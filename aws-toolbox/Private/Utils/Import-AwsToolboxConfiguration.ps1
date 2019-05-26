function Import-AwsToolboxConfiguration
{
    $configPath = [IO.Path]::Combine([Environment]::GetFolderPath('ApplicationData'), 'aws-toolbox', 'aws-toolbox.config.json')

    $config = New-Object PSObject -Property @{ }

    if (Test-Path -Path $configPath -PathType Leaf)
    {
        try
        {
            $config = Get-Content -Raw -Path $configPath | ConvertFrom-Json
        }
        catch
        {
            Write-Warning "Config at '$configPath' is corrupt. Please recreate with Set-ATConfigurationItem"
        }
    }

    $config |
    Add-Member -PassThru -MemberType ScriptMethod -Name HasItem -Value {
        param
        (
            [string]$ItemName
        )

        $null -ne (
            $this.PSObject.Properties |
            Where-Object {
                $_.MemberType -ne 'ScriptMethod' -and $_.Name -ieq $ItemName
            }
        )
    }
}