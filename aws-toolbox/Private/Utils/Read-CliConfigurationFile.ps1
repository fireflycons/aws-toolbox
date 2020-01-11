Function Read-CliConfigurationFile
{
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'config')]
        [switch]$Config,

        [Parameter(Mandatory, ParameterSetName = 'credentials')]
        [switch]$Credentials
    )

    $FilePath = $(

        if ($Config -and $null -ne $env:AWS_CONFIG_FILE)
        {
            $env:AWS_CONFIG_FILE
        }
        elseif ($Credentials -and $null -ne $env:AWS_SHARED_CREDENTIALS_FILE)
        {
            $env:AWS_SHARED_CREDENTIALS_FILE
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