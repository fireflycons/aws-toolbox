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
Retrieve CloudFormation Init and Elastic Beanstalk instance logs from one or more instances,
and place them into a directory structure containing the logs for each selected instance.

## EXAMPLES

### EXAMPLE 1
```
Get-ATEBInstanceLogs -InstanceId i-00000000,i-00000001
```

Get Elastic Beanstalk logs from given instances and write to EB-Logs folder in current location

### EXAMPLE 2
```
Get-ATEBInstanceLogs -EnvironmentId e-a4d34fd -OutputFolder C:\Temp\EB-Logs
```

Get Elastic Beanstalk logs from instances in given EB environment by enviromnent ID and write to specified folder.

### EXAMPLE 3
```
Get-ATEBInstanceLogs -EnvironmentName my-enviromn -OutputFolder C:\Temp\EB-Logs
```

Get Elastic Beanstalk logs from instances in given EB environment by name and write to specified folder.

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
and they must have a profile which includes AmazonEC2RoleforSSM managed policy, or sufficient individual rights
to run the SSM command and write to S3.

## RELATED LINKS
