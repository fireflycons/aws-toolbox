function Invoke-ATSSMPowerShellScript
{
<#
    .SYNOPSIS
        Run PowerShell on hosts using SSM AWS-RunPowerShellScript.

    .DESCRIPTION
        Run PowerShell on hosts using SSM AWS-RunPowerShellScript.

    .PARAMETER InstanceIds
        List of instance IDs identifying instances to run the script on.

    .PARAMETER AsJson
        If set, attempt to parse command output as a JSON string and convert to an object.

    .PARAMETER AsText
        Print command output from each instance to the console

    .PARAMETER UseS3
        SSM truncates results to 2000 characters. If you expect results to exceed this, then this switch
        instructs SSM to send the results to S3. The cmdlet will retrieve these results and return them.

    .PARAMETER CommandText
        ScriptBlock containing the script to run.

    .PARAMETER ExecutionTimeout
         The time in seconds for a command to be completed before it is considered to have failed. Default is 3600 (1 hour). Maximum is 172800 (48 hours).

    .PARAMETER Deliverytimeout
        The time in seconds for a command to be delivered to a target instance. Default is 600 (10 minutes).

    .OUTPUTS
        [PSObject], none
        If -AsText specified, then none
        Else
        List of PSObject, one per instance containing the following fields
        - InstanceId   Instance for which this result pertains to
        - ResultObject If -AsJson and the result was successfully parsed, then an object else NULL
        - ResultText   Standard Output returned by the script (Write-Host etc.)

    .NOTES
        aws-toolbox uses a working bucket for passing results through S3 which will be created if not found.
        Format of bucket name is aws-toolbox-workspace-REGIONNAME-AWSACCOUNTID

    .EXAMPLE
        Invoke-ATSSMPowerShellScript -InstanceIds ('i-00000001', 'i-00000002') -ScriptBlock { net user me mypassword /add ; net localgroup Administrators me /add }
        Creates a windows user and adds to local administrators group on given instances

    .EXAMPLE
        Invoke-ATSSMPowerShellScript -InstanceIds ('i-00000001', 'i-00000002') -AsJson -ScriptBlock { Invoke-RestMethod http://localhost/status | ConvertTo-Json }
        Calls a local rest service, returning a JSON string and parse the result back into an object.

    .EXAMPLE
        Invoke-ATSSMPowerShellScript -InstanceIds i-00000000 -AsText { dir c:\ }
        Returns directory listing from remote instance to the console.
#>
    [CmdletBinding(DefaultParameterSetName = 'AsText')]
    param
    (
        [Parameter(Mandatory=$true)]
        [string[]]$InstanceIds,

        [Parameter(Mandatory=$true, Position = 0)]

        [Alias("ScriptBlock")]
        [scriptblock]$CommandText,

        [Parameter(ParameterSetName = 'AsJson')]
        [switch]$AsJson,

        [Parameter(ParameterSetName = 'AsText')]
        [switch]$AsText,

        [switch]$UseS3,

        [int]$ExecutionTimeout = 3600,

        [int]$DeliveryTimeout = 600

    )


    $invokeArguments = @{
        ScriptType = 'WindowsPowerShell'
    }

    $PSBoundParameters.Keys |
    ForEach-Object {
        $invokeArguments.Add($_, $PSBoundParameters[$_])
    }

    Invoke-SSMCommandScript @invokeArguments
}