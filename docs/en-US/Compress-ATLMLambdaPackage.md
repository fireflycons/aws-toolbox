---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: http://winmerge.org/
schema: 2.0.0
---

# Compress-ATLMLambdaPackage

## SYNOPSIS
Packages lambda function code to a zip file

## SYNTAX

```
Compress-ATLMLambdaPackage [-ZipFile] <String> [-Path] <String> [-PassThru] [<CommonParameters>]
```

## DESCRIPTION
Creates a zip file containing a lambda function payload that can be uploaded using the varoius mechanisms for updating function code.
Unix attributes of rwxrwxrwx are set on all files packaged.

## EXAMPLES

### EXAMPLE 1
```
Compress-ATLMLambdaPackage -ZipFile lambda.zip -Path src\my-lambda.py
```

Creates lambda.zip in the current directory and packages the file \`lambda.py\` from directory .\src in the root directory of the archive

### EXAMPLE 2
```
Compress-ATLMLambdaPackage -ZipFile lambda.zip -Path src
```

Where src is a directory, the entire contents of the directory are packaged to lambda.zip

### EXAMPLE 3
```
Update-LMFunctionCode -FunctionName my-func -ZipFile (Compress-ATLMLambdaPackage -ZipFile lambda.zip -Path src -PassThru)
```

Passes the zipped function code directly to Update-LMFunctionCode

## PARAMETERS

### -ZipFile
Path to zip file to create

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

### -Path
If this references a single file, it will be zipped.
If this references a path, then the entire folder structure beneath the path will be zipped.

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

### -PassThru
If set, the path passed to -ZipFile is returned

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

## RELATED LINKS
