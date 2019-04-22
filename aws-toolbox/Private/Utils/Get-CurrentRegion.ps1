function Get-CurrentRegion
{
<#
    .SYNOPSIS
        Determine region from AWS default.

    .OUTPUTS
        [string] Region name.
#>
    if (Test-Path -Path variable:StoredAWSRegion)
    {
        $StoredAWSRegion
    }
    else
    {
        $fallbackRegion = [Amazon.Runtime.FallbackRegionFactory]::GetRegionEndpoint()

        if ($null -ne $fallbackRegion)
        {
            $fallbackRegion.SystemName
        }
        else
        {
            throw "Cannot determine AWS Region. Use Set-DefaultAWSRegion to set in shell."
        }
    }
}