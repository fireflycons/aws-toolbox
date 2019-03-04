---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: http://winmerge.org/
schema: 2.0.0
---

# Get-ATEBEnvironmentResourceList

## SYNOPSIS
Gets a list of resources accociated Elastic Beanstalk environents

## SYNTAX

### Id
```
Get-ATEBEnvironmentResourceList [-EnvironmentId <String>] [-AsText] [<CommonParameters>]
```

### Name
```
Get-ATEBEnvironmentResourceList [-EnvironmentName <String>] [-AsText] [<CommonParameters>]
```

### App
```
Get-ATEBEnvironmentResourceList [-ApplicationName <String>] [-AsText] [<CommonParameters>]
```

## DESCRIPTION
This command gets essential information about the resources in a beanstalk environment
Resource information is retured as an object by default so you can do further processing,
however addition of -AsText switch instead prints out the information and the command returns nothing

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

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
Position: Named
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
