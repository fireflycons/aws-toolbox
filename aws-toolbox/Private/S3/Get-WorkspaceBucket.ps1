function Get-WorkspaceBucket
{
    <#
    .SYNOPSIS
        Gets, creating if necessary, a bucket for use by tools in this module

    .OUTPUTS
        [PSObject] with the following fields
        - BucketName
        - BucketUrl
#>
    $bucketName = "aws-toolbox-workspace-$(Get-CurrentRegion)-$((Get-STSCallerIdentity).Account)"

    try
    {
        $location = Get-BucketLocation -BucketName $bucketName

        return New-Object psobject -Property @{
            BucketName = $bucketName
            BucketUrl  = [uri]"https://s3.$($location).amazonaws.com/$bucketName"
        }
    }
    catch
    {
        # Bucket not found
    }

    # Try to create it
    $response = New-S3Bucket -BucketName $bucketName

    if ($response)
    {
        $location = Get-BucketLocation -BucketName $bucketName

        return New-Object psobject -Property @{
            BucketName = $bucketName
            BucketUrl  = [uri]"https://s3.$($location).amazonaws.com/$bucketName"
        }
    }

    throw "Unable to create S3 bucket $bucketName"
}