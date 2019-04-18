$ModuleName = $(
    if ($PSVersionTable.PSEdition -ieq 'Core')
    {
        'aws-toolbox.netcore'
    }
    else
    {
        'aws-toolbox'
    }
)

# http://www.lazywinadmin.com/2016/05/using-pester-to-test-your-manifest-file.html
# Make sure one or multiple versions of the module are not loaded
Get-Module -Name $ModuleName | Remove-Module

# Find the Manifest file
$ManifestFile = Get-ChildItem -Path (Split-path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition)) -Recurse -Filter "$ModuleName.psd1" | Select-Object -ExpandProperty FullName

if (($ManifestFile | Measure-Object).Count -ne 1)
{
    throw "Cannot locate $ModuleName.psd1"
}

$global:scriptRoot = $PSScriptRoot
Import-Module $manifestFile

InModuleScope -Module $ModuleName {

    Describe 'EC2' {

        Context 'Read-ATEC2LoadBalancerLogs' {

            Mock -CommandName Get-S3BucketLocation -MockWith {

                New-Object PSObject -Property @{ Value = 'us-east-2' }
            }

            Mock -CommandName Get-STSCallerIdentity -MockWith {

                New-Object PSObject -Property @{ Account = '123456789012' }
            }

            It 'Should read classic ELB logs' {

                Mock -CommandName Get-ELBLoadBalancer -MockWith {

                    New-Object PSObject -Property @{
                        LoadBalancerName = 'my-loadbalancer'
                    } |
                        Add-Member -PassThru -MemberType ScriptMethod -Name ToString -Value { return 'Test.LoadBalancerDescription' } -Force
                }

                Mock -CommandName Get-S3Object -MockWith {

                    @(
                        New-Object PSObject -Property @{
                            BucketName = 'my-bucket'
                            Key        = 'my-classic-app/AWSLogs/123456789012/elasticloadbalancing/us-east-2/2014/02/15/123456789012_elasticloadbalancing_us-east-2_my-loadbalancer_20140215T2340Z_172.160.001.192_20EMOTPKSW.log'
                            Size       = 675
                        }
                    )
                }

                Mock -CommandName Read-S3Object -MockWith {

                    Copy-Item "$($global:scriptRoot)\Assets\elb.log" $File
                }

                Mock -CommandName Get-ELBLoadBalancerAttribute -MockWith {

                    New-Object PSObject -Property @{
                        AccessLog = New-Object PSObject -Property @{
                            S3BucketName   = 'my-bucket'
                            S3BucketPrefix = 'my-classic-app'
                        }
                    }
                }

                $logData = Read-ATEC2LoadBalancerLogs -LoadBalancer 'my-loadbalancer' -StartTime ([DateTime]::new(2014, 2, 15, 23, 30, 0, 0, 'Utc')) -EndTime ([DateTime]::new(2014, 2, 15, 23, 50, 0, 0, 'Utc'))

                # Should return 4 rows
                ($logData | Measure-Object).Count | Should Be 4
            }

            It 'Should read ALB compressed logs' {

                Mock -CommandName Get-ELB2LoadBalancer -MockWith {

                    New-Object PSObject -Property @{
                        LoadBalancerName = 'my-loadbalancer'
                        LoadBalancerArn = 'arn:aws:elasticloadbalancing:us-east-2:324811521787:loadbalancer/app/my-loadbalancer/1fd293e4e28b9747'
                    } |
                        Add-Member -PassThru -MemberType ScriptMethod -Name ToString -Value { return 'Test.V2LoadBalancer' } -Force
                }

                # Re-mock this. I thought that mocks within a context e.g. It would be pulled out at then end of the context - seems not.
                Mock -CommandName Get-ELBLoadBalancer -MockWith {

                    $null
                }

                Mock -CommandName Get-S3Object -MockWith {

                    @(
                        New-Object PSObject -Property @{
                            BucketName = 'my-bucket'
                            Key        = 'my-alb-app/AWSLogs/123456789012/elasticloadbalancing/us-east-2/2014/02/15/123456789012_elasticloadbalancing_us-east-2_app.my-loadbalancer.1fd293e4e28b9747_20140215T2340Z_172.160.001.192_20EMOTPKSW.log.gz'
                            Size       = 622
                        }
                    )
                }

                Mock -CommandName Read-S3Object -MockWith {

                    Copy-Item "$($global:scriptRoot)\Assets\alb.log.gz" $File
                }

                Mock -CommandName Get-ELB2LoadBalancerAttribute -MockWith {

                    @(
                        New-Object PSObject -Property @{
                            Key = 'access_logs.s3.bucket'
                            Value = 'my-bucket'
                        }
                        New-Object PSObject -Property @{
                            Key = 'access_logs.s3.prefix'
                            Value = 'my-alb-app'
                        }
                    )
                }

                $logData = Read-ATEC2LoadBalancerLogs -LoadBalancer 'my-loadbalancer' -StartTime ([DateTime]::new(2014, 2, 15, 23, 30, 0, 0, 'Utc')) -EndTime ([DateTime]::new(2014, 2, 15, 23, 50, 0, 0, 'Utc'))

                # Should return 7 rows
                ($logData | Measure-Object).Count | Should Be 7
            }
        }
    }

    Describe 'EB' {

        Context 'Get-ATEBInstanceLogs' {

            Mock Get-EC2Instance -MockWith {

                $InstanceId |
                ForEach-Object {
                    New-Object PSObject -Property @{
                        Instances = @(
                            New-Object PSObject -Property @{
                                Platform = 'Windows'
                                InstanceId = $_
                            }
                        )
                    }
                }
            }

            Mock Get-EC2InstanceStatus -MockWith {

                $InstanceId |
                ForEach-Object {
                    New-Object PSObject -Property @{
                        InstanceId = $_
                        InstanceState = New-Object PSObject -Property @{
                            Code = 16
                            Name = 'Running'
                        }
                        Status = New-Object PSObject -Property @{
                            Status = New-Object PSObject -Property @{
                                Value = 'ok'
                            }
                        }
                        SystemStatus = New-Object PSObject -Property @{
                            Status = New-Object PSObject -Property @{
                                Value = 'ok'
                            }
                        }
                    }
                }
            }

            Mock Invoke-ATSSMPowerShellScript -MockWith {

                $lf = [char]10
                $InstanceIds |
                Foreach-Object {

                    $sb = New-Object System.Text.StringBuilder
                    $sb.Append("---#LOG# log1.log$lf").
                        Append("log 1 content$lf").
                        Append("---#LOG# log2.log$lf").
                        Append("log 2 content$lf") | Out-Null

                    New-Object PSObject -Property @{
                        InstanceId = $_
                        Stdout = $sb.ToString()
                        Stderr = [string]::Empty
                    }
                }
            }

            Mock Get-SSMEnabledInstances -MockWith {

                New-Object PSObject -Property @{
                    Windows = $InstanceId
                    NonWindows = $null
                    NonSSM = $null
                    NotReady = $null
                }
            }

            It 'Downloads logs for one instance' {

                Get-ATEBInstanceLogs -InstanceId i-00000001 -OutputFolder 'TESTDRIVE:\Test1'

                Test-Path -Path 'TESTDRIVE:\Test1\i-00000001' | Should Be $true
                (Get-ChildItem -Path 'TESTDRIVE:\Test1\i-00000001' | Measure-Object).Count | Should Be 2
            }

            It 'Downloads logs for two instances' {

                Get-ATEBInstanceLogs -InstanceId i-00000001,i-00000002 -OutputFolder 'TESTDRIVE:\Test2'

                Test-Path -Path 'TESTDRIVE:\Test2\i-00000001' | Should Be $true
                Test-Path -Path 'TESTDRIVE:\Test2\i-00000002' | Should Be $true
                (Get-ChildItem -Path 'TESTDRIVE:\Test2\i-00000001' | Measure-Object).Count | Should Be 2
                (Get-ChildItem -Path 'TESTDRIVE:\Test2\i-00000002' | Measure-Object).Count | Should Be 2
            }
        }
    }
}