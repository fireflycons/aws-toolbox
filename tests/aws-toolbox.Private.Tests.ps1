$ModuleName = 'aws-toolbox'

Get-Module -Name $ModuleName | Remove-Module

# Find the Manifest file
$manifestFile = "$(Split-path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition))\$ModuleName\$ModuleName.psd1"

Import-Module $manifestFile

InModuleScope 'aws-toolbox' {

    Describe 'Utils' {

        Context 'Get-CurrentRegion' {

            BeforeEach {

                if (Test-Path -Path variable:StoredAWSRegion)
                {
                    Remove-Item  -Path variable:StoredAWSRegion
                }
            }

            It 'Should throw if default region never initialised' {

                if ($null -eq [Amazon.Runtime.FallbackRegionFactory]::GetRegionEndpoint())
                {
                    { Get-CurrentRegion } | Should -Throw
                }
                else
                {
                    Set-ItResult -Inconclusive -Because "you have already initialised a region (should not be the case on AppVeyor)."
                }
            }

            It 'Should return region set by Set-DefaultAWSRegion if no specific region passed' {

                Set-DefaultAWSRegion -Region us-east-2
                Get-CurrentRegion | Should -Be 'us-east-2'
            }
        }

    }

    Describe 'S3' {

        Context 'Get-LoadBalancerAccessLogs' {

            Mock -CommandName Get-S3BucketLocation -MockWith {

                New-Object PSObject -Property @{ Value = 'us-west-2' }
            }

            Mock -CommandName Get-S3Object -MockWith {

                $objects =@(
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-east-2/2014/02/15/123456789012_elasticloadbalancing_us-east-2_my-loadbalancer_20140215T2340Z_172.160.001.192_20EMOTPKSW.log' }

                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/15/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140215T2340Z_172.160.001.192_20VLOTFYQZ.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/15/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140215T2355Z_172.160.001.192_20RNIBMCSY.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0010Z_172.160.001.192_20DWFPBOFX.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0025Z_172.160.001.192_20PTQZXFXE.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0040Z_172.160.001.192_20GUTBIHJY.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0055Z_172.160.001.192_20WSNYRADF.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0110Z_172.160.001.192_20NOPNPJCV.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0125Z_172.160.001.192_20KNSBDYRL.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0140Z_172.160.001.192_20PZXRCCNB.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0155Z_172.160.001.192_20JZACWWFF.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0210Z_172.160.001.192_20MDHUIHCR.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0225Z_172.160.001.192_20MOSYOYNO.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0240Z_172.160.001.192_20WAOPGUPZ.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0255Z_172.160.001.192_20IUSLVBCN.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0310Z_172.160.001.192_20SALNCPXG.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0325Z_172.160.001.192_20RNTCMWYX.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0340Z_172.160.001.192_20FLUBDWOR.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0355Z_172.160.001.192_20QJBVSJMI.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0410Z_172.160.001.192_20VTZQUOUJ.log' }
                    New-Object PSObject -Property @{ Key='my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/16/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140216T0425Z_172.160.001.192_20NJGXYLUH.log' }

                    New-Object PSObject -Property @{ Key='your-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/15/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140215T2340Z_172.160.001.192_20EMOTPKSW.log' }
                    New-Object PSObject -Property @{ Key='your-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/2014/02/15/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_20140215T2355Z_172.160.001.192_20IDQJJLWJ.log' }
                )

                # Add some for -Last tests
                $dt = [datetime]::UtcNow

                $objects += 0..4 |
                Foreach-Object {
                    $d = ($dt - [timespan]::FromMinutes($_ * 15))
                    $rnd = [string]::new((1..8 | ForEach-Object {[char](get-random -min 65 -max (65+26))}))
                    $key = "my-app/AWSLogs/123456789012/elasticloadbalancing/us-west-2/$($d.ToString('yyyy/MM/dd'))/123456789012_elasticloadbalancing_us-west-2_my-loadbalancer_$($d.ToString('yyyyMMddTHHmmZ'))_172.160.001.192_20$($rnd).log"

                    New-Object PSObject -Property @{
                        Key = $key
                    }
                }

                $objects | Where-Object { $_.Key.StartsWith($KeyPrefix) }
            }

            It 'Should get logs with date range' {

                $startDate =  [datetime]::new(2014,2,15,23,40,0,0,'Utc')
                $endtDate =  [datetime]::new(2014,2,16,0,30,0,0,'Utc')

                $logs = Get-LoadBalancerAccessLogs -LoadBalancerId 'my-loadbalancer' -AccountId 123456789012 -BucketName mybucket -KeyPrefix my-app -StartTime $startDate -EndTime $endtDate

                # 15/02/2014 23:40:00, 15/02/2014 23:55:00, 16/02/2014 00:10:00, 16/02/2014 00:25:00
                ($logs | Measure-Object).Count | Should Be 4
            }

            It 'Should get logs for last 30 minutes' {

                $logs = Get-LoadBalancerAccessLogs -LoadBalancerId 'my-loadbalancer' -AccountId 123456789012 -BucketName mybucket -KeyPrefix my-app -Last 30

                # At 15 min interval, should be 2 or 3 returned
                ($logs | Measure-Object).Count | Should BeIn @(2,3)
            }
        }

        Context 'S3 Workspace Bucket' {

            Mock Get-STSCallerIdentity -MockWith {
                New-Object PSObject -Property @{
                    Account = '0123456789012'
                }
            }

            It 'Should return bucket details if bucket exists' {

                $region = 'us-east-1'
                Set-DefaultAWSRegion -Region $region

                $expectedBucketName = "aws-toolbox-workspace-$($region)-000000000000"
                $expectedBucketUrl = [uri]"https://s3.$($region).amazonaws.com/$expectedBucketName"

                Mock -CommandName Get-STSCallerIdentity -MockWith {

                    New-Object PSObject -Property @{
                        Account = '000000000000'
                    }
                }

                Mock -CommandName Get-S3BucketLocation -MockWith {

                    New-Object PSObject -Property @{
                        Value = $region
                    }
                }

                $result = Get-WorkspaceBucket
                Assert-MockCalled -CommandName Get-STSCallerIdentity -Times 1
                $result.BucketName | Should Be $expectedBucketName
                $result.BucketUrl | Should Be $expectedBucketUrl
            }

            It 'Should create bucket if bucket does not exist' {

                $region = 'us-east-1'
                Set-DefaultAWSRegion -Region $region

                $expectedBucketName = "aws-toolbox-workspace-$($region)-000000000000"
                $expectedBucketUrl = [uri]"https://s3.$($region).amazonaws.com/$expectedBucketName"
                $script:callCount = 0

                Mock -CommandName Get-STSCallerIdentity -MockWith {

                    New-Object PSObject -Property @{
                        Account = '000000000000'
                    }
                }

                Mock -CommandName Get-S3BucketLocation -MockWith {

                    if ($script:callCount++ -eq 0)
                    {
                        throw "The specified bucket does not exist"
                    }

                    New-Object PSObject -Property @{
                        Value = $region
                    }
                }

                Mock -CommandName New-S3Bucket -MockWith {
                    $true
                }

                $result = Get-WorkspaceBucket
                $result.BucketName | Should Be $expectedBucketName
                $result.BucketUrl | Should Be $expectedBucketUrl

                Assert-MockCalled -CommandName Get-S3BucketLocation -Times 2
                Assert-MockCalled -CommandName New-S3Bucket -Times 1
            }

        }
    }
}