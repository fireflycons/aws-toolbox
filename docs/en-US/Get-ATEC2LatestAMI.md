---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Get-ATEC2LatestAMI.md
schema: 2.0.0
---

# Get-ATEC2LatestAMI

## SYNOPSIS
Build a CloudFormation mapping for the latest version of an AMI in all accessible regions.

## SYNTAX

### ByName
```
Get-ATEC2LatestAMI -ImageName <String> -MappingName <String> [<CommonParameters>]
```

### ByFilter
```
Get-ATEC2LatestAMI -Filter <Object> -MappingName <String> [<CommonParameters>]
```

## DESCRIPTION
Given an AMI search filter, the script enumerates all known regions looking for the newest AMI that matches the criteria
Depending on where you are and your account permissions, some regions will not return a value e.g.
China and Gov Cloud.
Ensure you have the latest version of AWSPowerShell if AWS has recently added new regions.

## EXAMPLES

### EXAMPLE 1
```
Get-LatestAMI -ImageName 'amzn-ami-vpc-nat-hvm*' -MappingName 'NatAMI' | ConvertTo-Json
```

Gets the latest Amazon Linux NAT instance AMIs.

### EXAMPLE 2
```
Get-LatestAMI -Filter @{'Name' = 'name'; Values = 'amzn-ami-vpc-nat-hvm*'} -MappingName 'NatAMI' | ConvertTo-Json
```

Gets the latest Amazon Linux NAT instance AMIs using a filter expression.

## PARAMETERS

### -ImageName
Name of image to search for (may include wildcards).

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Filter
Filter in Amazon filter syntax to more accurately specify an image to search for.

```yaml
Type: Object
Parameter Sets: ByFilter
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MappingName
Name of the mapping to generate.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### A hashtable of hashtables which can be piped to ConvertTo-Json to get a block of code that can be pasted into a CF template.
### If you have installed a YAML converter like https://github.com/cloudbase/powershell-yaml, then the output can also be piped to ConvertTo-Yaml.
### Or you can use the result object itself in some other process.
## NOTES
IAM permissions required to run this command
- ec2:DescribeImages

## RELATED LINKS

[https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Get-ATEC2LatestAMI.md](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Get-ATEC2LatestAMI.md)

