function Get-CredentialProcess
{
    param
    (
        [string]$CacheScriptPath
    )

    $edition = 'Desktop'
    $windows = $PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows

    if (Get-Variable -Name PSEdition)
    {
        $edition = $PSEdition
    }

    $process = @{
        PowerShell = $(
            if ($edition -eq 'Desktop')
            {
                (Get-Command 'PowerShell.exe').Source
            }
            else
            {
                (Get-Command 'pwsh').Source
            }
        )
        Module = (Get-PSCallStack)[0].InvocationInfo.MyCommand.Module.Name
    }

    if ($CacheScriptPath -match '\s')
    {
        $CacheScriptPath = "`"$CacheScripPath`""
    }

    $process['CredentialProcess'] = $(

        if ($windows)
        {
            if ($process.PowerShell -match '\s')
            {
                "`"$($process.PowerShell)`" -File $CacheScriptPath"
            }
            else
            {
                "$($process.PowerShell) -File $CacheScriptPath"
            }
        }
        else
        {
            # shebang executable script
            $CacheScriptPath
        }
    )

    $process
}