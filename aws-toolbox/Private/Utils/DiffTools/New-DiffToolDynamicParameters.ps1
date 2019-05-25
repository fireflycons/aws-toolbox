function New-DiffToolDynamicParameters
{
    param
    (
        [System.Management.Automation.RuntimeDefinedParameterDictionary]$DPDictionary
    )

    if ($null -eq $script:PluginConfig)
    {
        Write-Warning "Cannot configure diff tool. plugin-config.json missing or corrupt."
        return
    }

    $os = Get-OperatingSystem

    $script:PluginConfig.DiffTools |
    Where-Object {

        $tool = $_
        switch ($os)
        {
            'Windows' { $tool.Windows }

            'Linux'   { $tool.Linux   }

            'MacOs'   { $tool.MacOS   }

            default   { $false }
        }
    } |
    Foreach-Object {

        New-DynamicParam -ParameterSetName $tool.Name -Name $tool.Name -Type Switch -Mandatory -DPDictionary $DPDictionary
    }
}