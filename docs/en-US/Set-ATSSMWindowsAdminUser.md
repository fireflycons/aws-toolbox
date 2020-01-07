---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackProtectionPolicy.md
schema: 2.0.0
---

# Set-ATSSMWindowsAdminUser

## SYNOPSIS
Use SSM to set up an admin user on one or more Windows instances

## SYNTAX

### ByUsername
```
Set-ATSSMWindowsAdminUser -InstanceId <String[]> -Username <String> -Password <String> [<CommonParameters>]
```

### ByCredential
```
Set-ATSSMWindowsAdminUser -InstanceId <String[]> -Credential <PSCredential> [<CommonParameters>]
```

## DESCRIPTION
Uses SSM to set up a user from the given credentials as a local administrator on the target instances.
Instances are checked for being Windows, running, passed status checks and SSM enabled.
This is good for instances created without a key pair, or just to create a user that isn't Administrator.

## EXAMPLES

### EXAMPLE 1
```
Get-Credential | Set-ATSSMWindowsAdminUser -InstanceId i-00000000,i-00000001
```

Prompt for credential and add as an admin user on given instances.

### EXAMPLE 2
```
Set-ATSSMWindowsAdminUser -InstanceId i-00000000,i-00000001 -Username jdoe -Password Password1
```

Add given user with password as admin on given instances.

## PARAMETERS

### -InstanceId
List of instance IDs on which to set credential

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Username
Username to set

```yaml
Type: String
Parameter Sets: ByUsername
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Password
Password to set

```yaml
Type: String
Parameter Sets: ByUsername
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Credential
PSCredential containing credentials to set.

```yaml
Type: PSCredential
Parameter Sets: ByCredential
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
