function Import-PluginConfiguration
{
    $pluginConfig = Join-Path $PSScriptRoot 'plugin-config.json'

    if (-not (Test-Path -Path $pluginConfig -PathType Leaf))
    {
        Write-Warning "Plugin config file '$pluginConfig' not found"
        return
    }

    try
    {
        Get-Content -Path $pluginConfig -Raw | ConvertFrom-Json
    }
    catch
    {
        Write-Warning "$($pluginConfig): File is corrupt. Not importing"
        $null
    }
}