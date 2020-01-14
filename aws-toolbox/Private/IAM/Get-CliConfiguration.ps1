function Get-CliConfiguration
{
    param
    (
        [ValidateSet('config', 'credentials')]
        [string]$ConfigurationFileName
    )

    $environmentPath = $(

        switch ($ConfigurationFileName)
        {
            'config'
            {
                $env:AWS_CONFIG_FILE
            }

            'credentials'
            {
                $env:AWS_SHARED_CREDENTIALS_FILE
            }
        }
    )

    $filePath = $(

        if ($null -ne $environmentPath)
        {
            $environmentPath
        }
        else
        {
            if ((Get-OperatingSystem) -eq 'Windows')
            {
                Join-Path $env:USERPROFILE ".aws\$($ConfigurationFileName)"
            }
            else
            {
                "~/.aws/$($ConfigurationFileName)"
            }
        }
    )

    New-Object PSObject -Property @{
        FilePath = $filePath
        Directory = Split-Path -Parent $filePath
    }
}