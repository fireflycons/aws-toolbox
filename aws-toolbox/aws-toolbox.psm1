$ErrorActionPreference = 'Stop'

# .NET compression libraries
'System.IO.Compression', 'System.IO.Compression.FileSystem' |
Foreach-Object {
    [System.Reflection.Assembly]::LoadWithPartialName($_) | Out-Null
}

# Get public and private function definition files.
$Public = @( Get-ChildItem -Path ([IO.Path]::Combine($PSScriptRoot, "Public", "*.ps1")) -Recurse -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path ([IO.Path]::Combine($PSScriptRoot, "Private", "*.ps1")) -Recurse -ErrorAction SilentlyContinue )

# Dot source the files
foreach ($import in @($Public + $Private))
{
    try
    {
        . $import.FullName
    }
    catch
    {
        Write-Error -Message "Failed to import function $($import.FullName): $_"
    }
}

# Check what authentication is available
if (-not ((Test-ATEC2IsRunningInEC2) -or $null -ne (Get-Item variable:StoredAWSCredentials -ErrorAction SilentlyContinue) -or $null -ne (Get-AWSCredential -ProfileName default)))
{
    Write-Warning "No credential found. Please use Set-AWSCredential or Initialize-AWSDefaultConfiguration to set a credential before using commands in this module"
}

$script:PluginConfig = Import-PluginConfiguration
$script:moduleConfig = Import-AwsToolboxConfiguration
$script:isPester = $null -ne (Get-PSCallStack | Where-Object Command -eq 'Invoke-Pester')

# Export public functions
Export-ModuleMember -Function $Public.Basename
