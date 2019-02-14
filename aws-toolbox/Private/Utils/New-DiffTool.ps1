function New-DiffTool
{
    if ([System.Runtime.InteropServices.RuntimeInformation]::IsOSPlatform([System.Runtime.InteropServices.OSPlatform]::Windows))
    {
        # Look for winmerge
        $programFiles = Get-ChildItem -Path env: | Where-Object {
            $_.Name -ilike 'ProgramFiles*'
        }

        foreach ($dir in $programFiles.Value)
        {
            $winmerge = Join-Path $dir 'WinMerge\WinMergeU.exe'

            if (Test-Path -Path $winmerge)
            {
                return (
                    New-Object PSObject -Property @{
                        Command = Get-Command $winmerge
                    } |
                        Add-Member -PassThru -MemberType ScriptMethod -Name Invoke -Value {
                        param
                        (
                            [Parameter(Mandatory = $true)]
                            [string]$SourceFile,
                            [Parameter(Mandatory = $true)]
                            [string]$TargetFile,
                            [string]$SourceDisplayName,
                            [string]$TargetDisplayName
                        )

                        $arguments = @('/e', '/s', '/u', '/wr')

                        if (-not ([string]::IsNullOrEmpty($SourceDisplayName)))
                        {
                            $arguments += @('/dl', $SourceDisplayName)
                        }

                        if (-not ([string]::IsNullOrEmpty($TargetDisplayName)))
                        {
                            $arguments += @('/dr', $TargetDisplayName)
                        }

                        $arguments += ($SourceFile, $TargetFile)

                        Write-Host "Starting WinMerge..."
                        Start-Process -FilePath $this.Command.Path -ArgumentList $arguments -Wait
                    }
                )
            }
        }

        # Git is next
        $git = Get-Command git.exe -ErrorAction SilentlyContinue
    }
    else
    {
        # Unix/Linux/MacOS
        $git = Get-Command git -ErrorAction SilentlyContinue
    }

    # Common code for git diff
    if (-not $git)
    {
        return
    }

    New-Object PSObject -Property @{
        Command = $git
    } |
        Add-Member -PassThru -MemberType ScriptMethod -Name Invoke -Value {
        param
        (
            [Parameter(Mandatory = $true)]
            [string]$SourceFile,
            [Parameter(Mandatory = $true)]
            [string]$TargetFile,
            [string]$SourceDisplayName,
            [string]$TargetDisplayName
        )

        $arguments = @('diff', '--no-index', $SourceFile, $TargetFile)

        & $this.Command @arguments
    }
}