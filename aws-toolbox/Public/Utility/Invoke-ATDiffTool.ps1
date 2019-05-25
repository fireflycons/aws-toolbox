function Invoke-ATDiffTool
{
<#
    .SYNOPSIS
        Invoke the module's configured diff tool

    .DESCRIPTION
        Invoke the module's configured diff tool.
        Provides a consistent interface to compare two files irrespective of the diff tool in use.

    .PARAMETER LeftPath
        Path to 'left' file to compare

    .PARAMETER RightPath
        Path to 'right' file to compare

    .PARAMETER LeftTitle
        Title to show for left file on tools that support this.
        Defaults to the value of LeftPath

    .PARAMETER RightTitle
        Title to show for right file on tools that support this.
        Defaults to the value of RightPath

    .PARAMETER Wait
        For tools that run as a GUI, wait for the process to exit before continuing.

    .EXAMPLE
        Invoke-ATDiffTool -LeftPath .\thisfile.txt -RightPath .\thatfile.txt -LeftTitle This -RightTitle That -Wait

        Compare files displaying custom titles and wait for GUI process to exit.

    .NOTES
        -Wait parameter currently does not work when configured diff tool is VSCode,
        as code starts a sub-process for the diff and the main process exits immediately.

    .LINK
        Set-ATConfiguratonItem
#>
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$LeftPath,

        [Parameter(Mandatory = $true, Position = 1)]
        [string]$RightPath,

        [Parameter(Position = 2)]
        [string]$LeftTitle,

        [Parameter(Position = 3)]
        [string]$RightTitle,

        [switch]$Wait
    )

    if (-not $script:moduleConfig.HasItem('DiffTool'))
    {
        Write-Warning "Diff tool not configured."
        Write-Warning "Run Set-ATConfigurationItem -ConfigurationItem DiffTool to configure one."
        return
    }

    $toolDefinition = $script:moduleConfig.DiffTool

    $cmd = Get-Command $toolDefinition.Path

    # Can only wait on GUI tools, i.e. not git diff
    $Wait = $Wait -and $toolDefinition.IsGUI

    if ([string]::IsNullOrEmpty($LeftTitle))
    {
        $LeftTitle = $LeftPath
    }

    if ([string]::IsNullOrEmpty($RightTitle))
    {
        $RightTitle = $RightPath
    }

    $argumentArray = $toolDefinition.Arguments -split '\s'

    for ($i = 0; $i -lt $argumentArray.Length; ++$i)
    {
        switch ($argumentArray[$i])
        {
            '{LeftTitle}'  { $argumentArray[$i] = $LeftTitle }
            '{RightTitle}'  { $argumentArray[$i] = $RightTitle }
            '{LeftPath}'  { $argumentArray[$i] = $LeftPath }
            '{RightPath}'  { $argumentArray[$i] = $RightPath }
        }
    }

    if (-not $toolDefinition.IsGUI)
    {
        # Run in current console
        & $cmd $argumentArray
    }
    else
    {
        if ($Wait)
        {
            Write-Host "Waiting for $($toolDefinition.Name)..."
        }
        else
        {
            Write-Host "Starting $($toolDefinition.Name)..."
        }

        # Start GUI process
        $proc = Start-Process -FilePath $cmd.Path -ArgumentList $argumentArray -PassThru

        if ($Wait)
        {
            $proc.WaitForExit()
        }
    }
}