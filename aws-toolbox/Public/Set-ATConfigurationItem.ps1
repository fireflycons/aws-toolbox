function Set-ATConfigurationItem
{
<#
    .SYNOPSIS
        Set a module configuration item

    .DESCRIPTION
        Sets a user-configurable configuration item
        Currently you can only configure which application to use for file diffs.

        DYNAMIC PARAMETERS

        The cmdlet provides additional parameters in the context of the item being configured

    .PARAMETER ConfigurationItem
        The item to configure

        DYNAMIC PARAMETERS

        With -ConfigurationItem DiffTool, the following parameters becode active
        * -Git       Use git for diffs
        * -WinMerge  Use winmerge for diffs (Windows only)
        * -VSCode    Use Visual Studio Code for diffs
        * -Path      Available with the above 3 switches: Specify path to executable

    .EXAMPLE
        Set-ATConfigurationItem -ConfigurationItem DiffTool -Git

        Sets git diff as the file difference tool. Git executable is searched for in the system path

    .EXAMPLE
        Set-ATConfigurationItem -ConfigurationItem DiffTool -Git

        Sets git diff as the file difference tool. Git executable is searched for in the system path

    .EXAMPLE
        Set-ATConfigurationItem -ConfigurationItem DiffTool -Git -Path /opt/git/bin/git

        Sets git diff as the file difference tool, with executable located at specificed path.

    .EXAMPLE
        Set-ATConfigurationItem -ConfigurationItem DiffTool -WinMerge

        Sets winmerge as the file difference tool. Executable is searched for in known installation locations.
        This option is unavailable on non-windows operating systems

    .NOTES
        Supported diff tools are
        - git (all platforms) -Git
        - Winmerge (Windows only) -Winmerge
        - Visual Studio Code (all platforms) -VSCode

        Winmerge is generally preferable as it can set specific titles for the files being compared as opposed to just the file paths.
        This is especially useful when running Compare-ATDeployedStackWithSourceTemplate as the stack version is titled with the
        stack name rather than the temporary file path where the stack version has been downloaded to.

        If you have a diff tool you would like added, raise an issue in github.

#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateSet('DiffTool')]
        [string]$ConfigurationItem
    )

    DynamicParam
    {

        #Create the RuntimeDefinedParameterDictionary
        $dpDict = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary

        switch ($ConfigurationItem)
        {
            'DiffTool'
            {
                New-DynamicParam -Name 'Path' -Type String -HelpMessage "Path to diff tool" -DPDictionary $dpDict

                # Generate remaining parameters from diff-tools.json
                New-DiffToolDynamicParameters -DPDictionary $dpDict
            }
        }

        $dpDict
    }

    begin
    {
        # This standard block of code loops through bound parameters...
        # If no corresponding variable exists, one is created
        # Get common parameters, pick out bound parameters not in that set
        Function _temp { [cmdletbinding()] param() }
        $BoundKeys = $PSBoundParameters.keys | Where-Object { (get-command _temp | Select-Object -ExpandProperty parameters).Keys -notcontains $_ }
        foreach ($param in $BoundKeys)
        {
            if (-not ( Get-Variable -name $param -scope 0 -ErrorAction SilentlyContinue ) )
            {
                New-Variable -Name $Param -Value $PSBoundParameters.$param
            }
        }
    }

    end
    {
        switch ($ConfigurationItem)
        {
            'DiffTool'
            {
                if ($null -eq $script:PluginConfig)
                {
                    Write-Warning "Cannot configure diff tool. plugin-config.json missing or corrupt."
                    return
                }

                $diffConfig = $null

                $userPath = $(

                    if (Get-Variable -name 'Path' -scope 0 -ErrorAction SilentlyContinue)
                    {
                        $Path
                    }
                    else
                    {
                        $null
                    }
                )

                $diffToolPlugin = $script:PluginConfig.DiffTools |
                Where-Object {
                    $_.Name -ieq $PSCmdlet.ParameterSetName
                }

                if ($diffToolPlugin)
                {
                    $diffConfig = New-DiffTool -DiffToolConfig $diffToolPlugin -UserPath $userPath

                    if ($diffConfig)
                    {
                        if ($script:moduleConfig.HasItem('DiffTool'))
                        {
                            $script:moduleConfig.DiffTool = $diffConfig
                        }
                        else
                        {
                            Add-Member -InputObject $script:moduleConfig -MemberType NoteProperty -Name DiffTool -Value $diffConfig
                        }

                        Update-AwsToolboxConfiguration
                    }
                }
            }
        }
    }
}