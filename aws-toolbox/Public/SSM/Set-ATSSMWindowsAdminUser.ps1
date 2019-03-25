function Set-ATSSMWindowsAdminUser
{
<#
    .SYNOPSIS
        Use SSM to set up an admin user on one or more Windows instances

    .DESCRIPTION
        Uses SSM to set up a user from the given credentials as a local administrator on the target instances.
        Instances are checked for being Windows, running, passed status checks and SSM enabled.
        This is good for instances created without a key pair, or just to create a user that isn't Administrator.

    .PARAMETER InstanceId
        List of instance IDs on which to set credential

    .PARAMETER Username
        Username to set

    .PARAMETER Password
        Password to set

    .PARAMETER Credential
        PSCredential containing credentials to set.

    .EXAMPLE
        Get-Credential | Set-ATSSMWindowsAdminUser -InstanceId i-00000000,i-00000001
        Prompt for credential and add as an admin user on given instances.

    .EXAMPLE
        Set-ATSSMWindowsAdminUser -InstanceId i-00000000,i-00000001 -Username jdoe -Password Password1
        Add given user with password as admin on given instances.
#>
    param
    (
        [Parameter(Mandatory = $true)]
        [string[]]$InstanceId,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByUserName')]
        [string]$Username,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByUserName')]
        [string]$Password,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByCredential', ValueFromPipeline = $true)]
        [PSCredential]$Credential
    )

    $instanceTypes = Get-SSMEnabledInstances -InstanceId $InstanceId

    if (-not $instanceTypes.Windows)
    {
        Write-Warning "No instances found that are Windows, running, passed status checks, SSM enabled and ready."
        return
    }

    Write-Host "Setting credentials on $($instanceTypes.Windows -join ', ')"

    if ($PSCmdlet.ParameterSetName -eq 'cred')
    {
        $nc = $Credential.GetNetworkCredential()
        $Username = $nc.UserName
        $Password = $nc.Password
    }

    $script = "net user $Username `"$Password`" /add ; net localgroup Administrators $Username /add"

    Invoke-ATSSMPowerShellScript -InstanceIds $InstanceId -ScriptBlock ([scriptblock]::Create($script)) -AsText
    $script = $null
}