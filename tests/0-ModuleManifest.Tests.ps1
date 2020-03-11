$ModuleName = 'aws-toolbox'

# http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-manifest-file.html
# Make sure one or multiple versions of the module are not loaded
Get-Module -Name $ModuleName | Remove-Module

# Find the Manifest file
$ManifestFile = Get-ChildItem -Path (Split-path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)) -Recurse -Filter "$ModuleName.psd1" | Select-Object -ExpandProperty FullName

if (($ManifestFile | Measure-Object).Count -ne 1)
{
    throw "Cannot locate $ModuleName.psd1"
}

# Import the module and store the information about the module
$ModuleInformation = Import-Module -Name $manifestFile -PassThru

Describe "$ModuleName Module - Testing Manifest File (.psd1)" {
    Context 'Manifest' {
        It 'Should contain RootModule' {
            $ModuleInformation.RootModule | Should not BeNullOrEmpty
        }
        It 'Should contain Author' {
            $ModuleInformation.Author | Should not BeNullOrEmpty
        }
        It 'Should contain Company Name' {
            $ModuleInformation.CompanyName | Should not BeNullOrEmpty
        }
        It 'Should contain Description' {
            $ModuleInformation.Description | Should not BeNullOrEmpty
        }
        It 'Should contain Copyright' {
            $ModuleInformation.Copyright | Should not BeNullOrEmpty
        }
        It 'Should contain License' {
            $ModuleInformation.LicenseURI | Should not BeNullOrEmpty
        }
        It 'Should contain a Project Link' {
            $ModuleInformation.ProjectURI | Should not BeNullOrEmpty
        }
        It 'Should contain Tags (For the PSGallery)' {
            $ModuleInformation.Tags.count | Should not BeNullOrEmpty
        }
        It 'Should have no whitespace in tag values' {
            $ModuleInformation.Tags |
            ForEach-Object {
                $_ | Should Not Match '\s'
            }
        }
        It "Should have matching dependencies in RequiredModules and PrivateData.PSData['ExternalModuleDependencies']" {

            Compare-Object -ReferenceObject $ModuleInformation.RequiredModules -DifferenceObject $ModuleInformation.PrivateData.PSData['ExternalModuleDependencies'] | SHould -BeNullOrEmpty
        }
    }

    Context 'Required dependencies are listed' {
        Write-Host -ForegroundColor Green '    Scanning module files...'

        # All verbs
        $verbs = Get-Verb | Select-Object -ExpandProperty Verb

        # AWS service info
        $services = Get-AWSService |
        Where-Object {
            # Confusion between AS and ASA prefixes
            ('AWS.Tools.AWSSupport') -inotcontains $_.ModuleName
        }

        # Service cmdlet noun prefixes
        $nounPrefixes = $services |
        Select-Object -ExpandProperty CmdletNounPrefix |
        Sort-Object -Property @{Expression = {$_.Length}; Descending = $true}

        # Build regex to search for AWS cmldet calls within the module
        $regex = New-Object System.Text.RegularExpressions.Regex -ArgumentList "($($verbs -join '|'))-(?<prefix>$($nounPrefixes -join '|'))[A-Za-z\d]+"

        # Gather module content
        $moduleScripts = Get-ChildItem -Path ([IO.Path]::Combine($PSScriptRoot, '..', 'aws-toolbox')) -Filter *.ps1 -Recurse

        # Detect all usages of AWS cmdlets by unique noun prefix
        $detectedNounPrefixes = $moduleScripts |
        ForEach-Object {
            $_ | Get-Content |
            ForEach-Object {
                $mc = $regex.Matches($_)

                if ($mc.Success)
                {
                    $mc |
                    Foreach-Object {
                        $_.Groups['prefix'].Value
                    }
                }
            }
        } |
        Sort-Object -Unique

        # Check module for each prefix is listed as a dependency
        $detectedNounPrefixes |
        Foreach-Object {

            $prefix = $_
            $dependency = $services |
            Where-Object {
                $_.CmdletNounPrefix -eq $prefix
            }

            It "Should import $($dependency.ModuleName)" {

                $ModuleInformation.RequiredModules.Name | Should -Contain $dependency.ModuleName
            }
        }
    }
}
