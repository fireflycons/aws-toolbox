function New-DiffTool
{
    param
    (
        [PSObject]$DiffToolConfig,
        [string]$UserPath
    )

    $tool = $null

    # If user has supplied a path
    if ($UserPath)
    {
        $tool = Get-Command $UserPath -ErrorAction SilentlyContinue
    }
    else
    {
        if ((Get-OperatingSystem) -ieq 'Windows')
        {
            $executable = $DiffToolConfig.ExecutableName + ".exe"
            $searchPaths = $DiffToolConfig.WindowsPaths
        }
        else
        {
            $executable = $DiffToolConfig.ExecutableName
            $searchPaths = $DiffToolConfig.NonWindowsPaths
        }

        if ($DiffToolConfig.SearchInPath)
        {
            $tool = Get-Command $executable -ErrorAction SilentlyContinue
        }

        if (-not $tool)
        {
            foreach ($path in $searchPaths)
            {
                $tool = Get-Command (Join-Path $ExecutionContext.InvokeCommand.ExpandString($path) $executable) -ErrorAction SilentlyContinue

                if ($tool)
                {
                    break
                }
            }

            if (-not $tool)
            {
                Write-Warning "Cannot locate $($DiffToolConfig.DisplayName). Try specifying a path to the executable with -Path"
                return $null
            }
        }

        New-Object PSObject -Property @{
            Name = $DiffToolConfig.DisplayName
            Path = $tool.Path
            Arguments = $DiffToolConfig.Arguments
            IsGUI = $DiffToolConfig.IsGUI
        }
    }
}