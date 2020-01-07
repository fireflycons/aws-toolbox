function Get-StoredAwsCredentials
{
    # Check user authenticated
    if (-not (Test-Path variable:StoredAWSCredentials))
    {
        throw "Please authenticate with AWSPowerShell first (Set-AWSCredential)"
    }

    # Get the AWSCredential object from the shell stored credential
    $StoredAwsCredentials.GetType().
        GetProperty('Credentials', ([System.Reflection.BindingFlags]::NonPublic -bor [System.Reflection.BindingFlags]::Instance)).
        GetValue($StoredAwsCredentials).GetCredentials() | Select-Object *
}