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

    if (-not (Get-Module -ListAvailable PSDepend))
    {
        Install-Module PSDepend -Repository PSGallery -Scope CurrentUser -Force
    }

    Import-Module PSDepend

    $psDependTags = $(
        if (Test-Path -Path variable:PSEdition)
        {
            $PSEdition
        }
        else
        {
            'Desktop'
        }
    )

    Invoke-PSDepend -Path "$PSScriptRoot\build.requirements.psd1" -Install -Import -Force -Tags $psDependTags

    Set-BuildEnvironment -ErrorAction SilentlyContinue

    Invoke-psake -buildFile (Join-Path $PSScriptRoot psake.ps1) -taskList $Task -nologo
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