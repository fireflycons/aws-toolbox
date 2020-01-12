function Set-ATIAMCliExternalCredentials
{
<#
    .SYNOPSIS
        Configue aws-toolbox as an AWS CLI Credential Process

    .DESCRIPTION
        This cmdlet maps a PowerShell stored profile into the AWS CLI credential file
        as a provider of external credentials. This is useful to get AWS CLI to use a
        saved SAML profile when e.g. you use Active Directory integration to authenticate
        with AWS

    .PARAMETER ProfileName
        Name of PowerShell stored profile to use.

    .PARAMETER CliProfileName
        Name of profile to create in CLI credentials file. If omitted, then the name
        passed to ProfileName will be used.

    .EXAMPLE
        Set-ATIAMCliExternalCredentials -ProfileName MySamlProfile
        Creates an AWS CLI external credential profile named 'MySamlProfile' that maps onto the PowerShell profile named 'MySamlProfile'

    .EXAMPLE
        Set-ATIAMCliExternalCredentials -ProfileName MySamlProfile -CliProfileName MyCliSamlProfile
        Creates an AWS CLI external credential profile named 'MyCliSamlProfile' that maps onto the PowerShell profile named 'MySamlProfile'
#>
    [CmdletBinding()]
    param
    (
        [string]$CliProfileName
    )

    DynamicParam
    {
        $validateSet = Get-AWSCredential -ListProfileDetail | Select-Object -ExpandProperty ProfileName | Sort-Object -Unique
        New-DynamicParam -Name ProfileName -Mandatory -ValidateSet $validateSet -HelpMessage 'Name of PowerShell stored profile to use'
    }

    begin
    {
        foreach ($p in $PSBoundParameters.Keys)
        {
            if (-not (Get-Variable -Name $p -Scope Local -ErrorAction SilentlyContinue))
            {
                Set-Variable -Name $p -Value $PSBoundParameters[$p] -Scope Local
            }
        }
        if ($null -eq $ProfileName)
        {
            throw "Profile Name not set"
        }
    }

    process
    {}

    end
    {
        if ([string]::IsNullOrEmpty($CliProfileName))
        {
            $CliProfileName = $ProfileName
        }

        $creds = Read-CliConfigurationFile -Credentials

        if ($creds.ContainsKey($CliProfileName))
        {
            $creds.Remove($CliProfileName)
        }

        $creds[$CliProfileName] = @{
            credential_process = (Get-CredentialProcess).CredentialProcess -f $ProfileName
        }

        $creds | Write-CliConfigurationFile -Credentials
    }
}
