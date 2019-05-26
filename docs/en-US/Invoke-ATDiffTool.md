---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version:
schema: 2.0.0
---

# Invoke-ATDiffTool

## SYNOPSIS
Invoke the module's configured diff tool

## SYNTAX

```
Invoke-ATDiffTool [-LeftPath] <String> [-RightPath] <String> [[-LeftTitle] <String>] [[-RightTitle] <String>]
 [-Wait] [<CommonParameters>]
```

## DESCRIPTION
Invoke the module's configured diff tool.
Provides a consistent interface to compare two files irrespective of the diff tool in use.

## EXAMPLES

### EXAMPLE 1
```
Invoke-ATDiffTool -LeftPath .\thisfile.txt -RightPath .\thatfile.txt -LeftTitle This -RightTitle That -Wait
```

Compare files displaying custom titles and wait for GUI process to exit.

## PARAMETERS

### -LeftPath
Path to 'left' file to compare

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RightPath
Path to 'right' file to compare

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -LeftTitle
Title to show for left file on tools that support this.
Defaults to the value of LeftPath

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 3
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RightTitle
Title to show for right file on tools that support this.
Defaults to the value of RightPath

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 4
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Wait
For tools that run as a GUI, wait for the process to exit before continuing.

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
-Wait parameter currently does not work when configured diff tool is VSCode,
as code starts a sub-process for the diff and the main process exits immediately.

## RELATED LINKS

[Set-ATConfiguratonItem]()

