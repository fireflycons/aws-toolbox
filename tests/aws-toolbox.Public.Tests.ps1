$ModuleName = 'aws-toolbox'

Get-Module -Name $ModuleName | Remove-Module

# Find the Manifest file
$manifestFile = "$(Split-path (Split-Path -Parent -Path $MyInvocation.MyCommand.Definition))\$ModuleName\$ModuleName.psd1"

$global:scriptRoot = $PSScriptRoot
Import-Module $manifestFile

Describe 'EC2' {

    Context 'Read-ATEC2LoadBalancerLogs' {

        InModuleScope -Module $ModuleName {

            Mock -CommandName Get-S3BucketLocation -MockWith {

                New-Object PSObject -Property @{ Value = 'us-west-2' }
            }

            Mock -CommandName Get-STSCallerIdentity -MockWith {

                New-Object PSObject -Property @{ Account = '123456789012' }
            }
        }

        It 'Should read classic ELB logs' {

            InModuleScope -Module $ModuleName {

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
            }

            $logData = Read-ATEC2LoadBalancerLogs -LoadBalancer 'my-loadbalancer' -StartTime ([DateTime]::new(2014, 2, 15, 23, 30, 0, 0, 'Utc')) -EndTime ([DateTime]::new(2014, 2, 15, 23, 50, 0, 0, 'Utc'))
            $x = 1
        }
    }
}