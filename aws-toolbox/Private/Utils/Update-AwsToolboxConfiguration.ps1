function Update-AwsToolboxConfiguration
{
    $configDir = [IO.Path]::Combine([Environment]::GetFolderPath('ApplicationData'), 'aws-toolbox')
    $configPath = [IO.Path]::Combine($configDir, 'aws-toolbox.config.json')

    if (-not (Test-Path -Path $configDir -PathType Container))
    {
        New-Item -Path $configDir -ItemType Directory -Force | Out-Null
    }

    [IO.File]::WriteAllText($configPath, ($Script:moduleConfig | ConvertTo-Json), (New-Object System.Text.UTF8Encoding ($false)))
}