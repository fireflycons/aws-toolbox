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
        [Hashtable]$InputObject
    )

    Begin
    {
        function Add-HashContent
        {
            param
            (
                [string]$FilePath,
                [System.Collections.IDictionary]$Hash,
                [int]$Indent = 0
            )

            $pad = " " * $Indent

            Foreach ($j in $($Hash.keys | Sort-Object))
            {
                $value = $Hash[$j]

                if ($j -match "^Comment[\d]+")
                {
                    Add-Content -Path $FilePath -Value "$($pad)$($value)" -Encoding ascii
                }
                elseif ($value -is [System.Collections.IDictionary])
                {
                    Add-Content -Path $FilePath -Value "$($pad)$j =" -Encoding ascii
                    Add-HashContent -Hash $value -Indent ($Indent + 2) -FilePath $FilePath
                }
                else
                {
                    Add-Content -Path $FilePath -Value "$($pad)$j = $value" -Encoding ascii
                }
            }
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
                Add-Content -Path $outFile -Value "$i=$($InputObject[$i])" -Encoding ascii
            }
            else
            {
                #Sections
                Add-Content -Path $outFile -Value "[$i]" -Encoding ascii
                Add-HashContent -Hash $InputObject[$i] -FilePath $outFile
                Add-Content -Path $outFile -Value "" -Encoding ascii
            }
        }
    }

    End
    { 
        $x = 1
    }
}