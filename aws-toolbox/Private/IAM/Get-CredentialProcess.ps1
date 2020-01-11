function Get-CredentialProcess
{
    $edition = 'Desktop'

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

    $sb = New-Object System.Text.StringBuilder

    if ($process.PowerShell -match '\s')
    {
        $sb.Append("`"$($process.PowerShell)`"") | Out-Null
    }
    else
    {
        $sb.Append($process.PowerShell) | Out-Null
    }

    $sb.Append(" -Command `"Import-Module $($process.Module); Set-AwsCredential {0}; Get-ATIAMSessionCredentials -AwsCli`"") | Out-Null

    $process['CredentialProcess'] = $sb.ToString()

    $process
}