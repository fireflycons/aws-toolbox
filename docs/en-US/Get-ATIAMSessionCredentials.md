---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Get-ATEC2LatestAMI.md
schema: 2.0.0
---

# Get-ATIAMSessionCredentials

## SYNOPSIS
Gets keys from a federated AWS login

## SYNTAX

### SetLocal (Default)
```
Get-ATIAMSessionCredentials [-SetLocal] [<CommonParameters>]
```

### Ruby
```
Get-ATIAMSessionCredentials [-Ruby] [-ClipBoard] [<CommonParameters>]
```

### Shell
```
Get-ATIAMSessionCredentials [-Bash] [-ClipBoard] [<CommonParameters>]
```

## DESCRIPTION
If your organisaation uses federated authentication (SAML etc) for API authentication with AWS,
this cmdlet enables you to get a set of temoprary keys for use with applications that do not
understand/support this authentication method.

Various means of acquiring/storing the credentials are provided by this cmdlet.

You must first authenticate with AWS using the account you need keys for via Set-AWSCredential.

## EXAMPLES

### Example 1
```powershell
PS C:\> {{ Add example code here }}
```

{{ Add example description here }}

## PARAMETERS

### -Ruby
The credentials are formatted as ENV\[\] = staements and output to the console

```yaml
Type: SwitchParameter
Parameter Sets: Ruby
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Bash
The credentials are formatted as EXPORT staements and output to the console

```yaml
Type: SwitchParameter
Parameter Sets: Shell
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ClipBoard
If set, output of -Ruby or -Bash is copied directly to clipboard, so you can paste them into code or your active Ruby or Shell prompt

```yaml
Type: SwitchParameter
Parameter Sets: Ruby, Shell
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -SetLocal
The credentials are set as environment variables AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN in the current shell.
Proceed to run your application that supports environment-based credentails in this shell.

```yaml
Type: SwitchParameter
Parameter Sets: SetLocal
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
