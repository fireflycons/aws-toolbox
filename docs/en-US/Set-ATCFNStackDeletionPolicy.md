---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackDeletionPolicy.md
schema: 2.0.0
---

# Set-ATCFNStackDeletionPolicy

## SYNOPSIS
Set or remove stack policy to prevent replacement or deletion of resources

## SYNTAX

```
Set-ATCFNStackDeletionPolicy [-Stack] <Object[]> [-Action] <String> [<CommonParameters>]
```

## DESCRIPTION
WARNING - Setting policy on the objects within the nested stack does NOT prevent the nested stack being deleted by its parent!

This is a fairly simple utility to protect/unprotect all resources within a stack
such that you can prevent accidental deletions or replacements which would interrupt service.

Policy for the entire stack is REPLACED by this script, so only use it if you want to set blanket policy
Don't use it if you want finer-grained policies.

If the stack being processed is a nested stack, policy is set in the parent stack to prevent delete/replace operations.
Attempts to remove one of the nested stacks will result in an error during changeset calculation and thus prevent nested stack deletion.

## EXAMPLES

### EXAMPLE 1
```
Get-CFNStack | Where-Object { $_.StackName -like 'MyStack-MyNestedStack*' } | Set-ATCFNStackDeletionPolicy -Action Protect
```

Protect all resources in all stacks with names beginning with MyStack-MyNestedStack

## PARAMETERS

### -Stack
One or more stacks by name, or as stack objects (output of Get-CFNStack)
This parameter accepts pipeline input

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Action
Action to perform for all resources within the given stacks

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
IAM permissions required to run this command
- cloudformation:DescribeStacks
- cloudformation:DescribeStackResources
- cloudformation:GetStackPolicy
- cloudformation:SetStackPolicy

## RELATED LINKS

[https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackDeletionPolicy.md](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackDeletionPolicy.md)

