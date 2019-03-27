function Get-ContentFromS3
{
<#
    .SYNOPSIS
        Get raw text content from a file in S3

    .PARAMETER BucketName
        Bucket name

    .PARAMETER Key
        Key identifying file

    .PARAMETER ExpectContent
        If true, wait longer for key to be present

#>
    param
    (
        [Parameter(ParameterSetName = 'ByName')]
        [string]$BucketName,

        [Parameter(ParameterSetName = 'ByName')]
        [string]$Key,

        [Parameter(ParameterSetName = 'ByUri')]
        [Uri]$S3Url,

        [bool]$ExpectContent = $true
    )

    $tempfile = [IO.Path]::GetTempFileName()
    $lastSize = 0
    $thisSize = 0

    if ($PSCmdLet.ParameterSetName -eq 'ByUri')
    {
        $s3 = $S3Url | Split-S3Url
        $BucketName = $s3.BucketName
        $Key = $s3.Key
    }

    # There is sometimes a delay in the results being fully streamed
    for ($i = 0; $i -lt 30; ++$i)
    {
        $obj = Get-S3Object -BucketName $BucketName -Key $key

        if ($obj)
        {
            $thisSize = $obj.Size
        }

        if (($lastSize -gt 0 -and $thisSize -eq $lastSize) -or ($thisSize -eq 0 -and $i -gt 3 -and -not $ExpectContent))
        {
            break
        }

        $lastSize = $thisSize
        Start-Sleep -Seconds 5
    }

    try
    {
        Read-S3Object -BucketName $BucketName -Key $Key -File $tempfile | Out-Null
        $text = Get-Content -Raw $tempfile
        return $text
    }
    catch
    {
        return [string]::Empty
    }
    finally
    {
        if (Test-Path -Path $tempFile -PathType Leaf)
        {
            Remove-Item $tempfile
        }
    }
}

