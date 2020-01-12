---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackProtectionPolicy.md
schema: 2.0.0
---

# Set-ATIAMCliExternalCredentials

## SYNOPSIS
Configue aws-toolbox as an AWS CLI Credential Process

## SYNTAX

```
Set-ATIAMCliExternalCredentials [[-CliProfileName] <String>] -ProfileName <String> [<CommonParameters>]
```

## DESCRIPTION
This cmdlet maps a PowerShell stored profile into the AWS CLI credential file
as a provider of external credentials.
This is useful to get AWS CLI to use a
saved SAML profile when e.g.
you use Active Directory integration to authenticate
with AWS

## EXAMPLES

### EXAMPLE 1
```
Set-ATIAMCliExternalCredentials -ProfileName MySamlProfile
```

Creates an AWS CLI external credential profile named 'MySamlProfile' that maps onto the PowerShell profile named 'MySamlProfile'

### EXAMPLE 2
```
Set-ATIAMCliExternalCredentials -ProfileName MySamlProfile -CliProfileName MyCliSamlProfile
```

Creates an AWS CLI external credential profile named 'MyCliSamlProfile' that maps onto the PowerShell profile named 'MySamlProfile'

## PARAMETERS

### -CliProfileName
Name of profile to create in CLI credentials file.
If omitted, then the name
passed to ProfileName will be used.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProfileName
Name of PowerShell stored profile to use

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

## NOTES

## RELATED LINKS
