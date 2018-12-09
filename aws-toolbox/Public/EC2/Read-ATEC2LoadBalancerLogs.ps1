function Read-ATEC2LoadBalancerLogs
{
    <#
    .NOTES
        IAM permissions required to run this command
        - sts:getCallerIdentity  (when -AccountId is not specified)
        - ec2:DescribeLoadBalancers  (when -LoadBalancer is a name)
        - ec2:DescribeLoadBalancerAttributes
        - s3:GetBucketLocation
        - s3:GetObject
        - s3:ReadObject
#>    
    param
    (
        [object]$LoadBalancer,

        [string]$AccountId,

        [Parameter(ParameterSetName = 'Range')]
        [DateTime]$StartTime,

        [Parameter(ParameterSetName = 'Range')]
        [DateTime]$EndTime,

        [Parameter(ParameterSetName = 'LastX')]
        [int]$Last,

        [System.Int64]$LimitSize = 500MB
    )

    if ([string]::IsNullOrEmpty($AccountId))
    {
        $AccountId = Get-STSCallerIdentity | Select-Object -ExpandProperty Account
    }

    if ($LoadBalancer -is [string])
    {
        try
        {
            $lb = Get-ELBLoadBalancer -LoadBalancerName $LoadBalancer
        }
        catch
        {
            $lb = $null
        }

        if (-not $lb)
        {
            $lbArg = $(
                if ($LoadBalancer -like 'arn:*')
                {
                    @{
                        LoadBalancerArn = $LoadBalancer
                    }
                }
                else
                {
                    @{
                        Name = $LoadBalancer
                    }
                }
            )
            try
            {
                $lb = Get-ELB2LoadBalancer @lbArg
            }
            catch
            {
                $lb = $null
            }
        }

        if (-not $lb)
        {
            throw "Cannot find ALB or Classic ELB with name $LoadBalancer"
        }

        $LoadBalancer = $lb
    }

    if ($LoadBalancer -is [Amazon.ElasticLoadBalancing.Model.LoadBalancerDescription] -or $LoadBalancer.ToString() -eq 'Test.LoadBalancerDescription')
    {
        # Classic
        $attributes = Get-ELBLoadBalancerAttribute -LoadBalancerName $LoadBalancer.LoadBalancerName
        $bucket = $attributes.AccessLog.S3BucketName
        $prefix = $attributes.AccessLog.S3BucketPrefix
        $loadBalancerId = $LoadBalancer.LoadBalancerName
        $columns = @(
            'timestamp'
            'elb'
            'client'
            'backend'
            'request_processing_time'
            'backend_processing_time'
            'response_processing_time'
            'elb_status_code'
            'backend_status_code'
            'received_bytes'
            'sent_bytes'
            'request'
            'user_agent'
            'ssl_cipher'
            'ssl_protocol'
        )

        if ([string]::IsNullOrEmpty($bucket))
        {
            Write-Host -ForegroundColor Yellow "Logging not configured for this load balancer"
            return
        }
    }
    elseif ($LoadBalancer -is [Amazon.ElasticLoadBalancingV2.Model.LoadBalancer])
    {
        # ALB
        $attributes = Get-ELB2LoadBalancerAttribute -LoadBalancerArn $LoadBalancer.LoadBalancerArn

        $bucket = $attributes | Where-Object { $_.Key -eq 'access_logs.s3.bucket' } | Select-Object -ExpandProperty Value
        $prefix = $attributes | Where-Object { $_.Key -eq 'access_logs.s3.prefix' } | Select-Object -ExpandProperty Value
        $loadBalancerId = $LoadBalancer.Name

        $columns = @(
            'type'
            'timestamp'
            'elb'
            'client'
            'target'
            'request_processing_time'
            'target_processing_time'
            'response_processing_time'
            'elb_status_code'
            'target_status_code'
            'received_bytes'
            'sent_bytes'
            'request'
            'user_agent'
            'ssl_cipher'
            'ssl_protocol'
            'target_group_arn'
            'trace_id'
            'domain_name'
            'chosen_cert_arn'
            'matched_rule_priority'
            'request_creation_time'
            'actions_executed'
            'redirect_url'
            'error_reason'
        )

        if (-not $bucket)
        {
            Write-Host -ForegroundColor Yellow "Logging not configured for this load balancer"
            return
        }
    }
    else 
    {
        throw "Input object $($LoadBalancer.GetType().FullName) does not decribe a load balancer"    
    }

    $logObjects = $(

        switch ($PSCmdlet.ParameterSetName)
        {
            'LastX'
            {
                Get-LoadBalancerAccessLogs -LoadBalancerId $loadBalancerId -AccountId $AccountId -BucketName $bucket -KeyPrefix $prefix -Last $Last
            }

            'Range'
            {
                Get-LoadBalancerAccessLogs -LoadBalancerId $loadBalancerId -AccountId $AccountId -BucketName $bucket -KeyPrefix $prefix -StartTime $StartTime -EndTime $EndTime
            }
        }
    )

    # Before downloading, see how much would be downloaded
    $downloadSize = $logObjects.Size | Measure-Object -Sum | Select-Object -ExpandProperty Sum

    if ($downloadSize -gt $LimitSize)
    {
        $fs = [System.Globalization.CultureInfo]::CurrentCulture.NumberFormat
        throw "$($downloadSize.ToString('##,#', $fs)) bytes would be downloaded from S3, which exceeds limit of $($LimitSize.ToString('##,#', $fs))"
    }

    [Int64]$bytesDownloaded = 0

    $logObjects |
        ForEach-Object {

        try 
        {
            $localFile = Join-Path $env:TEMP (Split-Path -Leaf $_.Key)

            Read-S3Object -BucketName $_.BucketName -Key $_.Key -File $localFile
            $bytesDownloaded += $_.Size

            if ([System.IO.Path]::GetExtension($_.Key) -ieq '.gz')
            {
                # uncompress - delete compressed, set $localfile to uncompressed path
                $uncompressed = [System.IO.Path]::GetFileNameWithoutExtension($_.Key)

                try
                {
                    $originalFileStream = [System.IO.File]::OpenRead($localFile)
                    $decompressedFileStream = [System.IO.File]::Create($uncompressed)
                    $decompressionStream = New-Object System.IO.Compression.GZipStream -ArgumentList ($originalFileStream, 'Decompress')

                    $decompressionStream.CopyTo($decompressedFileStream)
                }
                finally
                {

                    ($originalFileStream, $decompressedFileStream, $decompressionStream) |
                        Foreach-Object {
                        $_.Dispose()
                    }
                }

                Remove-Item $localFile
                $localFile = $uncompressed
            }

            Import-Csv -Header $columns -Delimiter ' ' -Path $localFile |
                ForEach-Object {
                $_ | Add-Member -PassThru -MemberType NoteProperty -Name TimeStampDateTime -Value ([datetime]::Parse($_.timestamp))
            }
        }
        finally
        {
            if (Test-Path -Path $localFile)
            {
                Remove-Item $localFile
            }
        }
    } |
    Sort-Object -Descending TimeStampDateTime #|
    #Select-Object -Property ('TimeStampDateTime' + $columns)
}
