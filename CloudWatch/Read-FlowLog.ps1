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

    .PARAMETER StartTime
        The start of the time range. Events with a time stamp equal to this time or later than this time are included. Events with a time stamp earlier than this time are not included.

    .PARAMETER EndTime
        The end of the time range. Events with a time stamp equal to or later than this time are not included.

    .PARAMETER Profile
        Name of a stored profile to use for authentication. If omitted, instance profile credentials, or existing shell credentials are used.

    .EXAMPLE
        Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -StartTime ([DateTime]::UtcNow.AddHours(-1)) | Where-Object { $_.DestPort -eq 80 } | Out-GridView
#>
param
(
    [string]$LogGroupName = 'Flow-Logs',

    [Parameter(Mandatory = $true)]
    [string]$LogStreamName,

    [DateTime]$StartTime,

    [DateTime]$EndTime,

    [string]$Profile
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
    Initialize-AWSDefaults -ProfileName $Profile -Region eu-west-1
}
elseif (-not (($script:IsRunningInAws) -or $null -ne (Get-Item variable:StoredAWSCredentials -ErrorAction SilentlyContinue)))
{
    throw "Not running inside EC2 and no initialised credential found. Use -Profile or call Initialize-AWSDefaults with keys for the target account."
}

# Create splat argument, and add start time/end time if present
$args = @{}

if ($StartTime)
{
    $args.Add('StartTime', $StartTime)
}

if ($EndTime)
{
    $args.Add('EndTime', $EndTime)
}

# Count all the events read
$totalEvents = 0

# Regex for deconstructing log record
$logMessageRx = '^(?<Version>\d+)\s+(?<AccountId>\d+)\s+(?<InterfaceId>[\w-]+)\s+(?<SourceAddress>\d+\.\d+\.\d+\.\d+)\s+(?<DestAddress>\d+\.\d+\.\d+\.\d+)\s+(?<SourcePort>\d+)\s+(?<DestPort>\d+)\s+(?<Protocol>\d+)\s+(?<Packets>\d+)\s+(?<Bytes>\d+)\s+(?<StartTime>\d+)\s+(?<EndTime>\d+)\s+(?<Action>\w+)\s+(?<Status>\w+)'

# UNIX epoch for timestamp -> DateTime
$epoch = New-Object DateTime -ArgumentList (1970, 1, 1, 0, 0, 0, 0, 'Utc')

$events = $(

    do
    {
        # Loop until we get no more events from AWS

        Write-Host "Reading log..."
        $log = Get-CWLLogEvent -LogGroupName $LogGroupName -LogStreamName $LogStreamName @args

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

                # Add the ingestion time which is in its own field in the event record
                $h.Add('IngestionTime', $_.IngestionTime)

                # Emit new object with properties defined by the hash
                New-Object PSObject -Property $h
            }

            if (++$numProcessed % 50 -eq 0)
            {
                # Update progress every 50 records processed.
                Write-Progress -Activity "Processing event batch" -Status "$numProcessed of $numEvents" -PercentComplete ($numProcessed * 100 / $numEvents)
            }
        }

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
    while($moreData)
)

Write-Host "Total events returned: $totalEvents"

# Emit the events.
$events

