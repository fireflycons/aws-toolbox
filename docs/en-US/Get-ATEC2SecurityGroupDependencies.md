---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Get-ATEC2LatestAMI.md
schema: 2.0.0
---

# Get-ATEC2SecurityGroupDependencies

## SYNOPSIS
Find all dependencies of a given security group or groups.

## SYNTAX

```
Get-ATEC2SecurityGroupDependencies [[-GroupId] <String[]>] [-AsText] [<CommonParameters>]
```

## DESCRIPTION
You cannot delete a security group if it is in use anywhere.
Usages come down to whether it is bound to any network interface (e.g.
instance or laod balancer),
or whether it is referenced as the target of a rule in another security group.

This cmdlet enables you to determine what may be linked to the given security group so you can
break those links prior to deleting it.

## EXAMPLES

### EXAMPLE 1
```
Get-ATEC2SecurityGroupDependencies -GroupId sg-00000000 -AsText
```

List dependencies of given group to console

### EXAMPLE 2
```
Get-ATEC2SecurityGroupDependencies -GroupId sg-00000000
```

Return dependencies of given group as object

### EXAMPLE 3
```
(Get-ATEBEnvironmentResourceList my-eb-environment).Instances.SecurityGroups.SecurityGroupId | sort -Unique | Get-ATEC2SecurityGroupDependencies -AsText
```

List dependencies of security groups attached to instances of an Elastic Beanstalk environment to console.

### EXAMPLE 4
```
(Get-ATEBEnvironmentResourceList my-eb-environment).LoadBalancers.SecurityGroups.SecurityGroupId | Get-ATEC2SecurityGroupDependencies -AsText
```

List dependencies of security groups attached to load balancers of an Elastic Beanstalk environment to console.

## PARAMETERS

### -GroupId
One or more security groups to obtain dependency information for

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -AsText
If set, print a report to the console, else returns an object that can be used by a calling script.
Where possible, if a dependency belongs to a cloudformation stack, then the owning stack name is shown in parentheses.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### [string]
### Security Group ID(s)
## OUTPUTS

### [object]
### Or nothing if -AsText
## NOTES
IAM permissions required to run this command

- ec2:DescribeSecurityGroups
- ec2:DescribeTags
- elasticloadbalancing:DescribeLoadBalancers
- elasticloadbalancing:DescribeTags

## RELATED LINKS
