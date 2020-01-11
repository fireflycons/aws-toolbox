Function Write-CliConfigurationFile
{
    Param
    (
        [Parameter(Mandatory, ParameterSetName = 'config')]
        [switch]$Config,

        [Parameter(Mandatory, ParameterSetName = 'credentials')]
        [switch]$Credentials,

        [ValidateNotNullOrEmpty()]
        [Parameter(ValueFromPipeline = $True, Mandatory = $True)]
        [Hashtable]$InputObject,

        [string]$AlternateDirectory
    )

    Begin
    {
        $Encoding = 'ASCII'
        $FilePath = $(
            if (-not [string]::IsNullOrEmpty($AlternateDirectory))
            {
                Join-Path $AlternateDirectory $PSCmdlet.ParameterSetName
            }
            else
            {
                if ((Get-OperatingSystem) -eq 'Windows')
                {
                    Join-Path $env:USERPROFILE ".aws\$($PSCmdlet.ParameterSetName)"
                }
                else
                {
                    "~/.aws/$($PSCmdlet.ParameterSetName)"
                }
            }
        )
    }

    Process
    {
        $outFile = New-Item -ItemType file -Path $Filepath -Force

        if (-not ($outFile))
        {
            Throw "Could not create File"
        }

        foreach ($i in $InputObject.keys)
        {
            if (-not ($($InputObject[$i].GetType().Name) -eq "Hashtable"))
            {
                #No Sections
                Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding $Encoding
            }
            else
            {
                #Sections
                Add-Content -Path $outFile -Value "[$i]" -Encoding $Encoding
                Foreach ($j in $($InputObject[$i].keys | Sort-Object))
                {
                    if ($j -match "^Comment[\d]+")
                    {
                        Add-Content -Path $outFile -Value "$($InputObject[$i][$j])" -Encoding $Encoding
                    }
                    else
                    {
                        Add-Content -Path $outFile -Value "$j=$($InputObject[$i][$j])" -Encoding $Encoding
                    }

                }
                Add-Content -Path $outFile -Value "" -Encoding $Encoding
            }
        }
    }

    End
    { }
}