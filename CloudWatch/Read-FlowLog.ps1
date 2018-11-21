<#
    .SYNOPSIS
        Read a flow log into a list of PowerShell custom objects

    .DESCRIPTION
        Read a flow log into a list of PowerShell custom objects and emits this as the result of the script.
        The various fields of the flow log are parsed out and can be accesses as properties of the returned
        object simplifying sorting and searching of the log events.

    .PARAMETER LogGroupName
        The name of the log group. Defaults to 'Flow-Logs'

    .PARAMETER LogStreamName
        The name of the log stream.

    .PARAMETER Interleaved
        If the value is true, the operation makes a best effort to provide responses that contain events from multiple log streams within the log group, interleaved in a single response.
        If the value is false, all the matched log events in the first log stream are searched first, then those in the next log stream, and so on. The default is false.

    .PARAMETER StartTime
        The start of the time range. Events with a time stamp equal to this time or later than this time are included. Events with a time stamp earlier than this time are not included.

    .PARAMETER EndTime
        The end of the time range. Events with a time stamp equal to or later than this time are not included.

    .PARAMETER Last
        Sets the time range to the last X minutes from now. Default of 30 minutes.

    .PARAMETER FilterPattern
        Applies a server-side filter to the results.  This filters the results before they are returned by AWS. If not provided, all the events are matched.
        Filter syntax is described here: https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html

    .PARAMETER Profile
        Name of a stored profile to use for authentication. If omitted, instance profile credentials, or existing shell credentials are used.

    .EXAMPLE
        Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -StartTime ([DateTime]::UtcNow.AddHours(-1)) | Where-Object { $_.DestPort -eq 80 } | Out-GridView
        Filter client-side (slow, uses more memory)

    .EXAMPLE
        Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -StartTime ([DateTime]::UtcNow.AddHours(-1)) -FilterPattern "[Version,AccountId,InterfaceId,SourceAddress,DestAddress,SourcePort,DestPort=80,...]" | Out-GridView
        Filter server side (fast, but tricky syntax)

    .NOTES
        IAM permissions required to run this script
            logs:FilterLogEvents

    .INPUTS
        None

    .OUTPUTS
        [object]
        List of parsed flow log entries

    .LINK
        https://github.com/fireflycons/aws-toolbox/tree/master/CloudWatch
#>
[CmdletBinding(DefaultParametersetname='LastX')]
param
(
    [string]$LogGroupName = 'Flow-Logs',

    [Parameter(Mandatory = $true)]
    [string[]]$LogStreamName,

    [switch]$Interleaved,

    [Parameter(ParameterSetName = 'Range')]
    [DateTime]$StartTime,

    [Parameter(ParameterSetName = 'Range')]
    [DateTime]$EndTime,

    [Parameter(ParameterSetName = 'LastX')]
    [int]$Last = 30,

    [string]$FilterPattern = [string].Empty,

    [string]$Profile,

    [string]$Region
)

$ErrorActionPreference = 'Stop'

# Test for AWS
$script:IsRunningInAws = $(
    try
    {
        Invoke-RestMethod -Uri 'http://169.254.169.254/latest/meta-data/instance-id' | Out-Null
        $true
    }
    catch
    {
        $false
    }
)

# Import modules
if (-not (Get-Module -Name AWSPowerShell -ErrorAction SilentlyContinue))
{
    Write-Host 'Loading modules...'
    Import-Module AWSPowerShell
}

# Set up credentials if given
if ($Profile)
{
    Set-AWSCredential -ProfileName $Profile

    if ($Region)
    {
        Set-DefaultAWSRegion -Region eu-west-1
    }
}
elseif (-not (($script:IsRunningInAws) -or $null -ne (Get-Item variable:StoredAWSCredentials -ErrorAction SilentlyContinue)))
{
    throw "Not running inside EC2 and no initialised credential found. Use -Profile or or one of the credential cmdlets with keys for the target account."
}

# Count all the events read
$totalEvents = 0

# Regex for deconstructing log record
$logMessageRx = '^(?<Version>\d+)\s+(?<AccountId>\d+)\s+(?<InterfaceId>[\w-]+)\s+(?<SourceAddress>\d+\.\d+\.\d+\.\d+)\s+(?<DestAddress>\d+\.\d+\.\d+\.\d+)\s+(?<SourcePort>\d+)\s+(?<DestPort>\d+)\s+(?<Protocol>\d+)\s+(?<Packets>\d+)\s+(?<Bytes>\d+)\s+(?<StartTime>\d+)\s+(?<EndTime>\d+)\s+(?<Action>\w+)\s+(?<Status>\w+)'

# UNIX epoch for timestamp -> DateTime
$epoch = New-Object DateTime -ArgumentList (1970, 1, 1, 0, 0, 0, 0, 'Utc')

# Create splat argument, and add start time/end time if present
$args = @{}

switch ($PSCmdLet.ParameterSetName)
{
    'LastX' {

        # Start time is $Last minutes before now
        $args.Add('StartTime', [int64](([DateTime]::UtcNow.AddMinutes(0 - $Last) - $epoch).TotalMilliseconds))
    }

    'Range' {

        # Convert user supplied start and end time to milliseconds since Unix epoch
        if ($StartTime)
        {
            $args.Add('StartTime', [int64](($StartTime.ToUniversalTime() - $epoch).TotalMilliseconds))
        }

        if ($EndTime)
        {
            $args.Add('EndTime', [int64](($EndTime.ToUniversalTime() - $epoch).TotalMilliseconds))
        }
    }
}

if ($Interleaved)
{
    # Interleave if requested
    $args.Add('Interleaved', $true)
}

$events = $(

    do
    {
        # Loop until we get no more events from AWS

        Write-Host "Reading log..."
        $log = Get-CWLFilteredLogEvent -LogGroupName $LogGroupName -LogStreamName $LogStreamName -FilterPattern $FilterPattern @args

        # Number of events in this batch
        $numEvents = ($log.Events | Measure-Object).Count

        # Add to total number processed
        $totalEvents += $numEvents

        # Numver processed in this batch (for progress meter)
        $numProcessed = 0

        Write-Host "Processing events..."
        $log.Events |
            Foreach-Object {

            # Deconstruct log record and create an object for it
            if ($_.Message -match $logMessageRx)
            {
                # Add all the named matches to a hash
                $h = @{}

                $Matches.Keys |
                    Where-Object { $_ -ine '0' } |
                    Foreach-Object {
                    $h.Add($_, $Matches[$_])
                }

                # Convert UNIX times to local DateTimes
                'StartTime', 'EndTime' |
                    Foreach-Object {
                    $h[$_] = $epoch.AddSeconds([int]::Parse($h[$_])).ToLocalTime()
                }

                # Convert integer values from strings
                'Packets', 'Version', 'SourcePort', 'Bytes', 'DestPort', 'Protocol' |
                    Foreach-Object {
                    $h[$_] = [long]::Parse($h[$_])
                }

                # Add the ingestion time which is in its own field in the event record. This one's in milliseconds since epoch
                $h.Add('IngestionTime', $epoch.AddMilliseconds($_.IngestionTime))

                # Emit new object with properties defined by the hash
                New-Object PSObject -Property $h
            }

            if (++$numProcessed % 50 -eq 0)
            {
                # Update progress every 50 records processed.
                Write-Progress -Activity "Processing event batch" -Status "$numProcessed of $numEvents" -PercentComplete ($numProcessed * 100 / $numEvents)
            }
        } |
            Select-Object -Property IngestionTime, Version, AccountId, InterfaceId, SourceAddress, DestAddress, SourcePort, DestPort, Protocol, Packets, Bytes, StartTime, EndTime, Action, Status # Order fields correctly

        # End progress
        Write-Progress -Activity "Processing event batch" -Status 'Processing' -PercentComplete 100 -Completed

        # Determine if there is more data to read and add the token argument to the argument hash for Get-CWLLogEvent
        $moreData = $false

        if ($args.ContainsKey('NextToken'))
        {
            if ($args['NextToken'] -ine $log.NextBackwardToken)
            {
                $moreData = $true
                $args['NextToken'] = $log.NextBackwardToken
            }
        }
        else
        {
            if (-not ([string]::IsNullOrEmpty($log.NextBackwardToken)))
            {
                $moreData = $true
                $args.Add('NextToken', $log.NextBackwardToken)
            }
        }
    }
    while ($moreData)
)

Write-Verbose "Total events processed   : $totalEvents"
Write-Verbose "Number of events returned: $(($events | Measure-Object).Count)"

# Emit the events.
$events

