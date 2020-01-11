Function Read-CliConfigurationFile
{
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'config')]
        [switch]$Config,

        [Parameter(Mandatory, ParameterSetName = 'credentials')]
        [switch]$Credentials,

        [string]$AlternateDirectory
    )

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

    $configuration = @{ }

    if (Test-Path -Path $FilePath)
    {
        switch -regex -file $FilePath
        {
            "^\[(.+)\]$"
            {
                # Section
                $section = $matches[1]
                $configuration[$section] = @{ }
                $CommentCount = 0
            }
            "^(;.*)$"
            {
                # Comment
                if (!($section))
                {
                    $section = "No-Section"
                    $configuration[$section] = @{ }
                }
                $value = $matches[1]
                $CommentCount = $CommentCount + 1
                $name = "Comment" + $CommentCount
                $configuration[$section][$name] = $value
            }
            "(.+?)\s*=\s*(.*)"
            {
                # Key
                if (!($section))
                {
                    $section = "No-Section"
                    $configuration[$section] = @{ }
                }
                $name, $value = $matches[1..2]
                $configuration[$section][$name] = $value
            }
        }
    }
    else
    {
        Write-Warning "No AWS $($PSCmdlet.ParameterSetName) file found."
    }

    return $configuration
}