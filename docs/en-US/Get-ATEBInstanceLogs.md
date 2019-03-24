---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: http://winmerge.org/
schema: 2.0.0
---

# Get-ATEBInstanceLogs

## SYNOPSIS
Retrieve CloudFormation Init and Elastic Beanstalk instance logs from one or more instances.

## SYNTAX

### ByEnvName (Default)
```
Get-ATEBInstanceLogs [[-EnvironmentName] <String>] [-OutputFolder <String>] [<CommonParameters>]
```

### ByInstance
```
Get-ATEBInstanceLogs [-InstanceId <String[]>] [-OutputFolder <String>] [<CommonParameters>]
```

### ByEnvId
```
Get-ATEBInstanceLogs [-EnvironmentId <String>] [-OutputFolder <String>] [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -InstanceId
One or more instance Ids.

```yaml
Type: String[]
Parameter Sets: ByInstance
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnvironmentId
ID of an Elastic Beanstalk environment.
All running instances will be queried.

```yaml
Type: String
Parameter Sets: ByEnvId
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnvironmentName
Name of an Elastic Beanstalk environment.
All running instances will be queried.

```yaml
Type: String
Parameter Sets: ByEnvName
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OutputFolder
Name of folder to write logs to.
If omitted a folder EB-Logs will be created in the current folder.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
For this to succeed, your instances must have the SSM agent installed (generally the default with recent AMIs),
and they must have a profile which includes AmazonEC2RoleforSSM managed policy,

## RELATED LINKS
