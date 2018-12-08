# PSake makes variables declared here available in other scriptblocks
# Init some things
Properties {
    # Find the build folder based on build system
    $ProjectRoot = $ENV:BHProjectPath
    if (-not $ProjectRoot)
    {
        $ProjectRoot = $PSScriptRoot
    }
    $ProjectRoot = Convert-Path $ProjectRoot

    try
    {
        $script:IsWindows = (-not (Get-Variable -Name IsWindows -ErrorAction Ignore)) -or $IsWindows
        $script:IsLinux = (Get-Variable -Name IsLinux -ErrorAction Ignore) -and $IsLinux
        $script:IsMacOS = (Get-Variable -Name IsMacOS -ErrorAction Ignore) -and $IsMacOS
        $script:IsCoreCLR = $PSVersionTable.ContainsKey('PSEdition') -and $PSVersionTable.PSEdition -eq 'Core'
    }
    catch { }

    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
    $lines = '----------------------------------------------------------------------'

    $Verbose = @{}
    if ($ENV:BHCommitMessage -match "!verbose")
    {
        $Verbose = @{Verbose = $True}
    }

    $DefaultLocale = 'en-US'
    $DocsRootDir = "$PSScriptRoot\docs"
    $ModuleName = "aws-toolbox"
    $ModuleOutDir = "$PSScriptRoot\aws-toolbox"

}

Task Default -Depends BuildHelp

Task Init {
    $lines
    Set-Location $ProjectRoot
    "Build System Details:"
    Get-Item ENV:BH*
    "`n"

    if ($script:IsWindows)
    {
        "Checking for NuGet"
        $psgDir = Join-Path ${env:LOCALAPPDATA} "Microsoft\Windows\PowerShell\PowerShellGet"

        $nugetPath = $(

            $nuget = Get-Command nuget.exe -ErrorAction SilentlyContinue

            if ($nuget)
            {
                $nuget.Path
            }
            else
            {
                if (Test-Path -Path (Join-Path $psgDir 'nuget.exe'))
                {
                    Join-Path $psgDir 'nuget.exe'
                }
            }
        )

        if ($nugetPath)
        {
            "NuGet.exe found at '$nugetPath"
        }
        else
        {
            if (-not (Test-Path -Path $psgDir -PathType Container))
            {
                New-Item -Path $psgDir -ItemType Directory | Out-Null
            }

            "Installing NuGet to '$psgDir'"
            Invoke-WebRequest -Uri https://nuget.org/nuget.exe -OutFile (Join-Path $psgDir 'nuget.exe')
        }
    }
}

Task Test -Depends Init {
    $lines
    "`n`tSTATUS: Testing with PowerShell $PSVersion"

    # Gather test results. Store them in a variable and file
    $pesterParameters = @{
        Path         = "$ProjectRoot\Tests"
        PassThru     = $true
        OutputFormat = "NUnitXml"
        OutputFile   = "$ProjectRoot\$TestFile"
    }

    if (-Not $IsWindows) { $pesterParameters["ExcludeTag"] = "WindowsOnly" }
    $TestResults = Invoke-Pester @pesterParameters

    # In Appveyor?  Upload our tests! #Abstract this into a function?
    If ($ENV:BHBuildSystem -eq 'AppVeyor')
    {
        (New-Object 'System.Net.WebClient').UploadFile(
            "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)",
            "$ProjectRoot\$TestFile" )
    }

    Remove-Item "$ProjectRoot\$TestFile" -Force -ErrorAction SilentlyContinue

    # Failed tests?
    # Need to tell psake or it will proceed to the deployment. Danger!
    if ($TestResults.FailedCount -gt 0)
    {
        Write-Error "Failed '$($TestResults.FailedCount)' tests, build failed"
    }
    "`n"
}

Task Build -Depends Test {
    $lines

    # Load the module, read the exported functions, update the psd1 FunctionsToExport
    #Set-ModuleFunctions

    # Bump the module version if we didn't already
    Try
    {
        [version]$GalleryVersion = Get-NextNugetPackageVersion -Name $env:BHProjectName -ErrorAction Stop
        [version]$GithubVersion = Get-MetaData -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -ErrorAction Stop
        if ($GalleryVersion -ge $GithubVersion)
        {
            Update-Metadata -Path $env:BHPSModuleManifest -PropertyName ModuleVersion -Value $GalleryVersion -ErrorAction stop
        }
    }
    Catch
    {
        "Failed to update version for '$env:BHProjectName': $_.`nContinuing with existing version"
    }
}

function Test-IsTagPush
{
    # would be nice to detect tag by using GIT commands, but can't work out how.
    if ($ENV:BHBuildSystem -ieq 'AppVeyor' -and $ENV:APPVEYOR_REPO_TAG -ieq 'true')
    {
        return $true
    }

    return $false
}

Task Deploy -Depends Init {
    $lines

    try
    {
        # Is this commit a tag
        $isTagged = Test-IsTagPush

        # Gate Production deployment
        if (
            $ENV:BHBuildSystem -ne 'Unknown' -and
            $ENV:BHBranchName -eq "master" -and
            $isTagged
        )
        {
            if ($ENV:APPVEYOR_REPO_TAG_NAME)
            {
                "PSGallery deployment for tag: ${ENV:APPVEYOR_REPO_TAG_NAME}"
            }

            $Params = @{
                Path  = $ProjectRoot
                Force = $true
                Tags = @('Development', 'Production')
            }

            Invoke-PSDeploy @Verbose @Params
        }
        else
        {
            "Skipping PSGallery deployment: To deploy, ensure that...`n" +
            "`t* You are in a known build system (Current: $ENV:BHBuildSystem)`n" +
            "`t* You are committing a tag to the master branch (Branch: $ENV:BHBranchName, Is Tag: $isTagged) `n"
            " "

            # Only deploy AppVeyor artifact
            $Params = @{
                Path  = $ProjectRoot
                Force = $true
                Tags = 'Development'
            }

            Invoke-PSDeploy @Verbose @Params
        }
    }
    catch
    {
        $_.ScriptStackTrace
        throw
    }
}

Task BuildHelp -Depends Build, GenerateMarkdown {}

Task GenerateMarkdown -requiredVariables DefaultLocale, DocsRootDir {

    if ($ENV:BHBuildSystem -ine 'Unknown')
    {
        "Only updating help when building locally"
        return
    }

    if (!(Get-Module platyPS -ListAvailable))
    {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $moduleInfo = Import-Module $ENV:BHPSModuleManifest -Global -Force -PassThru

    try
    {
        if ($moduleInfo.ExportedCommands.Count -eq 0)
        {
            "No commands have been exported. Skipping $($psake.context.currentTaskName) task."
            return
        }

        if (!(Test-Path -LiteralPath $DocsRootDir))
        {
            New-Item $DocsRootDir -ItemType Directory > $null
        }
        else
        {
            # Force regeneration of all function documentation
            Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse |
            Where-Object {
                $_.Name -ine "${env:BHProjectName}.md"
            } |
            Remove-Item -Force
        }
<#
        if (Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse)
        {
            Get-ChildItem -LiteralPath $DocsRootDir -Directory | 
                ForEach-Object {
                Update-MarkdownHelp -Path $_.FullName -Verbose:$VerbosePreference > $null
            }
        }
#>
        # ErrorAction set to SilentlyContinue so this command will not overwrite an existing MD file.
        New-MarkdownHelp -Module $ModuleName -Locale $DefaultLocale -OutputFolder $DocsRootDir\$DefaultLocale `
            -WithModulePage -ErrorAction SilentlyContinue -Verbose:$VerbosePreference > $null
    }
    finally
    {
        Remove-Module $ModuleName
    }
}

Task GenerateHelpFiles -requiredVariables DocsRootDir, ModuleName, ModuleOutDir {
    if (!(Get-Module platyPS -ListAvailable))
    {
        "platyPS module is not installed. Skipping $($psake.context.currentTaskName) task."
        return
    }

    if (!(Get-ChildItem -LiteralPath $DocsRootDir -Filter *.md -Recurse -ErrorAction SilentlyContinue))
    {
        "No markdown help files to process. Skipping $($psake.context.currentTaskName) task."
        return
    }

    $helpLocales = (Get-ChildItem -Path $DocsRootDir -Directory).Name

    # Generate the module's primary MAML help file.
    foreach ($locale in $helpLocales)
    {
        New-ExternalHelp -Path $DocsRootDir\$locale -OutputPath $ModuleOutDir\$locale -Force `
            -ErrorAction SilentlyContinue -Verbose:$VerbosePreference > $null
    }
}