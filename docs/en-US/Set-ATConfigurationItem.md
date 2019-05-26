---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackProtectionPolicy.md
schema: 2.0.0
---

# Set-ATConfigurationItem

## SYNOPSIS
Set a module configuration item

## SYNTAX

```
Set-ATConfigurationItem [-ConfigurationItem] <String> [<CommonParameters>]
```

## DESCRIPTION
Sets a user-configurable configuration item
Currently you can only configure which application to use for file diffs.

DYNAMIC PARAMETERS

The cmdlet provides additional parameters in the context of the item being configured

## EXAMPLES

### EXAMPLE 1
```
Set-ATConfigurationItem -ConfigurationItem DiffTool -Git
```

Sets git diff as the file difference tool.
Git executable is searched for in the system path

### EXAMPLE 2
```
Set-ATConfigurationItem -ConfigurationItem DiffTool -Git
```

Sets git diff as the file difference tool.
Git executable is searched for in the system path

### EXAMPLE 3
```
Set-ATConfigurationItem -ConfigurationItem DiffTool -Git -Path /opt/git/bin/git
```

Sets git diff as the file difference tool, with executable located at specificed path.

### EXAMPLE 4
```
Set-ATConfigurationItem -ConfigurationItem DiffTool -WinMerge
```

Sets winmerge as the file difference tool.
Executable is searched for in known installation locations.
This option is unavailable on non-windows operating systems

## PARAMETERS

### -ConfigurationItem
The item to configure

DYNAMIC PARAMETERS

With -ConfigurationItem DiffTool, the following parameters becode active
* -Git       Use git for diffs
* -WinMerge  Use winmerge for diffs (Windows only)
* -VSCode    Use Visual Studio Code for diffs
* -Path      Available with the above 3 switches: Specify path to executable

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable.
For more information, see about_CommonParameters (http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES
Supported diff tools are
- git (all platforms) -Git
- Winmerge (Windows only) -Winmerge
- Visual Studio Code (all platforms) -VSCode

Winmerge is generally preferable as it can set specific titles for the files being compared as opposed to just the file paths.
This is especially useful when running Compare-ATDeployedStackWithSourceTemplate as the stack version is titled with the
stack name rather than the temporary file path where the stack version has been downloaded to.

If you have a diff tool you would like added, raise an issue in github.

## RELATED LINKS
