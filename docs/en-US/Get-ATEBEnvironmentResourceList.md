---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: http://winmerge.org/
schema: 2.0.0
---

# Get-ATEBEnvironmentResourceList

## SYNOPSIS
Gets a list of resources associated Elastic Beanstalk environents.

## SYNTAX

### Name (Default)
```
Get-ATEBEnvironmentResourceList [[-EnvironmentName] <String>] [-AsText] [<CommonParameters>]
```

### Id
```
Get-ATEBEnvironmentResourceList [-EnvironmentId <String>] [-AsText] [<CommonParameters>]
```

### App
```
Get-ATEBEnvironmentResourceList [-ApplicationName <String>] [-AsText] [<CommonParameters>]
```

## DESCRIPTION
This command gets essential information about the resources in a beanstalk environment.
Resource information is retured as an object by default so you can do further processing,
however addition of -AsText switch instead prints out the information and the command returns nothing

## EXAMPLES

### EXAMPLE 1
```
Get-ATEBEnvironmentResourceList -EnvironmentName production -AsText
```

Lists the resources of the given environment to the console.

### EXAMPLE 2
```
Get-ATEBEnvironmentResourceList -EnvironmentId e-edxny3zkbp -AsText
```

Lists the resources of the given environment to the console.

### EXAMPLE 3
```
Get-ATEBEnvironmentResourceList -ApplicationName MYApplication -AsText
```

Lists the resources of all environments in the given EB application to the console.

### EXAMPLE 4
```
Invoke-ATSSMPowerShellScript -InstanceIds (Get-ATEBEnvironmentResourceList -EnvironmentName production).Instances.InstanceId -AsJson -ScriptBlock { Invoke-RestMethod http://localhost/status | ConvertTo-Json }
```

Used in conjunction with Invoke-ATSSMPowerShellScript, send a command to all instances in the given Windows environment.

### EXAMPLE 5
```
Invoke-ATSSMShellScript -InstanceIds (Get-ATEBEnvironmentResourceList -EnvironmentName production).Instances.InstanceId -CommandText "ls -la /"
```

Used in conjunction with Invoke-ATSSMShellScript, send a command to all instances in the given Linux environment.

## PARAMETERS

### -EnvironmentId
ID of an Elastic Beanstalk environment

```yaml
Type: String
Parameter Sets: Id
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -EnvironmentName
Name of an Elastic Beanstalk environment

```yaml
Type: String
Parameter Sets: Name
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApplicationName
Name of an Elastic Beanstalk application.
All environments are returned.

```yaml
Type: String
Parameter Sets: App
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsText
Print the environment information to the console instead of returning it as an object

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

### [PSObject[]] Information about each environment returned
### or nothing if -AsText specified.
## NOTES

## RELATED LINKS
