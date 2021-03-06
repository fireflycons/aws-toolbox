function Read-ATCWLFlowLog
{
<#
    .SYNOPSIS
        Read a flow log into a list of PowerShell custom objects

    .DESCRIPTION
        Read a flow log into a list of PowerShell custom objects and emits this as the result of the script.
        The various fields of the flow log are parsed out and can be accessed as properties of the returned
        object simplifying sorting and searching of the log events.

        You can pipe the output to Out-GridView to view quickly or Export-Csv for further analysis in Excel.

    .PARAMETER LogGroupName
        The name of the log group.

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
        Sets the time range to the last X minutes from now.

    .PARAMETER FilterPattern
        Applies a server-side filter to the results.  This filters the results before they are returned by AWS. If not provided, all the events are matched.
        See Related Links for a link to filter syntax.

    .EXAMPLE
        Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -Last 30
        Read all events for the last 30 minutes.

    .EXAMPLE
        Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all,eni-00000000000000001-all -Last 30 -Interleaved
        Read all events for the last 30 minutes for two interfaces and interleave the results.

    .EXAMPLE
        Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30)) | Where-Object { $_.DestPort -eq 80 }
        Read all events for the given range and filter client-side (slow, uses more memory)

    .EXAMPLE
        Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30)) -FilterPattern "[Version,AccountId,InterfaceId,SourceAddress,DestAddress,SourcePort,DestPort=80,...]"
        Read all events for the given range and filter server side (fast, but tricky syntax)

    .NOTES
        IAM permissions required to run this command
        - logs:FilterLogEvents

        Each object has the following fields

        | Property      | Description|
        |---------------|---------------------------------------------------------------------------------------------------------------------|
        | Version       | The VPC Flow Logs version.|
        | AccountId     | The AWS account ID for the flow log.|
        | InterfaceId   | The ID of the network interface for which the traffic is recorded.|
        | SourceAddress | The source IPv4 or IPv6 address.|
        | DestAddress   | The destination IPv4 or IPv6 address|
        | SourcePort    | The source port of the traffic.|
        | DestPort      | The destination port of the traffic.|
        | Protocol      | The IANA protocol number of the traffic.|
        | Packets       | The number of packets transferred during the capture window.|
        | Bytes         | The number of bytes transferred during the capture window.|
        | StartTime     | The time, as a local DateTime, of the start of the capture window.|
        | EndTime       | The time, as a local DateTime, of the end of the capture window.|
        | Action        | The action associated with the traffic: ACCEPT or REJECT|
        | Status        | The logging status of the flow log: OK, NODATA or SKIPDATA|

        Notes
        - IPv4 addresses for network interfaces are always their private IPv4 address.

    .INPUTS
        None

    .OUTPUTS
        [object]
        List of parsed flow log entries. See Notes for a description of the fields.

    .LINK
        https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATCWLFlowLog.md

    .LINK
        https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html

    .LINK
        http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml

    .LINK
        https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html
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

        [string]$FilterPattern = [string].Empty
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
                        $h[$_] = $epoch.AddSeconds([long]::Parse($h[$_])).ToLocalTime()
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
}