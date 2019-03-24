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
    $defaultRegionsMap = @{
        CN  = 'cn-north-1'
        EU  = 'eu-west-1'
        GOV = 'us-gov-west-1'
        SFO = 'us-west-1'
        US  = 'us-east-1'

    }

    $bucketName = "aws-toolbox-workspace-$(Get-CurrentRegion)-$((Get-STSCallerIdentity).Account)"

    try
    {
        $location = Get-S3BucketLocation -BucketName $bucketName | Select-Object -ExpandProperty Value

        if ($defaultRegionsMap.ContainsKey($location))
        {
            $location = $defaultRegionsMap[$location]
        }

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
        $location = Get-S3BucketLocation -BucketName $bucketName | Select-Object -ExpandProperty Value

        if ($defaultRegionsMap.ContainsKey($location))
        {
            $location = $defaultRegionsMap[$location]
        }

        return New-Object psobject -Property @{
            BucketName = $bucketName
            BucketUrl  = [uri]"https://s3.$($location).amazonaws.com/$bucketName"
        }
    }

    throw "Unable to create S3 bucket $bucketName"
}