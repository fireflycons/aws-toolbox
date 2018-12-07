---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackProtectionPolicy.md
schema: 2.0.0
---

# Set-ATCFNStackProtectionPolicy

## SYNOPSIS
Set or remove stack policy to prevent replacement or deletion of resources

## SYNTAX

```
Set-ATCFNStackProtectionPolicy [-Stack] <Object[]> [-Action] <String> [-Force] [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
WARNING - This command modifies resources.
Test properly in stacks that you don't mind breaking before running in a prod environment.

WARNING - Setting policy on the objects within the nested stack does NOT prevent the nested stack being deleted by its parent.

This is a fairly simple utility to protect/unprotect all resources within a stack
such that you can prevent accidental deletions or replacements which would interrupt service.

Policy for entire nested stacks is REPLACED by this script, so only use it if you want to set blanket policy
Don't use it if you want finer-grained policies.

If the stack being processed is a nested stack, policy is set in the parent stack to prevent delete/replace operations.
Parent stack policy is additive, i.e.
other policies are not replaced.
Attempts to remove one of the nested stacks will result in an error during changeset calculation and thus prevent nested stack deletion.

## EXAMPLES

### EXAMPLE 1
```
Get-CFNStack | Where-Object { $_.StackName -like 'MyStack-MyNestedStack*' } | Set-ATCFNStackProtectionPolicy -Action Protect
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

### -Force
If set, do not abort if any of the stacks in scope are updating.
Policy will be set on those which are not updating only.
Probably not what you want, but you can re-run the command once all stacks are stable.

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

### -PassThru
If set, ARNS of all stacks that were changed are emitted.

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

### [string] - Stack Name
### [Amazon.CloudFormation.Model.Stack] - Stack object
## OUTPUTS

### [string]
### ARNs of stacks that were successfully updated
### Or none, if -PassThru not specified.
## NOTES
IAM permissions required to run this command
- cloudformation:DescribeStacks
- cloudformation:DescribeStackResources
- cloudformation:GetStackPolicy
- cloudformation:SetStackPolicy

## RELATED LINKS

[https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackProtectionPolicy.md](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackProtectionPolicy.md)

