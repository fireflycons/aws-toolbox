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

        [Parameter(Mandatory = $true, ParameterSetName = 'ByUsername')]
        [string]$Username,

        [Parameter(Mandatory = $true, ParameterSetName = 'ByUsername')]
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

    if ($PSCmdlet.ParameterSetName -eq 'ByCredential')
    {
        $nc = $Credential.GetNetworkCredential()
        $Username = $nc.Username
        $Password = $nc.Password
    }

    # Scriptblock to manipulate local users via ADSI,
    # as the PowerShell localgroup module is not available by default prior to Windows 2016.
    $scriptblock = {

        $username = '#USER#'
        $pwd = '#PASSWORD#'
        $computer = [ADSI]"WinNT://$($env:COMPUTERNAME),computer"

        # Get existing users
        $users = $computer.PSBase.Children |
        Where-Object {
            $_.PSBase.SchemaClassName -match 'user'
        } |
        ForEach-Object {
            $_.Path.SubString($_.Path.LastIndexOf('/') + 1)
        }

        if ($users -icontains $username)
        {
            "User $username exists - changing password."
            $user = [ADSI]"WinNT://$($env:COMPUTERNAME)/$($username),user"
            $user.SetPassword($pwd)
            $user.SetInfo()
        }
        else
        {
            # Add user
            $user = $computer.Create('User', $username)
            $user.SetPassword($pwd)
            $user.put("Description", 'Added via SSM')
            $user.SetInfo()

            "Created user $username"

            # Add to administrators
            $group = [ADSI]"WinNT://$($env:COMPUTERNAME)/Administrators,group"
            $group.Add("WinNT://$($username),user")

            "Added $username to Administrators"
        }
    }

    # Inject credentials into script block
    $scriptblock = [ScriptBlock]::Create($scriptblock.ToString().Replace('#USER#', $Username).Replace('#PASSWORD#', $Password))

    Invoke-ATSSMPowerShellScript -InstanceIds $InstanceId -ScriptBlock $scriptblock -AsText
    $scriptblock = $null
}