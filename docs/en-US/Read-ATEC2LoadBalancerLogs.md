---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATEC2LoadBalancerLogs.md
schema: 2.0.0
---

# Read-ATEC2LoadBalancerLogs

## SYNOPSIS
Read Load Balancer logs into a list of PowerShell custom objects

## SYNTAX

### LastX (Default)
```
Read-ATEC2LoadBalancerLogs [-LoadBalancer <Object>] [-AccountId <String>] [-Last <Int32>] [-LimitSize <Int64>]
 [<CommonParameters>]
```

### Range
```
Read-ATEC2LoadBalancerLogs [-LoadBalancer <Object>] [-AccountId <String>] [-StartTime <DateTime>]
 [-EndTime <DateTime>] [-LimitSize <Int64>] [<CommonParameters>]
```

## DESCRIPTION
Read load balancer logs into a list of PowerShell custom objects and emits this as the result of the script.
The various fields of the flow log are parsed out and can be accessed as properties of the returned
object simplifying sorting and searching of the log events.

You can pipe the output to Out-GridView to view quickly or Export-Csv for further analysis in Excel.

Logs can be very large especially on high traffic sites so you should keep time constraints small.
If you need to analyse logs over a large period, you'll be better off doing it with Athena.

## EXAMPLES

### EXAMPLE 1
```
Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer my-loadbalancer -Last 30
```

Read all events for the last 30 minutes.

### EXAMPLE 2
```
Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer my-loadbalancer -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30))
```

Read all events for the given range.

### EXAMPLE 3
```
$lb = Get-ELBLoadBalancer -LoadBalancerName my-loadbalancer ; Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer $lb -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30))
```

Read all events for Classic ELB for the given range with a load balancer object as input.

### EXAMPLE 4
```
$lb = Get-ELB2LoadBalancer -LoadBalancerName my-loadbalancer ; Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer $lb -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30))
```

Read all events for ALB for the given range with a load balancer object as input.

## PARAMETERS

### -LoadBalancer
Nome of load balancer, or object returned by Get-ELBLoadBalancer or Get-ELB2LoadBalancer
Load balancer to get logs for.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AccountId
AWS Account id of the account that contains the load balancer.
If not specified it will be detected from the account you are running this command under.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
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
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -LimitSize
Limit the size of the log download.
If the combined size of all the logs to download exceeds this size in bytes, the command will abort.

```yaml
Type: Int64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 524288000
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [object]
### List of parsed log entries. Fields depend on whether the target load balancer is classic or application.
### Both LB types have an additional field:
### - elb_node_ip: IP of the load balancer node that handled the request
## NOTES
IAM permissions required to run this command
- sts:GetCallerIdentity (when -AccountId is not specified)
- ec2:DescribeLoadBalancers (when -LoadBalancer is a name)
- ec2:DescribeLoadBalancerAttributes
- s3:GetBucketLocation
- s3:GetObject
- s3:ReadObject

## RELATED LINKS

[https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATEC2LoadBalancerLogs.md](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATEC2LoadBalancerLogs.md)

[https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html](https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html)

[https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html)

