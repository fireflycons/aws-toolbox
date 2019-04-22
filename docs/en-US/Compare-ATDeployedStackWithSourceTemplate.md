---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: http://winmerge.org/
schema: 2.0.0
---

# Compare-ATDeployedStackWithSourceTemplate

## SYNOPSIS
Compare a template file with what is currently deployed in CloudFormation.
Also report stack drift (items that have been updated by other means since last CloudFormation stack update).

## SYNTAX

### FromFile
```
Compare-ATDeployedStackWithSourceTemplate [-StackName <String>] [-TemplateFilePath <String>] [-WaitForDiff]
 [<CommonParameters>]
```

### FromS3
```
Compare-ATDeployedStackWithSourceTemplate [-StackName <String>] [-TemplateUri <String>] [-WaitForDiff]
 [<CommonParameters>]
```

## DESCRIPTION
This function will display any current drift report, but will additionally
compare a CloudFormation template file with what is currently deployed in the target stack.
This will show changes that cannot be picked up simply by drift reporting, e.g.
a property
that has been changed from a literal value to an expression (e.g.
Ref, Fn::If).
Where these
evaluate to the same value as the original literal, this is not reported by drift.

If running on Windows, this function will look for WinMerge to display the differences, else
it will fall back to git diff, which is the default on non-windows systems.

## EXAMPLES

### EXAMPLE 1
```
Compare-ATDeployedStackWithSourceTemplate -StackName my-stack -TemplateFilePath .\my-stack.json -WaitForDiff
```

Runs drift detection, then compares the text of my-stack.json with the current template stored with my-stack in CloudFormation. 
Waits for you to close the diff tool.

### EXAMPLE 2
```
Compare-ATDeployedStackWithSourceTemplate -StackName my-stack -TemplateURI https://s3-eu-west-1.amazonaws.com/my-bucket/my-stack.json -WaitForDiff
```

Runs drift detection, then compares the text of my-stack.json located in S3 with the current template stored with my-stack in CloudFormation. 
Waits for you to close the diff tool.

## PARAMETERS

### -StackName
Name or ARN of an existing CloudFormation Stack

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

### -TemplateFilePath
Path on disk to a CloudFormation template to compare to the stack

```yaml
Type: String
Parameter Sets: FromFile
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TemplateUri
URI of a template stored in S3 to compare to the stack

```yaml
Type: String
Parameter Sets: FromS3
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WaitForDiff
If a GUI diff tool is used to compare templates and this is set,
then the function does not return until the diff tool has been closed.
If not set, then the temp file used to store AWS's view of the template is not cleaned up.

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

## NOTES

## RELATED LINKS

[http://winmerge.org/](http://winmerge.org/)

