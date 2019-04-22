function Get-ATIAMSessionCredentials
{
<#
    .SYNOPSIS
        Gets keys from a federated AWS login

    .DESCRIPTION
        If your organisation uses federated authentication (SAML etc) for API authentication with AWS,
        this cmdlet enables you to get a set of temporary keys for use with applications that do not
        understand/support this authentication method.

        Various means of acquiring/storing the credentials are provided by this cmdlet.

        You must first authenticate with AWS using the account you need keys for via Set-AWSCredential.

    .PARAMETER SetLocal
        The credentials are set as environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN in the current shell.
        Proceed to run your application that supports environment-based credentails in this shell.

    .PARAMETER Ruby
        The credentials are formatted as ENV[] = staements and output to the console

    .PARAMETER Bash
        The credentials are formatted as EXPORT staements and output to the console

    .PARAMETER Clipboard
        If set, output of -Ruby or -Bash is copied directly to clipboard, so you can paste them into code or your active Ruby or Shell prompt

    .EXAMPLE
        Get-ATIAMSessionCredentials
        With no parameters (or with -SetLocal), sets up the AWS environment variables in the current shell

    .EXAMPLE
        Get-ATIAMSessionCredentials -Bash -ClipBoard
        Copies shell EXPORT statements to create the AWS environment variables for sh/bash direct to clipboard. Paste into your shell environment.

    .EXAMPLE
        Get-ATIAMSessionCredentials -Ruby -ClipBoard
        Copies ruby ENV statements to create the AWS environment variables for ruby direct to clipboard. Paste into your irb shell environment.

#>
    [CmdletBinding(DefaultParameterSetName = 'SetLocal')]
    param
    (
        [Parameter(ParameterSetName = "Ruby")]
        [switch]$Ruby,

        [Parameter(ParameterSetName = "Shell")]
        [switch]$Bash,

        [Parameter(ParameterSetName = "Ruby")]
        [Parameter(ParameterSetName = "Shell")]
        [switch]$ClipBoard,

        [Parameter(ParameterSetName = "SetLocal")]
        [switch]$SetLocal
    )

    # Check user authenticated
    if (-not (Test-Path variable:StoredAWSCredentials))
    {
        throw "Please authenticate with AWSPowerShell first (Set-AWSCredential)"
    }

    # Get the AWSCredential object from the shell stored credential
    $cred = $StoredAwsCredentials.GetType().
        GetProperty('Credentials', ([System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)).
        GetValue($StoredAwsCredentials).GetCredentials() | Select-Object *

    Write-Warning "Expiry time for these keys: $($cred.Expires.ToLocalTime().ToString("HH:mm:ss")). You will need to re-run this script after then to regenerate keys."

    if ($Ruby)
    {
        # Build Ruby environment variables and output
        $sb = New-Object System.Text.StringBuilder

        $sb.AppendLine("ENV[`"AWS_ACCESS_KEY_ID`"] = `"$($cred.AccessKey)`"").
        AppendLine("ENV[`"AWS_SECRET_ACCESS_KEY`"] = `"$($cred.SecretKey)`"") | Out-Null

        if ($cred.UseToken)
        {
            $sb.AppendLine("ENV[`"AWS_SESSION_TOKEN`"] = `"$($cred.Token)`"") | Out-Null
        }

        if ($ClipBoard)
        {
            $sb.ToString() | clip.exe
            Write-Host "Ruby env vars copied to clipboard"
        }
        else
        {
            $sb.ToString()
        }
    }
    elseif ($Bash)
    {
        # Build shell environment variables and output
        $sb = New-Object System.Text.StringBuilder
        $sb.AppendLine("export AWS_ACCESS_KEY_ID=`"$($cred.AccessKey)`"").
        AppendLine("export AWS_SECRET_ACCESS_KEY=`"$($cred.SecretKey)`"") | Out-Null

        if ($cred.UseToken)
        {
            $sb.AppendLine("export AWS_SESSION_TOKEN=`"$($cred.Token)`"") | Out-Null
        }

        if ($ClipBoard)
        {
            $sb.ToString() | clip.exe
            Write-Host "BASH shell env vars copied to clipboard"
        }
        else
        {
            $sb.ToString()
        }
    }
    elseif ($PSCmdlet.ParameterSetName -ieq 'SetLocal')
    {
        # Set local enviroment with credential material.
        Set-Item -Path env:AWS_ACCESS_KEY_ID -Value $cred.AccessKey -Force
        Set-Item -Path env:AWS_SECRET_ACCESS_KEY -Value $cred.SecretKey -Force

        if ($cred.UseToken)
        {
            Set-Item -Path env:AWS_SESSION_TOKEN -Value $cred.Token -Force
        }
        else
        {
            if (Test-Path -Path env:AWS_SESSION_TOKEN)
            {
                Remove-Item env:AWS_SESSION_TOKEN
            }
        }

        Write-Host "Keys set in your environment. Run commands that need them (e.g. node) in this shell"
    }
}