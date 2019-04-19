<#
    .SYNOPSIS
        Get S3 objects for load balancer logs in given time range

    .PARAMETER LoadBalancerId
        Classic - Load balancer name
        ALB - Resource ID

    .PARAMETER AccountId
        The AWS account ID of the owner.

    .PARAMETER BucketName
        The name of the S3 bucket.

    .PARAMETER KeyPrefix
        The prefix (logical hierarchy) in the bucket. If you don't specify a prefix, the logs are assumed to be at the root level of the bucket.

    .PARAMETER StartTime
        Log batches older than this are excluded

    .PARAMETER EndTime
        Log batches newer than this are excluded

    .PARAMETER Last
        Get log batches for last X minutes

    .NOTES
        s3:GetBucketLocation
        s3:GetObject

#>
function Get-LoadBalancerAccessLogs
{
    param
    (
        [Parameter(Mandatory = $true)]
        [string]$LoadBalancerId,

        [Parameter(Mandatory = $true)]
        [string]$AccountId,

        [Parameter(Mandatory = $true)]
        [string]$BucketName,

        [string]$KeyPrefix,

        [Parameter(ParameterSetName = 'Range')]
        [DateTime]$StartTime,

        [Parameter(ParameterSetName = 'Range')]
        [DateTime]$EndTime,

        [Parameter(ParameterSetName = 'LastX')]
        [int]$Last
    )


    if ($PSCmdlet.ParameterSetName -ieq 'LastX')
    {
        $EndTime = [datetime]::UtcNow
        $StartTime = $EndTime - [timespan]::FromMinutes($Last)
    }

    $region = Get-BucketLocation -BucketName $Bucket

    if (-not [string]::IsNullOrEmpty($KeyPrefix))
    {
        $KeyPrefix = $KeyPrefix.Trim('/') + "/AWSLogs"
    }
    else
    {
        $KeyPrefix = "AWSLogs"
    }

    $LoadBalancerId = $LoadBalancerId.Replace('/', '.')
    $startPrefix = "$KeyPrefix/$AccountId/elasticloadbalancing/$region/$($StartTime.ToString('yyyy/MM/dd'))/$($AccountId)_elasticloadbalancing_$($region)_$($LoadBalancerId)"
    $endPrefix = "$KeyPrefix/$AccountId/elasticloadbalancing/$region/$($EndTime.ToString('yyyy/MM/dd'))/$($AccountId)_elasticloadbalancing_$($region)_$($LoadBalancerId)"

    ($startPrefix, $endPrefix) |
        Sort-Object -Unique |
        ForEach-Object {
        Get-S3Object -BucketName $BucketName -KeyPrefix $_ |
            Foreach-Object {

            if ($_.Key -match '(?<year>\d{4})(?<month>\d{2})(?<day>\d{2})T(?<hour>\d{2})(?<minute>\d{2})Z_(?<ip>\d+\.\d+\.\d+\.\d+)')
            {
                $_ | Add-Member -PassThru -MemberType NoteProperty -Name EndTime -Value (New-Object DateTime -ArgumentList ($Matches.year, $Matches.month, $Matches.day, $Matches.Hour, $Matches.minute, 0, 0, 'Utc')) |
                    Add-Member -PassThru -MemberType NoteProperty -Name NodeIp -Value ([System.Net.IPAddress]::Parse($Matches.ip).IPAddressToString)
            }
        }
    }  |
        Where-Object {
        $_.EndTime -le $EndTime -and $_.EndTime -ge $StartTime
    }
}