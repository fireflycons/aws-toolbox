function Invoke-SSMCommandScript
{
<#
    .SYNOPSIS
        Run sripts on hosts using SSM AWS-RunPowerShellScript or AWS-RunShellScript.

    .DESCRIPTION
        Run sripts on hosts using SSM AWS-RunPowerShellScript or AWS-RunShellScript.

    .PARAMETER ScriptType
        Type of script. Instances will be checked for correct platform prior to submission.

    .PARAMETER InstanceIds
        List of instance IDs identifying instances to run the script on.

    .PARAMETER AsJson
        If set, attempt to parse command output as a JSON string and convert to an object.

    .PARAMETER AsText
        Print command output from each instance to the console

    .PARAMETER UseS3
        SSM truncates results to 2000 characters. If you expect results to exceed this, then this switch
        instructs SSM to send the results to S3. The cmdlet will retrieve these results and return them.

    .PARAMETER ScriptBlock
        ScriptBlock containing the script to run.

    .PARAMETER CommandText
        String containing commands to run

    .PARAMETER ExecutionTimeout
         The time in seconds for a command to be completed before it is considered to have failed. Default is 3600 (1 hour). Maximum is 172800 (48 hours).

    .PARAMETER Deliverytimeout
        The time in seconds for a command to be delivered to a target instance. Default is 600 (10 minutes).

    .OUTPUTS
        [PSObject], none
        If -AsText specified, then none
        Else
        List of PSObject, one per instance containing the following fields
        - InstanceId   Instance for which this result pertains to
        - ResultObject If -AsJson and the result was successfully parsed, then an object else NULL
        - ResultText   Standard Output returned by the script (Write-Host etc.)

    .NOTES
        aws-toolbox uses a working bucket for passing results through S3 which will be created if not found.
        Format of bucket name is aws-toolbox-workspace-REGIONNAME-AWSACCOUNTID

    .EXAMPLE
        Invoke-ATSSMPowerShellScript -InstanceIds ('i-00000001', 'i-00000002') -ScriptBlock { net user me mypassword /add ; net localgroup Administrators me /add }
        Creates a windows user and adds to local administrators group on given instances

    .EXAMPLE
        Invoke-ATSSMPowerShellScript -InstanceIds ('i-00000001', 'i-00000002') -AsJson -ScriptBlock { Invoke-RestMethod http://localhost/status | ConvertTo-Json }
        Calls a local rest service, returning a JSON string and parse the result back into an object.

    .EXAMPLE
        Invoke-ATSSMPowerShellScript -InstanceIds i-00000000 -AsText { dir c:\ }
        Returns directory listing from remote instance to the console.
#>
    [CmdletBinding(DefaultParameterSetName = 'AsText')]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateSet('WindowsPowerShell', 'Shell')]
        [string[]]$ScriptType,

        [Parameter(Mandatory=$true)]
        [string[]]$InstanceIds,

        [Parameter(Mandatory=$true, Position = 0)]
        [object]$CommandText,

        [Parameter(ParameterSetName = 'AsJson')]
        [switch]$AsJson,

        [Parameter(ParameterSetName = 'AsText')]
        [switch]$AsText,

        [switch]$UseS3,

        [int]$ExecutionTimeout = 3600,

        [int]$DeliveryTimeout = 600
    )

    if ($UseS3)
    {
        $s3Bucket = Get-WorkspaceBucket
        $s3KeyPrefix = 'ssm-run-command/'
    }

    $ssmCommands = $(
        if ($CommandText -is [scriptblock])
        {
            $ScriptBlock.ToString() -split [Environment]::NewLine
        }
        elseif ($CommandText -is [string])
        {
            $CommandText -split [Environment]::NewLine
        }
        else
        {
            throw "SSM command must be string or scriptblock, not $($CommandText.GetType().Name)"
        }
    )

    $InstanceIds = $InstanceIds |
    Where-Object {
        $null -ne $_
    }

    if (($InstanceIds | Measure-Object).Count -eq 0)
    {
        Write-Warning "No instances specified!"
        return
    }

    $instanceTypes = $InstanceIds | Get-SSMEnabledInstances
    $documentName = $null

    switch ($ScriptType)
    {
        'WindowsPowerShell'
        {
            if (-not $instanceTypes.Windows)
            {
                Write-Warning "None of specified instances are Windows, ready and SSM enabled."
                return
            }

            $InstanceIds = $instanceTypes.Windows
            $documentName = 'AWS-RunPowerShellScript'
        }

        'Shell'
        {
            if (-not $instanceTypes.NonWindows)
            {
                Write-Warning "None of specified instances are Linux/Unix, ready and SSM enabled."
                return
            }

            $InstanceIds = $instanceTypes.NonWindows
            $documentName = 'AWS-RunShellScript'
        }
    }


    if (($InstanceIds | Measure-Object).Count -gt 50)
    {
        $instanceGroups = Split-Array -Array $InstanceIds -Size 50
    }
    else
    {
        $instanceGroups = @()
        $instanceGroups += ,@($InstanceIds)
    }

    $InstanceGroups |
        ForEach-Object {

        $instanceGroup = $_

        # Build SSM command structure
        $runCommandParams = @{

            DocumentName   = $documentName
            InstanceId     = $instanceGroup
            TimeoutSeconds = $DeliveryTimeout
            Parameter      = @{

                workingDirectory = [string]::Empty
                executionTimeout = $ExecutionTimeout.ToString()
                commands         = $ssmCommands
            }
        }

        if ($UseS3)
        {
            $runCommandParams.Add('OutputS3BucketName', $s3Bucket.BucketName)
            $runCommandParams.Add('OutputS3KeyPrefix', $s3KeyPrefix)
        }

        if ($instanceGroup.Length -gt 4)
        {
            $sb = New-Object System.Text.StringBuilder
            $sb.AppendLine('Sending SSM command to:') | Out-Null
            $s = Split-Array -Array $instanceGroup -Size 4
            $s |
            Foreach-Object {
                $sb.AppendLine("  $($_ -join ', ')") | Out-Null
            }

            Write-Host $sb.ToString()
        }
        else
        {
            Write-Host "Sending SSM command to $($instanceGroup -join ', ')"
        }

        $cmd = Send-SSMCommand @runCommandParams

        Write-Host "Submitted command with ID $($cmd.CommandId) and waiting for status..."

        while (('Pending', 'InProgress') -icontains $cmd.Status)
        {
            Start-Sleep -Seconds 5
            $cmd = Get-SSMCommand -CommandId $cmd.CommandId
        }

        if ($cmd.Status -ine 'Success')
        {
            if ($cmd.StatusDetails)
            {
                Write-Warning "The command did not complete successfully. Status is $($cmd.StatusDetails)."
            }
            else
            {
                Write-Warning  "The command did not complete successfully."
            }
        }

        if ($UseS3)
        {
            Write-Host "Collecting results from S3..."
        }

        # Collect results
        $instanceGroup |
        Foreach-Object {

            $instanceId = $_

            if ($UseS3)
            {
                $invocation = Get-SSMCommandInvocation -CommandId $cmd.CommandId -InstanceId $instanceId

                $detail = New-Object PSObject -Property @{
                    StandardOutputContent = Get-ContentFromS3 -S3Url $invocation.StandardOutputUrl
                    StandardErrorContent = Get-ContentFromS3 -S3Url $invocation.StandardErrorUrl -ExpectContent (-not ($invocation.Status -ieq 'Success'))
                }
            }
            else
            {
                $detail = Get-SSMCommandInvocationDetail -CommandId $cmd.CommandId -InstanceId $instanceId
            }

            $obj = $null

            if ($AsJson)
            {
                try
                {
                    $obj = $detail.StandardOutputContent | ConvertFrom-Json
                }
                catch
                {
                    $obj = $null
                }
            }

            if ($AsText)
            {
                Write-Host "----------- Instance $instanceId ----------- "

                if (-not ([string]::IsNullOrEmpty($detail.StandardOutputContent)))
                {
                    Write-Host
                    Write-Host $detail.StandardOutputContent
                    Write-Host
                }

                if (-not ([string]::IsNullOrEmpty($detail.StandardErrorContent)))
                {
                    Write-Host
                    Write-Host -ForegroundColor Red $detail.StandardErrorContent
                    Write-Host
                }
            }
            else
            {
                New-Object PSObject -Property @{
                    InstanceId = $instanceId
                    ResultObject = $obj
                    Stdout = $detail.StandardOutputContent
                    Stderr = $detail.StandardErrorContent
                }
            }
        }
    }
}