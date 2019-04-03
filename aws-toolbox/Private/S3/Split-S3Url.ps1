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

    if (('https', 'http') -inotcontains $S3Url.Scheme -or -not $S3Url.Host.StartsWith('s3-'))
    {
        throw "$($S3Url): Not an S3 URL"
    }

    New-Object PSObject -Property @{
        BucketName = $S3Url.Segments[1].Trim('/')
        Key        = ($S3Url.Segments | Select-Object -Skip 2 ) -join [string]::Empty
    }
}