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

        $FilePath = (Get-CliConfiguration -ConfigurationFileName $PSCmdlet.ParameterSetName).FilePath
    }

    Process
    {
        $outFile = New-Item -ItemType file -Path $Filepath -Force

        if (-not ($outFile))
        {
            Throw "Could not create file: $outFile"
        }

        foreach ($i in $InputObject.keys)
        {
            if (-not ($($InputObject[$i] -is [System.Collections.IDictionary])))
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
    { }
}