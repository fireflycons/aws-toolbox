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
        [scriptblock]$cacheScriptBlock = {
            #!/usr/bin/env pwsh

            # Silence warnings, or aws will consume them and fail
            $warnPef = $WarningPreference

            try
            {
                $WarningPreference = 'SilentlyContinue'
                $credentialCache = '{0}'
                $profileName = '{1}'

                if (Test-Path -Path $credentialCache)
                {
                    $profiles = Get-Content -Raw -Path $credentialCache | ConvertFrom-Json
                }
                else
                {
                    $profiles = @()
                }

                $profile = $profiles | Where-Object {
                    $_.Name -eq $profileName
                }

                $cred = @{
                    Expiration = [DateTime]'1900-01-01'
                }

                if ($profile)
                {
                    # Decode secure string back to JSON
                    $ss = ConvertTo-SecureString $pofile.Credential
                    $json = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR(([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($ss)))))

                    # Check credential time
                    $cred = $json | ConvertFrom-Json
                }

                if ($cred.Expiration -le [datetime]::UtcNow.AddMinutes(-5))
                {
                    # Regenerate
                    if ($PSVersionTable.PSVersion.Major -lt 6)
                    {
                        Import-Module aws-toolbox
                    }
                    else
                    {
                        Import-Module aws-toolbox.netcore
                    }
                }

                Set-AwsCredential -ProfileName $profileName
                $json = Get-ATIAMSessionCredentials -AwsCli

                $encryptedCredential = $json | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString

                if ($profile)
                {
                    $profile.Credential = $encryptedCredential
                }
                else {
                    $profiles += New-Object PSObject -Property @{
                        Name = $profileName
                        Credential = $encryptedCredential
                    }
                }

                # Write out credential cache
                $profiles | Set-Content -Path $credentialCache -Force
            }
            finally
            {
                $WarningPreference = $warnPef
            }

            # Emit credential
            $json
        }

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
        $windows = $PSVersionTable.PSVersion.Major -lt 6 -or $IsWindows
        $credentialStore = Get-CliConfiguration -ConfigurationFileName credentials

        if ([string]::IsNullOrEmpty($CliProfileName))
        {
            $CliProfileName = $ProfileName
        }

        $creds = Read-CliConfigurationFile -Credentials

        if ($creds.ContainsKey($CliProfileName))
        {
            $creds.Remove($CliProfileName)
        }

        # Write cache script for this profile
        $cacheScriptDir = Join-Path $credentialStore.Directory 'aws-toolbox-cache'
        if (-not (Test-Path -Path $cacheScriptDir -PathType Container))
        {
            New-Item -Path $cacheScriptDir -ItemType Directory | Out-Null
        }

        $cacheScriptPath = Join-Path $cacheScriptDir "$($ProfileName).ps1"
        $credentialCachePath = Join-Path $cacheScriptDir "credential-cache"

        $cacheScript = ($cacheScriptBlock.ToString().Replace('{0}', $credentialCachePath).Replace('{1}', $ProfileName)) -split ([System.Environment]::NewLine)

        $line = 0

        # Remove leading blank lines
        while([string]::IsNullOrEmpty($cacheScript[$line]))
        {
            $line++
        }

        $cacheScript[$line] -match '^(\s*)' | Out-Null
        $totalLines = $cacheScript.Length
        $blanks = ($Matches.1).Length

        # Remove leading space
        $cacheScript = $(
            for($i = $line; $i -lt $totalLines; ++$i)
            {
                if ($cacheScript[$i].Length -ge $blanks)
                {
                    $cacheScript[$i].Substring($blanks)
                }
                else
                {
                    $cacheScript[$i]
                }
            }
        ) -join ([System.Environment]::NewLine)

        # Write Cache script
        $cacheScript | Set-Content -Path $cacheScriptPath -Force -Encoding ascii

        if (-not $windows)
        {
            # Make cache script executable
            & chmod +x $cacheScript
        }

        $creds[$CliProfileName] = @{
            credential_process = (Get-CredentialProcess -CacheScriptPath $cacheScriptPath).CredentialProcess -f $ProfileName
        }

        $creds | Write-CliConfigurationFile -Credentials
    }
}
