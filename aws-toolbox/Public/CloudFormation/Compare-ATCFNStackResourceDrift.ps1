function Compare-ATCFNStackResourceDrift
{
    <#
    .SYNOPSIS
        Get resource drift for given stack

    .DESCRIPTION
        Optionally run a drift check on the stack and, depending on whether -PassThru was given
        either bring up the drift differences in the configured diff viewer, or output the
        drifted resource information to the pipeline.

    .PARAMETER StackName
        Name of stack to check.

    .PARAMETER PassThru
        If set, then emit the drift information to the pipeline

    .PARAMETER NoReCheck
        If set, use the current drift information unless the stack has never been checked in which case a check will be run.
        If not set, a check is always run.

    .EXAMPLE
        Compare-ATCFNStackResourceDrift -StackName my-stack

        Run a drift check, and display any drift in the configured diff tool.

    .EXAMPLE
        $drifts = Compare-ATCFNStackResourceDrift -StackName my-stack -PassThru

        Run a drift check and return any drifts in the pipeline.

    .EXAMPLE
        Compare-ATCFNStackResourceDrift -StackName my-stack -NoReCheck

        Use results from last run drift check, and display any drift in the configured diff tool.

    .EXAMPLE
        Get-CFNStack | Compare-ATCFNStackResourceDrift -PassThru

        Get a check on all stacks in the account for current region.
        Advisable to use -PassThru or you may have a lot of diff windows opened!

    .OUTPUTS
        List of modified resources if -PassThru switch was present.

    .LINK
        Set-ATConfigurationItem
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'ByName', ValueFromPipelineByPropertyName )]
        [string]$StackName,
        [switch]$PassThru,
        [switch]$NoReCheck
    )

    begin
    {
        if ($null -eq (Get-Command -Name Start-CFNStackDriftDetection -ErrorAction SilentlyContinue))
        {
            Write-Warning 'Upgrade your version of AWSPowerShell to see drift information'
            return $null
        }
    }

    process
    {
        try
        {
            $stack = Get-CFNStack -StackName $StackName
        }
        catch
        {
            Write-Warning "Stack not found: $StackName"
            return
        }

        $driftStatus = $stack.DriftInformation.StackDriftStatus

        # Detect last CF update
        $event = Get-CFNStackEvent -StackName $stack.StackId | Select-Object -First 1

        Write-Host "$($StackName): Last CloudFormation Update: $($event.Timestamp.ToString('dd MMM yyyy, HH:mm:ss'))"

        if (-not $NoReCheck -or @('UNKNOWN', 'NOT_CHECKED') -contains $driftStatus)
        {
            # Initiate drift detection
            $driftStatus = Get-StackDrift -Stack $stack

            if ($null -eq $driftStatus)
            {
                return
            }
        }
        else
        {
            Write-Host "Last drift check: $($stack.DriftInformation.LastCheckTimestamp.ToString('dd MMM yyyy, HH:mm:ss'))"
        }

        if ($driftStatus -eq 'IN_SYNC')
        {
            Write-Host "IN_SYNC"
            return
        }

        Write-Warning "Stack has drifted..."

        $newLine = [Environment]::NewLine

        # Get drifts and format into two files that can be compared in a diff tool
        $allExpected = New-Object System.Text.StringBuilder
        $allActual = New-Object System.Text.StringBuilder

        $drifts = Get-CFNDetectedStackResourceDrift -StackName $stack.StackId -StackResourceDriftStatusFilter @('DELETED', 'MODIFIED')

        if ($PassThru)
        {
            return [PSCustomObject][ordered] @{
                StackName        = $stack.StackName
                DriftInformation = $drifts
            }
        }

        $drifts |
        ForEach-Object {

            $drift = $_
            $expected = ($drift.ExpectedProperties | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Format-Json) -split $newLine

            switch ($_.StackResourceDriftStatus)
            {
                'MODIFIED'
                {
                    $actual = ($drift.ActualProperties | ConvertFrom-Json | ConvertTo-Json -Depth 10 | Format-Json) -split $newLine

                    # Whichever is longer, bulk the other up with newlines to align output
                    if ($actual.Length -ne $expected.Length)
                    {
                        $blankLines = [Environment]::NewLine * [Math]::Abs($actual.Length - $expected.Length)

                        if ($actual.Length -gt $expected.Length)
                        {
                            $expected += $blankLines
                        }
                        else
                        {
                            $actual += $blankLines
                        }
                    }
                }

                'DELETED'
                {
                    $actual = $newLine * $expected.Length
                }
            }

            # Write headings
            $allExpected.AppendLine("$($drift.LogicalResourceId) ($($drift.ResourceType))").AppendLine() | Out-Null
            $allActual.AppendLine("$($drift.LogicalResourceId) ($($drift.ResourceType)): $($drift.StackResourceDriftStatus)").AppendLine() | Out-Null

            # Make expected and actual the same number of lines so everything lines up in diff viewer
            $allExpected.AppendLine(($expected -join $newLine)).AppendLine() | Out-Null
            $allActual.AppendLine(($actual -join $newLine)).AppendLine() | Out-Null
        }

        # Write out and invoke diff tool
        $expectedOutFile = Join-Path ([IO.Path]::GetTempPath()) "DriftResults-$($StackName)-expected.json"
        $actualOutFile = Join-Path ([IO.Path]::GetTempPath()) "DriftResults-$($StackName)-actual.json"

        $encoding = New-Object System.Text.UTF8Encoding($false, $false)
        [IO.File]::WriteAllText($expectedOutFile, $allExpected.ToString(), $encoding)
        [IO.File]::WriteAllText($actualOutFile, $allActual.ToString(), $encoding)

        Invoke-ATDiffTool -LeftPath $expectedOutFile -RightPath $actualOutFile -LeftTitle ($StackName + " - Expected") -RightTitle ($StackName + " - Actual") -Wait
    }
}