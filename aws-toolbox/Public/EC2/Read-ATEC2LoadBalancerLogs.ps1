function Read-ATEC2LoadBalancerLogs
{
    <#
    .SYNOPSIS
        Read Load Balancer logs into a list of PowerShell custom objects

    .DESCRIPTION
        Read load balancer logs into a list of PowerShell custom objects and emits this as the result of the script.
        The various fields of the flow log are parsed out and can be accessed as properties of the returned
        object simplifying sorting and searching of the log events.

        You can pipe the output to Out-GridView to view quickly or Export-Csv for further analysis in Excel.

        Logs can be very large especially on high traffic sites so you should keep time constraints small.
        If you need to analyse logs over a large period, you'll be better off doing it with Athena.

    .PARAMETER LoadBalancer
        Nome of load balancer, or object returned by Get-ELBLoadBalancer or Get-ELB2LoadBalancer
        Load balancer to get logs for.

    .PARAMETER AccountId
        AWS Account id of the account that contains the load balancer.
        If not specified it will be detected from the account you are running this command under.

    .PARAMETER LimitSize
        Limit the size of the log download.
        If the combined size of all the logs to download exceeds this size in bytes, the command will abort.

    .PARAMETER StartTime
        The start of the time range. Events with a time stamp equal to this time or later than this time are included. Events with a time stamp earlier than this time are not included.

    .PARAMETER EndTime
        The end of the time range. Events with a time stamp equal to or later than this time are not included.

    .PARAMETER Last
        Sets the time range to the last X minutes from now.

    .OUTPUTS
        [object]
        List of parsed log entries. Fields depend on whether the target load balancer is classic or application.
        Both LB types have an additional field:
        - elb_node_ip: IP of the load balancer node that handled the request

    .NOTES
        IAM permissions required to run this command
        - sts:GetCallerIdentity (when -AccountId is not specified)
        - ec2:DescribeLoadBalancers (when -LoadBalancer is a name)
        - ec2:DescribeLoadBalancerAttributes
        - s3:GetBucketLocation
        - s3:GetObject
        - s3:ReadObject

    .EXAMPLE
        Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer my-loadbalancer -Last 30
        Read all events for the last 30 minutes.

    .EXAMPLE
        Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer my-loadbalancer -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30))
        Read all events for the given range.

    .EXAMPLE
        $lb = Get-ELBLoadBalancer -LoadBalancerName my-loadbalancer ; Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer $lb -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30))
        Read all events for Classic ELB for the given range with a load balancer object as input.

    .EXAMPLE
        $lb = Get-ELB2LoadBalancer -LoadBalancerName my-loadbalancer ; Read-ATEC2LoadBalancerLogs.ps1 -LoadBalancer $lb -StartTime ([DateTime]::UtcNow.AddHours(-1)) -EndTime ([DateTime]::UtcNow.AddMinutes(-30))
        Read all events for ALB for the given range with a load balancer object as input.

    .LINK
        https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Read-ATEC2LoadBalancerLogs.md

    .LINK
        https://docs.aws.amazon.com/elasticloadbalancing/latest/classic/access-log-collection.html

    .LINK
        https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html

#>
    [CmdletBinding(DefaultParametersetname = 'LastX')]
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
        # Get account ID for account the session is authenticated with
        $AccountId = Get-STSCallerIdentity | Select-Object -ExpandProperty Account
    }

    if ($LoadBalancer -is [string])
    {
        # -LoadBalancer argument was a string, i.e. a load balancer name
        try
        {
            # Is it classic?
            $lb = Get-ELBLoadBalancer -LoadBalancerName $LoadBalancer
        }
        catch
        {
            # No
            $lb = $null
        }

        if (-not $lb)
        {
            # Is it application?

            $lbArg = $(

                # Sort out whether the input was a name or an ARN and build an argument hash for Get-ELB2LoadBalancer
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
                # Not application
                $lb = $null
            }
        }

        if (-not $lb)
        {
            throw "Cannot find ALB or Classic ELB with name $LoadBalancer"
        }

        $LoadBalancer = $lb
    }

    # Need to cater for mock classic ELB object
    if ($LoadBalancer -is [Amazon.ElasticLoadBalancing.Model.LoadBalancerDescription] -or $LoadBalancer.ToString() -eq 'Test.LoadBalancerDescription')
    {
        # Classic

        # Get bucket and key prefix from attributes
        $attributes = Get-ELBLoadBalancerAttribute -LoadBalancerName $LoadBalancer.LoadBalancerName
        $bucket = $attributes.AccessLog.S3BucketName
        $prefix = $attributes.AccessLog.S3BucketPrefix

        # S3 log file names built from LB name
        $loadBalancerId = $LoadBalancer.LoadBalancerName

        # List of log columns for classic LBs
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

        # Check on the bucket name rather than the enabled flag, since logging may have been enabled previously then disabled
        if ([string]::IsNullOrEmpty($bucket))
        {
            Write-Host -ForegroundColor Yellow "Logging not configured for this load balancer"
            return
        }
    }
    # Need to cater for mock application ELB object
    elseif ($LoadBalancer -is [Amazon.ElasticLoadBalancingV2.Model.LoadBalancer] -or $LoadBalancer.ToString() -eq 'Test.V2LoadBalancer')
    {
        # ALB

        # Get bucket and key prefix from attributes
        $attributes = Get-ELB2LoadBalancerAttribute -LoadBalancerArn $LoadBalancer.LoadBalancerArn
        $bucket = $attributes | Where-Object { $_.Key -eq 'access_logs.s3.bucket' } | Select-Object -ExpandProperty Value
        $prefix = $attributes | Where-Object { $_.Key -eq 'access_logs.s3.prefix' } | Select-Object -ExpandProperty Value

        # S3 log file names built from LB full resource name which we axtract from the ARN
        $loadBalancerId = $(
            $LoadBalancer.LoadBalancerArn -match 'loadbalancer/(?<name>.*)$' | Out-Null
            $Matches.name
        )

        # List of log columns for application LBs
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

        # Check on the bucket name rather than the enabled flag, since logging may have been enabled previously then disabled
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

    # Get list of S3 objects for logs in the time period
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

    # Download and process logs
    $logObjects |
        ForEach-Object {

        try
        {
            $s3Object = $_
            $filename = Split-Path -Leaf $_.Key
            $localFile = Join-Path ([IO.Path]::GetTempPath()) $filename

            Write-Progress -Activity 'Getting Logs' -CurrentOperation "Processing $filename" -Status 'Downloading' -PercentComplete ($bytesDownloaded * 100 / $downloadSize )
            Read-S3Object -BucketName $_.BucketName -Key $_.Key -File $localFile | Out-Null
            $bytesDownloaded += $_.Size

            if ([System.IO.Path]::GetExtension($_.Key) -ieq '.gz')
            {
                Write-Progress -Activity 'Getting Logs' -CurrentOperation "Processing $filename" -Status 'Decompressing' -PercentComplete ($bytesDownloaded * 100 / $downloadSize )
                # uncompress - delete compressed, set $localfile to uncompressed path
                $uncompressed = Join-Path ([IO.Path]::GetTempPath()) ([System.IO.Path]::GetFileNameWithoutExtension($_.Key))

                try
                {
                    $originalFileStream = [System.IO.File]::OpenRead($localFile)
                    $decompressedFileStream = [System.IO.File]::Create($uncompressed)
                    $decompressionStream = New-Object System.IO.Compression.GZipStream -ArgumentList ($originalFileStream, [System.IO.Compression.CompressionMode]::Decompress)

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

            Write-Progress -Activity 'Getting Logs' -CurrentOperation "Processing $filename" -Status 'Importing' -PercentComplete ($bytesDownloaded * 100 / $downloadSize )

            Import-Csv -Header $columns -Delimiter ' ' -Path $localFile |
                ForEach-Object {
                $_ |
                    Add-Member -PassThru -MemberType NoteProperty -Name TimeStampDateTime -Value ([datetime]::Parse($_.timestamp)) |
                    Add-Member -PassThru -MemberType NoteProperty -Name elb_node_ip -Value $s3Object.NodeIp
            }
        }
        finally
        {
            Write-Progress -Activity 'Getting Logs' -CurrentOperation "Processing $filename" -PercentComplete ($bytesDownloaded * 100 / $downloadSize ) -Completed

            if (Test-Path -Path $localFile)
            {
                Remove-Item $localFile
            }
        }
    } |
        Sort-Object -Descending TimeStampDateTime |
        Select-Object -Property @( @(@{Name = "timestamp"; Expression = {$_.TimeStampDateTime}}, 'elb_node_ip') + $columns) -ExcludeProperty timestamp
}
