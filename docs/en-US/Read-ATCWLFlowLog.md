---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATCWLFlowLog.md
schema: 2.0.0
---

# Read-ATCWLFlowLog

## SYNOPSIS
Read a flow log into a list of PowerShell custom objects

## SYNTAX

### LastX (Default)
```
Read-ATCWLFlowLog [-LogGroupName <String>] -LogStreamName <String[]> [-Interleaved] [-Last <Int32>]
 [-FilterPattern <String>] [<CommonParameters>]
```

### Range
```
Read-ATCWLFlowLog [-LogGroupName <String>] -LogStreamName <String[]> [-Interleaved] [-StartTime <DateTime>]
 [-EndTime <DateTime>] [-FilterPattern <String>] [<CommonParameters>]
```

## DESCRIPTION
Read a flow log into a list of PowerShell custom objects and emits this as the result of the script.
The various fields of the flow log are parsed out and can be accessed as properties of the returned
object simplifying sorting and searching of the log events.

You can pipe the output to Out-GridView to view quickly or Export-Csv for further analysis in Excel.

## EXAMPLES

### EXAMPLE 1
```
Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -Last 30
```

Read all events for the last 30 minutes.

### EXAMPLE 2
```
Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all,eni-00000000000000001-all -Last 30 -Interleaved
```

Read all events for the last 30 minutes for two interfaces and interleave the results.

### EXAMPLE 3
```
Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30)) | Where-Object { $_.DestPort -eq 80 }
```

Read all events for the given range and filter client-side (slow, uses more memory)

### EXAMPLE 4
```
Read-FlowLog.ps1 -Profile myprofile -LogStreamName eni-00000000000000000-all -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30)) -FilterPattern "[Version,AccountId,InterfaceId,SourceAddress,DestAddress,SourcePort,DestPort=80,...]"
```

Read all events for the given range and filter server side (fast, but tricky syntax)

## PARAMETERS

### -LogGroupName
The name of the log group.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: Flow-Logs
Accept pipeline input: False
Accept wildcard characters: False
```

### -LogStreamName
The name of the log stream.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Interleaved
If the value is true, the operation makes a best effort to provide responses that contain events from multiple log streams within the log group, interleaved in a single response.
If the value is false, all the matched log events in the first log stream are searched first, then those in the next log stream, and so on.
The default is false.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -StartTime
The start of the time range.
Events with a time stamp equal to this time or later than this time are included.
Events with a time stamp earlier than this time are not included.

```yaml
Type: DateTime
Parameter Sets: Range
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EndTime
The end of the time range.
Events with a time stamp equal to or later than this time are not included.

```yaml
Type: DateTime
Parameter Sets: Range
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Last
Sets the time range to the last X minutes from now.

```yaml
Type: Int32
Parameter Sets: LastX
Aliases:

Required: False
Position: Named
Default value: 30
Accept pipeline input: False
Accept wildcard characters: False
```

### -FilterPattern
Applies a server-side filter to the results. 
This filters the results before they are returned by AWS.
If not provided, all the events are matched.
See Related Links for a link to filter syntax.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: [string].Empty
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None
## OUTPUTS

### [object]
### List of parsed flow log entries. See Notes for a description of the fields.
## NOTES
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

## RELATED LINKS

[https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATCWLFlowLog.md](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATCWLFlowLog.md)

[https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html](https://docs.aws.amazon.com/vpc/latest/userguide/flow-logs.html)

[http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml](http://www.iana.org/assignments/protocol-numbers/protocol-numbers.xhtml)

[https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html](https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html)

