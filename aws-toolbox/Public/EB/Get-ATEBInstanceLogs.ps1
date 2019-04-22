function Get-ATEBInstanceLogs
{
    <#
    .SYNOPSIS
        Retrieve CloudFormation Init and Elastic Beanstalk instance logs from one or more instances.

    .DESCRIPTION
        Retrieve CloudFormation Init and Elastic Beanstalk instance logs from one or more instances,
        and place them into a directory structure containing the logs for each selected instance.

    .PARAMETER InstanceId
        One or more instance Ids.

    .PARAMETER EnvironmentId
        ID of an Elastic Beanstalk environment. All running instances will be queried.

    .PARAMETER EnvironmentName
        Name of an Elastic Beanstalk environment. All running instances will be queried.

    .PARAMETER OutputFolder
        Name of folder to write logs to. If omitted a folder EB-Logs will be created in the current folder.

    .NOTES
        For this to succeed, your instances must have the SSM agent installed (generally the default with recent AMIs),
        and they must have a profile which includes AmazonEC2RoleforSSM managed policy, or sufficient individual rights
        to run the SSM command and write to S3.

    .EXAMPLE
        Get-ATEBInstanceLogs -InstanceId i-00000000,i-00000001
        Get Elastic Beanstalk logs from given instances and write to EB-Logs folder in current location

    .EXAMPLE
        Get-ATEBInstanceLogs -EnvironmentId e-a4d34fd -OutputFolder C:\Temp\EB-Logs
        Get Elastic Beanstalk logs from instances in given EB environment by enviromnent ID and write to specified folder.

    .EXAMPLE
        Get-ATEBInstanceLogs -EnvironmentName my-enviromn -OutputFolder C:\Temp\EB-Logs
        Get Elastic Beanstalk logs from instances in given EB environment by name and write to specified folder.
#>
    [CmdletBinding(DefaultParameterSetName = 'ByEnvName')]
    param
    (
        [Parameter(ParameterSetName = 'ByInstance')]
        [string[]]$InstanceId,

        [Parameter(ParameterSetName = 'ByEnvId')]
        [string]$EnvironmentId,

        [Parameter(ParameterSetName = 'ByEnvName', Position = 0)]
        [string]$EnvironmentName,

        [string]$OutputFolder
    )

    # Get the instances we will query
    $instances = $(

        switch ($PSCmdlet.ParameterSetName)
        {
            'ByInstance'
            {
                $InstanceId
            }

            'ByEnvId'
            {
                Write-Host "Getting EB environment details..."
                (Get-ATEBEnvironmentResourceList -EnvironmentId $EnvironmentId).Instances.InstanceId
            }

            'ByEnvName'
            {
                Write-Host "Getting EB environment details..."
                (Get-ATEBEnvironmentResourceList -EnvironmentName $EnvironmentName).Instances.InstanceId
            }
        }
    )

    Write-Host "Checking instances for SSM..."
    $instanceTypes = Get-SSMEnabledInstances -InstanceId $instances

    if ($instanceTypes.NotReady)
    {
        Write-Warning "Instances not running/not passed status checks`n:   $($instanceTypes.NotReady -join ', ')"
    }

    if ($instanceTypes.NonSSM)
    {
        Write-Warning "Instance is not SSM capable or SSM is not ready`n:   $($instanceTypes.NonSSM -join ', ')"
    }

    # Send SSM commands to get all the logs
    $results = $(

        if ($instanceTypes.Windows)
        {
            Invoke-ATSSMPowerShellScript -InstanceId $instanceTypes.Windows -UseS3 -ScriptBlock {

                # EB and CFN logs
                ("C:\Program Files\Amazon\ElasticBeanstalk\Logs", "C:\cfn\log") |
                Where-Object {
                    Test-Path -Path $_ -PathType Container
                } |
                ForEach-Object {
                    Get-ChildItem $_ |
                    Foreach-Object {
                        Write-Host "---#LOG# $($_.Name)"
                        Get-Content -Raw $_.FullName
                    }
                }

                # IIS Logs
                try
                {
                    Import-Module WebAdministration

                    (Get-ChildItem IIS:\Sites) |
                    Foreach-Object {
                        $site = Get-Item $_.FullName
                        Get-ChildItem (Join-Path ([Environment]::ExpandEnvironmentVariables($site.logfile.directory), "W3SVC$($site.id)")) |
                        Foreach-Object {
                            Write-Host "---#LOG# IIS_$($site.Name.Replace(' ', '_'))_$($_.Name)"
                            Get-Content -Raw $_.FullName
                        }
                    }
                }
                catch
                {
                    Write-Host "---#LOG# IISLogRetrievalFailed.log"
                    Write-Host $_.Exception.Message
                }

                # Event logs
                ('Application', 'System') |
                Foreach-Object {
                    Write-Host = "---#LOG# EventLog.$($_).csv"
                    Get-EventLog -LogName $_ -After ( [DateTime]::Now - [timespan]::FromMinutes(60) ) |
                    Select-Object Index, TimeGenerated, EntryType, Source, InstanceId, Message |
                    ConvertTo-Csv -NoTypeInformation
                }
            }
        }


        if ($instanceTypes.NonWindows)
        {
            $shellScript = @"
for f in `$(ls /var/log/eb*.log)
do
    echo "---#LOG# `$(basename `$f)"
    cat `$f
done

for f in `$(ls /var/log/cfn-*.log)
do
    echo "---#LOG# `$(basename `$f)"
    cat `$f
done

for f in `$(ls /var/log/cloud-*.log)
do
    echo "---#LOG# `$(basename `$f)"
    cat `$f
done

if [ -d /var/log/nginx ]
then
    for f in /var/log/nginx/access.log /var/log/nginx/error.log
    do
        echo "---#LOG# `$(basename `$f)"
        cat `$f
    done
fi
"@
            Invoke-ATSSMShellScript -InstanceId $instanceTypes.NonWindows -UseS3 -CommandText $shellScript
        }

    )

    if (-not $OutputFolder)
    {
        $OutputFolder = Join-Path (Get-Location).Path 'EB-Logs'
    }

    # SSM writes outout to S3 in Unix text
    $lf = [string]([char]10)

    # Write out logs
    $results |
    Foreach-Object {

        $thisInstance = $_.InstanceId
        $instanceFolder = Join-Path $OutputFolder $thisInstance
        Write-Host "Downloading logs for $thisInstance"

        if (Test-Path -Path $instanceFolder -PathType Container)
        {
            # Clean out any previous results
            Remove-Item $instanceFolder -Recurse -Force
        }

        New-Item -Path $instanceFolder -ItemType Directory -Force | Out-Null

        $currentFile = $null

        $_.Stdout -split $lf |
        ForEach-Object {

            if ($_ -match '^---\#LOG\#\s+(?<filename>.*)')
            {
                Write-Host "  -" $Matches.filename
                $currentFile = Join-Path $instanceFolder $Matches.filename
            }
            elseif ($null -ne $currentFile)
            {
                $_ | Out-File -Append -FilePath $currentFile
            }
        }

        if (-not ([string]::IsNullOrEmpty($_.Stderr)))
        {
            # Write SSM STDERR output to it's own file
            Write-Warning "Instance $($thisInstance): Errors were output by the commands run in SSM"
            $_.Stderr -split $lf | Out-File (Join-Path $instanceFolder "ssm-errors.log")
        }
    }
}