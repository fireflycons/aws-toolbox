---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Get-ATEC2LatestAMI.md
schema: 2.0.0
---

# Invoke-ATSSMPowerShellScript

## SYNOPSIS
Run PowerShell on hosts using SSM AWS-RunPowerShellScript.

## SYNTAX

### json
```
Invoke-ATSSMPowerShellScript -InstanceIds <String[]> [-ScriptBlock] <ScriptBlock> [-AsJson]
 [-ExecutionTimeout <Int32>] [-DeliveryTimeout <Int32>] [<CommonParameters>]
```

### text
```
Invoke-ATSSMPowerShellScript -InstanceIds <String[]> [-ScriptBlock] <ScriptBlock> [-AsText]
 [-ExecutionTimeout <Int32>] [-DeliveryTimeout <Int32>] [<CommonParameters>]
```

## DESCRIPTION
{{Fill in the Description}}

## EXAMPLES

### EXAMPLE 1
```
Invoke-ATSSMPowerShellScript -InstanceIds ('i-00000001', 'i-00000002') -ScriptBlock { net user me mypassword /add ; net localgroup Administrators me /add }
```

Creates a windows user and adds to local administrators group on given instances

### EXAMPLE 2
```
Invoke-ATSSMPowerShellScript -InstanceIds ('i-00000001', 'i-00000002') -AsJson -ScriptBlock { Invoke-RestMethod http://localhost/status | ConvertTo-Json }
```

Calls a local rest service, returning a JSON string and parse the result back into an object.

### EXAMPLE 3
```
Invoke-ATSSMPowerShellScript -InstanceIds i-00000000 -AsText { dir c:\ }
```

Returns directory listing from remote instance to the console.

## PARAMETERS

### -InstanceIds
List of instance IDs identifying instances to run the script on.

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

### -ScriptBlock
ScriptBlock containing the script to run.

```yaml
Type: ScriptBlock
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsJson
If set, attempt to parse command output as a JSON string and convert to an object.

```yaml
Type: SwitchParameter
Parameter Sets: json
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -AsText
Print command output from each instance to the console

```yaml
Type: SwitchParameter
Parameter Sets: text
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -ExecutionTimeout
The time in seconds for a command to be completed before it is considered to have failed.
Default is 3600 (1 hour).
Maximum is 172800 (48 hours).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 3600
Accept pipeline input: False
Accept wildcard characters: False
```

### -DeliveryTimeout
The time in seconds for a command to be delivered to a target instance.
Default is 600 (10 minutes).

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 600
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### [PSObject], none
### If -AsText specified, then none
### Else
### List of PSObject, one per instance containing the following fields
### - InstanceId   Instance for which this result pertains to
### - ResultObject If -AsJson and the result was successfully parsed, then an object else NULL
### - ResultText   Standard Output returned by the script (Write-Host etc.)
## NOTES

## RELATED LINKS
