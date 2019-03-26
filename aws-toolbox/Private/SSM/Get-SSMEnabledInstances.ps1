function Get-SSMEnabledInstances
{
    <#
    .SYNOPSIS
        Given a list of instance IDs, find those that are SSM enabled
        and sort into Windows and non-Windows

    .PARAMETER InstanceId
        List of instance IDs to check

    .OUTPUTS
        [PSObject] with the following fields
        - Windows       List of SSM enabled Windows instances
        - NonWindows    List of SSM enabled non-Windows instances
        - NonSSM        List of instances that aren't SSM enabled, or SSM not ready
        - NotReady      List of instances that are not running and passed status checks
#>
    param
    (
        [Parameter(Mandatory = $true)]
        [string[]]$InstanceId
    )

    $retval = New-Object PSObject -Property @{
        Windows    = $null
        NonWindows = $null
        NonSSM     = $null
        NotReady   = $null
    }

    $instances = $InstanceId
    $notReadyInstances = $null
    $nonSsmInstances = $null
    $windowsInstances = $null
    $nonWindowsInstances = $null

    # Filter down to running instances that have passed status checks
    $readyInstances = Get-EC2InstanceStatus -InstanceId $instances |
        Where-Object {

        $_.InstanceState.Code -eq 16 -and $_.Status.Status.Value -ieq 'ok' -and $_.SystemStatus.Status.Value -ieq 'ok'
    } |
        Select-Object -ExpandProperty InstanceId

    if ($readyInstances)
    {
        $notReadyInstances = Compare-Object -ReferenceObject $instances -DifferenceObject $readyInstances -PassThru
    }

    if ($notReadyInstances)
    {
        $retval.NotReady = $notReadyInstances
    }

    $instances = $readyInstances

    if (-not $instances)
    {
        # No instances ready - stop now
        return $retval
    }

    # Now filter to ones that respond to SSM
    $ssmInstances = Get-SSMInstanceInformation -Filter @{
        Key    = 'InstanceIds'
        Values = $instances
    } |
        Select-Object -ExpandProperty InstanceId

    if ($ssmInstances)
    {
        $nonSsmInstances = Compare-Object -ReferenceObject $instances -DifferenceObject $ssmInstances -PassThru
    }

    if ($nonSsmInstances)
    {
        $retval.NonSSM = $nonSsmInstances
    }

    $instances = $ssmInstances

    if (-not $instances)
    {
        # No instances SSM capable - stop now
        return $retval
    }

    # Now sort Windows from non-Windows
    $windowsInstances = (Get-EC2Instance -InstanceId $instances) |
        Select-Object -ExpandProperty Instances |
        Where-Object {
        $_.Platform -ieq 'Windows'
    } |
        Select-Object -ExpandProperty InstanceId

    if ($windowsInstances)
    {
        $nonWindowsInstances = Compare-Object -ReferenceObject $instances -DifferenceObject $windowsInstances -PassThru
    }

    if ($windowsInstances)
    {
        $retval.Windows = $windowsInstances
    }

    if ($nonWindowsInstances)
    {
        $retval.NonWindows = $nonWindowsInstances
    }

    $retval
}