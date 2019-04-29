function Write-WorkspaceBucketTagging
{
<#
    .SYNOPSIS
        Write workspace bucket tags if not present

    .PARAMETER BucketName
        Bucket to tag
#>
    param
    (
        [string]$BucketName
    )

    if ((Get-S3BucketTagging -BucketName $BucketName | Measure-Object).Count -eq 0)
    {
        try
        {
            $module = (Get-Command (Get-PSCallStack | Select-Object -First 1).Command).Module
            Write-S3BucketTagging -BucketName $BucketName -TagSet @(
                @{
                    Key   = 'CreatedBy'
                    Value = $module.Name
                }
                @{
                    Key   = 'ProjectURL'
                    Value = $module.ProjectUri.ToString()
                }
                @{
                    Key   = 'Purpose'
                    Value = 'Workspace bucket for SSM Command output'
                }
            )
        }
        catch
        {
            Write-Warning "Unable to tag S3 bucket $($bucketName): $($_.Exception.Message)"
        }
    }
}