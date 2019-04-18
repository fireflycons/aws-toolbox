# Generic module deployment.
# This stuff should be moved to psake for a cleaner deployment view

# ASSUMPTIONS:

# folder structure of:
# - RepoFolder
#   - This PSDeploy file
#   - ModuleName
#     - ModuleName.psd1

# Nuget key in $ENV:NuGetApiKey

# Set-BuildEnvironment from BuildHelpers module has populated ENV:BHProjectName

# find a folder that has psd1 of same name...

if ($ENV:BHProjectName -and $ENV:BHProjectName.Count -eq 1)
{
    Deploy Module {
        By PSGalleryModule {
            FromSource $ENV:BHProjectName
            To PSGallery
            Tagged Production
            WithOptions @{
                ApiKey = $ENV:NuGetApiKey
            }
        }
    }

    if (
        $env:BHProjectName -and $ENV:BHProjectName.Count -eq 1 -and
        $env:BHBuildSystem -eq 'AppVeyor'
    )
    {
        Deploy DeveloperBuild {
            By AppVeyorModule {
                FromSource $ENV:BHProjectName
                To AppVeyor
                Tagged Development
                WithOptions @{
                    Version = $env:APPVEYOR_BUILD_VERSION
                }
            }
        }
    }
}