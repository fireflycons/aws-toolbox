function Get-ATEBInstanceLogs
{
    <#
    .SYNOPSIS
        Retrieve CloudFormation Init and Elastic Beanstalk instance logs from one or more instances.

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

                (Get-ATEBEnvironmentResourceList -EnvironmentId $EnvironmentId).Instances.InstanceId
            }

            'ByEnvName'
            {

                (Get-ATEBEnvironmentResourceList -EnvironmentName $EnvironmentName).Instances.InstanceId
            }
        }
    )

    # Filter down to running instances that have passed status checks
    $instances = Get-EC2InstanceStatus -InstanceId $instances |
        Where-Object {

        $passedStatusChecks = $_.Status.Status.Value -ieq 'ok' -and $_.SystemStatus.Status.Value -ieq 'ok'

        if ($_.InstanceState.Code -eq 16 -and $passedStatusChecks)
        {
            $true
        }
        else
        {
            Write-Warning "$($_.InstanceId): $($_.InstanceState.Name), Passed Status Checks: $($passedStatusChecks)"
            $false
        }
    } |
        Select-Object -ExpandProperty InstanceId

    if (($instances | Measure-Object).Count -eq 0)
    {
        Write-Warning "No instances are ready."
        return
    }

    # Now sort Windows from non-Windows
    $windowsInstances = Get-EC2Instance -InstanceId $instances |
        Select-Object -ExpandProperty Instances |
        Where-Object {
        $_.Platform -ieq 'Windows'
    } |
        Select-Object -ExpandProperty InstanceId

    $linuxInstances = Compare-Object -ReferenceObject $instances -DifferenceObject $windowsInstances -PassThru

    if (($linuxInstances | Measure-Object).Count -gt 0)
    {
        Write-Warning "Non-Windows instances not currently supported: $($linuxInstances -join ', ')."
    }

    if (($windowsInstances | Measure-Object).Count -eq 0)
    {
        Write-Warning "No Windows instances found."
        return
    }

    # Send SSM commands to get all the logs
    $results = Invoke-ATSSMPowerShellScript -InstanceId $windowsInstances -UseS3 -ScriptBlock {

        ("C:\Program Files\Amazon\ElasticBeanstalk\Logs", "C:\cfn\log") |
            ForEach-Object {
            Get-ChildItem $_ |
                Foreach-Object {
                Write-Host "---#LOG# $($_.Name)"
                Get-Content -Raw $_.FullName
            }
        }
    }

    if (-not $OutputFolder)
    {
        $OutputFolder = Join-Path (Get-Location).Path 'EB-Logs'
    }

    # Write out logs
    $results |
        Foreach-Object {

        $instanceFolder = Join-Path $OutputFolder $_.InstanceId

        if (-not (Test-Path -Path $instanceFolder -PathType Container))
        {
            New-Item -Path $instanceFolder -ItemType Directory -Force | Out-Null
        }

        $currentFile = $null
        $_.Stdout -split ([Environment]::NewLine) |
            ForEach-Object {

            if ($_ -match '^---#LOG#\s+(?<filename>\w+)')
            {
                $currentFile = Join-Path $instanceFolder $Matches.filename
            }
            elseif ($null -ne $currentFile)
            {
                $_ | Out-File -Append -FilePath $currentFile
            }
        }
    }
}