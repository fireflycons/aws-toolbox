---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version:
schema: 2.0.0
---

# Compare-ATCFNStackResourceDrift

## SYNOPSIS
Get resource drift for given stack

## SYNTAX

```
Compare-ATCFNStackResourceDrift -StackName <String> [-PassThru] [-NoReCheck] [<CommonParameters>]
```

## DESCRIPTION
Optionally run a drift check on the stack and, depending on whether -PassThru was given
either bring up the drift differences in the configured diff viewer, or output the
drifted resource information to the pipeline.

## EXAMPLES

### EXAMPLE 1
```
Compare-ATCFNStackResourceDrift -StackName my-stack
```

Run a drift check, and display any drift in the configured diff tool.

### EXAMPLE 2
```
$drifts = Compare-ATCFNStackResourceDrift -StackName my-stack -PassThru
```

Run a drift check and return any drifts in the pipeline.

### EXAMPLE 3
```
Compare-ATCFNStackResourceDrift -StackName my-stack -NoReCheck
```

Use results from last run drift check, and display any drift in the configured diff tool.

### EXAMPLE 4
```
Get-CFNStack | Compare-ATCFNStackResourceDrift -PassThru
```

Get a check on all stacks in the account for current region.
Advisable to use -PassThru or you may have a lot of diff windows opened!

## PARAMETERS

### -StackName
Name of stack to check.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PassThru
If set, then emit the drift information to the pipeline

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

### -NoReCheck
If set, use the current drift information unless the stack has never been checked in which case a check will be run.
If not set, a check is always run.

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

## OUTPUTS

### List of modified resources if -PassThru switch was present.
## NOTES

## RELATED LINKS

[Set-ATConfigurationItem]()

