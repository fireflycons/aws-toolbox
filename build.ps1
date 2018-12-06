param
(
    $Task = 'Default'
)

$currentLocation = Get-Location
try
{
    Set-Location $PSScriptRoot

    # Grab nuget bits, install modules, set build variables, start build.
    Write-Host 'Setting up build environment'
    Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

    $loadedModules = Get-Module | Select-Object -ExpandProperty Name
    $requiredModules = @(
        'Psake'
        'PSDeploy'
        'BuildHelpers'
        'platyPS'
        'Pester'
    )

    # List of modules not already loaded
    $missingModules = Compare-Object -ReferenceObject $requiredModules -DifferenceObject $loadedModules |
    Where-Object {
        $_.SideIndicator -eq '<='
    } |
    Select-Object -ExpandProperty InputObject

    if ($missingModules)
    {
        $installedModules = Get-Module -ListAvailable

        $neededModules = $requiredModules |
            Where-Object {
            -not $installedModules.Name -icontains $_
        } |
            Select-Object -ExpandProperty Name

        if (($neededModules | Measure-Object).Count -gt 0)
        {
            Install-Module $neededModules -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser
        }

        Import-Module $missingModules
    }

    Set-BuildEnvironment -ErrorAction SilentlyContinue

    if (${env:BHBuildSystem} -ine 'Unknown')
    {
        # Seems AppVeyor's version of this is quite out of date
        Install-Module AWSPowerShell -Force -AllowClobber -SkipPublisherCheck -Scope CurrentUser
    }

    Invoke-psake -buildFile "$PSScriptRoot\psake.ps1" -taskList $Task -nologo
    exit ( [int]( -not $psake.build_success ) )
}
catch
{
    Write-Error $_.Exception.Message

    # Make AppVeyor fail the build if this setup borks
    exit 1
}
finally
{
    Set-Location $currentLocation
}