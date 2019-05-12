function Compress-ATLMLambdaPackage
{
    <#
    .SYNOPSIS
        Packages lambda function code to a zip file

    .DESCRIPTION
        Creates a zip file containing a lambda function payload that can be uploaded using the varoius mechanisms for updating function code.
        Unix attributes of rwxrwxrwx are set on all files packaged.

    .PARAMETER ZipFile
        Path to zip file to create

    .PARAMETER Path
        If this references a single file, it will be zipped.
        If this references a path, then the entire folder structure beneath the path will be zipped.

    .PARAMETER PassThru
        If set, the path passed to -ZipFile is returned

    .EXAMPLE
        Compress-ATLMLambdaPackage -ZipFile lambda.zip -Path src\my-lambda.py

        Creates lambda.zip in the current directory and packages the file `lambda.py` from directory .\src in the root directory of the archive

    .EXAMPLE
        Compress-ATLMLambdaPackage -ZipFile lambda.zip -Path src

        Where src is a directory, the entire contents of the directory are packaged to lambda.zip

    .EXAMPLE
        Update-LMFunctionCode -FunctionName my-func -ZipFile (Compress-ATLMLambdaPackage -ZipFile lambda.zip -Path src -PassThru)

        Passes the zipped function code directly to Update-LMFunctionCode

#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ZipFile,

        [Parameter(Mandatory=$true, Position=1)]
        [string]$Path,

        [switch]$PassThru
    )

    $isFolder = $false

    # Work out what to include in the zip file from the -Path argument
    $filesToZip = $(
        if (Test-Path -Path $Path -PathType Leaf)
        {
            Get-Item -Path $Path
        }
        elseif (Test-Path -Path $Path -PathType Container)
        {
            Get-ChildItem -Path $Path -Recurse
            $isFolder = $true
        }
        else
        {
            throw "Path not found: $Path"
        }
    )

    if (Test-Path -Path $ZipFile -PathType Leaf)
    {
        # Remove any pre-existing zip file
        Write-Verbose "Deleting existing package: $Zipfile"
        Remove-Item $ZipFile -Force
    }

    # Account for powershell and OS current directory not being the same
    # as .NET objects like ZipFile will use OS path
    if (-not [IO.Path]::IsPathRooted($ZipFile))
    {
        $osZipPath = Join-Path (Get-Location).Path $ZipFile
    }

    try
    {
        Write-Verbose "Creating: $ZipFile"

        # Create the zip file
        $archive = [IO.Compression.ZipFile]::Open($osZipPath, [IO.Compression.ZipArchiveMode]::Create)

        # Go to location where we are zipping for easier path resolution when creating zip directory entries
        if ($isFolder)
        {
            # Change to directory we are zipping
            Push-Location $Path
        }
        else
        {
            # Change to directory containg the file we are zipping
            Push-Location (Split-Path -Parent (Resolve-Path $Path).Path)
        }

        # Add files to zip
        $filesToZip |
        Foreach-Object {
            $entryName = Resolve-Path -Relative $_.FullName

            if (Test-Path -Path $entryName -PathType Leaf)
            {
                # Create zip directroy entry name
                $entryName = $entryName.Substring(2).Replace('\', '/')

                try
                {
                    # Create zip directroy entry
                    $entry = $archive.CreateEntry($entryName)
                    $entry.LastWriteTime = [System.DateTimeOffset]::Now

                    # Set unix attributes: rwxrwxrwx
                    $entry.ExternalAttributes = 0x1ff -shl 16

                    # Add file
                    $fs = [IO.File]::OpenRead($_.FullName)
                    $es = $entry.Open()
                    $fs.CopyTo($es)
                    $es.Flush()
                    Write-Verbose "Added: $($entryName)"
                }
                finally
                {
                    # Close zip entry and file read into it
                    ($es, $fs) |
                    Where-Object {
                        $null -ne $_
                    } |
                    ForEach-Object {
                        $_.Dispose()
                    }
                }
            }
        }
    }
    finally
    {
        if ($null -ne $archive)
        {
            # Close zip file
            $archive.Dispose()
        }

        # Restore working directory
        Pop-Location
    }

    if ($PassThru)
    {
        # Return path to zip file
        $ZipFile
    }
}