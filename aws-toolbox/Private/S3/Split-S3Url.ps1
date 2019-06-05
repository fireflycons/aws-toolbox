function Split-S3Url
{
    <#
    .SYNOPSIS
        Splits an S3 URL into bucket and key

    .DESCRIPTION
        Given an S3 URL of the form https://s3-region.amazonaws.com/bucket/key
        returns the bucket name and key

    .PARAMETER S3Url
        URL to split

    .OUTPUTS
        [PSObject] with fields
        - BucketName
        - Key
#>
    param
    (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
        [Uri]$S3Url
    )

    $url = $S3Url.ToString()

    # Weird behaviour. PowerShell -match does not match these regexes
    $virtualDomainRx = New-Object System.Text.RegularExpressions.Regex '^https://(?<bucket>.*?)\.s3([\.\-](?<region>[a-z]{2}-[a-z\-]+-\d))?\.amazonaws\.com/(?<key>.*)$'
    $pathStyleRx = New-Object System.Text.RegularExpressions.Regex '^https://s3([\.\-](?<region>[a-z]{2}-[a-z\-]+-\d))?\.amazonaws\.com/(?<bucket>.*?)/(?<key>.*)$'

    $m = $virtualDomainRx.Match($url)
    if ($m.Success)
    {
        return         New-Object PSObject -Property @{
            BucketName = $m.Groups["bucket"].Value
            Key        = $m.Groups["key"].Value
        }
    }

    $m = $pathStyleRx.Match($url)

    if ($m.Success)
    {
        return         New-Object PSObject -Property @{
            BucketName = $m.Groups["bucket"].Value
            Key        = $m.Groups["key"].Value
        }
    }

    throw "$($S3Url): Not an S3 URL"
}