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

### DotNet
```
Get-ATIAMSessionCredentials [-DotNetConstructor] [-ClipBoard] [<CommonParameters>]
```

### AwsCli
```
Get-ATIAMSessionCredentials [-AwsCli] [<CommonParameters>]
```

## DESCRIPTION
If your organisation uses federated authentication (SAML etc) for API authentication with AWS,
this cmdlet enables you to get a set of temporary keys for use with applications that do not
understand/support this authentication method.

Various means of acquiring/storing the credentials are provided by this cmdlet.

You must first authenticate with AWS using the account you need keys for via Set-AWSCredential.

## EXAMPLES

### EXAMPLE 1
```
Get-ATIAMSessionCredentials
```

With no parameters (or with -SetLocal), sets up the AWS environment variables in the current shell

### EXAMPLE 2
```
Get-ATIAMSessionCredentials -Bash -ClipBoard
```

Copies shell EXPORT statements to create the AWS environment variables for sh/bash direct to clipboard.
Paste into your shell environment.

### EXAMPLE 3
```
Get-ATIAMSessionCredentials -Ruby -ClipBoard
```

Copies ruby ENV statements to create the AWS environment variables for ruby direct to clipboard.
Paste into your irb shell environment.

### EXAMPLE 4
```
credential_process = powershell.exe -Command "Import-Module aws-toolbox; Set-AWSCredential -ProfileName your_federated_creds_profile; Get-ATIAMSessionCredentials -AwsCli"
```

This example is a line you would put into your aws/credentials file.

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

### -DotNetConstructor
The credentials are formatted as new SessionAWSCredentials(...) and output to the console.
Note that you would not want to store this in any code.
Useful only for quick debugging.

```yaml
Type: SwitchParameter
Parameter Sets: DotNet
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
Parameter Sets: Ruby, Shell, DotNet
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AwsCli
Instructs the command to return a credential source for use with aws cli.
See https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sourcing-external.html

```yaml
Type: SwitchParameter
Parameter Sets: AwsCli
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
