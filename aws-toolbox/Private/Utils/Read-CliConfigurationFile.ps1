Function Read-CliConfigurationFile
{
    param
    (
        [Parameter(Mandatory, ParameterSetName = 'config')]
        [switch]$Config,

        [Parameter(Mandatory, ParameterSetName = 'credentials')]
        [switch]$Credentials
    )

    function Read-SubSection
    {
        param
        (
            [System.IO.StreamReader]$StreamReader
        )

        $retval = @{}

        $line = [String]::Empty
        $finished = $false

        while (-not $finished -and $null -ne ($line = $StreamReader.ReadLine()))
        {
            switch -regex ($line)
            {
                "\s+(.+?)\s*=\s*(.*)"
                {
                    $name, $value = $matches[1..2]
                    $retval.Add($name, $value)
                }

                "^[^\s]"
                {
                    # End of indented section
                    $finished = $true
                }
            }
        }

        $retval
    }

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
        try
        {
            $sr = [System.IO.StreamReader]([System.IO.File]::OpenRead($FilePath))

            $line = [String]::Empty

            while ($null -ne ($line = $sr.ReadLine()))
            {
                switch -regex ($line)
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
                    '^(.+?)\s*=\s*$'
                    {
                        # Start of indented section
                        # Key
                        if (!($section))
                        {
                            $section = "No-Section"
                            $configuration[$section] = @{ }
                        }
                        $name = $matches.1
                        $configuration[$section][$name] = Read-SubSection -StreamReader $sr
                        break
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
        }
        finally
        {
            if ($sr)
            {
                $sr.Dispose()
            }
        }
    }

    else
    {
        Write-Warning "No AWS $($PSCmdlet.ParameterSetName) file found."
    }

    return $configuration
}