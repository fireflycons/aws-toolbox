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
$global:thisModule = Import-Module $manifestFile -PassThru

InModuleScope $ModuleName {

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

                #Write-Host "Mock Get-S3Object: Prefix: $($KeyPrefix)"

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

                $returnedObjects = $objects | Where-Object { $_.Key.StartsWith($KeyPrefix) }

                #Write-Host "Mock Get-S3Object: Return count: $(($returnedObjects | Measure-Object).Count)"

                $returnedObjects
            }

            It 'Should get logs with date range' {

                $startDate =  [datetime]::new(2014,2,15,23,40,0,0,'Utc')
                $endtDate =  [datetime]::new(2014,2,16,0,30,0,0,'Utc')

                $logs = Get-LoadBalancerAccessLogs -LoadBalancerId 'my-loadbalancer' -AccountId 123456789012 -BucketName mybucket -KeyPrefix my-app -StartTime $startDate -EndTime $endtDate

                # 15/02/2014 23:40:00 x 2, 15/02/2014 23:55:00, 16/02/2014 00:10:00, 16/02/2014 00:25:00
                ($logs | Measure-Object).Count | Should Be 5
            }

            It 'Should get logs for last 30 minutes' {

                $logs = Get-LoadBalancerAccessLogs -LoadBalancerId 'my-loadbalancer' -AccountId 123456789012 -BucketName mybucket -KeyPrefix my-app -Last 30

                # At 15 min interval, should be 2 or 3 returned
                ($logs | Measure-Object).Count | Should BeIn @(2,3)
            }

            It 'Should throw if date range gt 4 hours' {

                $env:AWTB_IGNORE_ELBROWCOUNT = $null
                { Get-LoadBalancerAccessLogs -LoadBalancerId 'my-loadbalancer' -AccountId 123456789012 -BucketName mybucket -KeyPrefix my-app -Last 250 } | Should Throw
            }

            It 'Should not throw if date range gt 4 hours and AWTB_IGNORE_ELBROWCOUNT = 1' {

                $env:AWTB_IGNORE_ELBROWCOUNT = '1'
                { Get-LoadBalancerAccessLogs -LoadBalancerId 'my-loadbalancer' -AccountId 123456789012 -BucketName mybucket -KeyPrefix my-app -Last 250 } | Should -Not -Throw
                $env:AWTB_IGNORE_ELBROWCOUNT = $null
            }
        }

        Context 'S3 Url Parsing - Path style' {

            @(
                'https://s3.amazonaws.com/jeffbarr-public/images/ritchie_and_thompson_pdp11.jpeg'
                'https://s3-us-east-2.amazonaws.com/jeffbarr-public/images/ritchie_and_thompson_pdp11.jpeg'
                'https://s3.us-east-2.amazonaws.com/jeffbarr-public/images/ritchie_and_thompson_pdp11.jpeg'
                'https://s3.us-gov-east-1.amazonaws.com/jeffbarr-public/images/ritchie_and_thompson_pdp11.jpeg'
                'https://s3-us-gov-east-1.amazonaws.com/jeffbarr-public/images/ritchie_and_thompson_pdp11.jpeg'
            ) |
            Foreach-Object {

                $uri = [Uri]$_

                It "Should parse $uri" {

                    { $uri | Split-S3Url } | Should Not throw

                    $loc = $uri | Split-S3Url
                    $loc.BucketName | Should -Be 'jeffbarr-public'
                    $loc.Key | Should -Be 'images/ritchie_and_thompson_pdp11.jpeg'
                }
            }
        }

        Context 'S3 Url Parsing - Virtual domain style' {

            @(
                'https://jeffbarr-public.s3.amazonaws.com/images/ritchie_and_thompson_pdp11.jpeg'
                'https://jeffbarr-public.s3.amazonaws.com/images/ritchie_and_thompson_pdp11.jpeg'
                'https://jeffbarr-public.s3.eu-west-1.amazonaws.com/images/ritchie_and_thompson_pdp11.jpeg'
                'https://jeffbarr-public.s3-eu-west-1.amazonaws.com/images/ritchie_and_thompson_pdp11.jpeg'
                'https://jeffbarr-public.s3-us-gov-east-1.amazonaws.com/images/ritchie_and_thompson_pdp11.jpeg'
            ) |
            Foreach-Object {

                $uri = [Uri]$_

                It "Should parse $uri" {

                    { $uri | Split-S3Url } | Should Not throw

                    $loc = $uri | Split-S3Url
                    $loc.BucketName | Should -Be 'jeffbarr-public'
                    $loc.Key | Should -Be 'images/ritchie_and_thompson_pdp11.jpeg'
                }
            }
        }

        Context 'S3 Workspace Bucket' {

            Mock Get-STSCallerIdentity -MockWith {
                New-Object PSObject -Property @{
                    Account = '000000000000'
                }
            }

            Mock -Command Get-S3BucketTagging -MockWith {}

            Mock -Command Write-S3BucketTagging -MockWith {}

            It 'Should return bucket details if bucket exists' {

                $global:region = 'us-east-1'
                Set-DefaultAWSRegion -Region $region

                $expectedBucketName = "aws-toolbox-workspace-$($region)-000000000000"
                $expectedBucketUrl = [uri]"https://s3.$($region).amazonaws.com/$expectedBucketName"

                Mock -CommandName Get-S3BucketLocation -MockWith {

                    if ($null -eq $global:region)
                    {
                        throw "Mock Get-S3BucketLocation - region is null"
                    }

                    New-Object PSObject -Property @{
                        Value = $global:region
                    }
                }

                $result = Get-WorkspaceBucket
                Assert-MockCalled -CommandName Get-STSCallerIdentity -Times 1
                $result.BucketName | Should Be $expectedBucketName
                $result.BucketUrl | Should Be $expectedBucketUrl
            }

            It 'Should tag existing bucket if untagged' {

                $global:region = 'us-east-1'
                Set-DefaultAWSRegion -Region $region

                Mock -CommandName Get-S3BucketLocation -MockWith {

                    New-Object PSObject -Property @{
                        Value = $global:region
                    }
                }

                Get-WorkspaceBucket | Out-Null
                Assert-MockCalled -CommandName Write-S3BucketTagging -Times 1 -Scope It
            }

            It 'Should create and tag a bucket if bucket does not exist' {

                Mock -CommandName Get-S3BucketLocation -MockWith {

                    if ($script:callCount++ -eq 0)
                    {
                        throw "The specified bucket does not exist"
                    }

                    New-Object PSObject -Property @{
                        Value = $global:region
                    }
                }

                Mock -CommandName New-S3Bucket -MockWith {
                    $true
                }

                $region = 'us-east-1'
                Set-DefaultAWSRegion -Region $region

                $expectedBucketName = "aws-toolbox-workspace-$($region)-000000000000"
                $expectedBucketUrl = [uri]"https://s3.$($region).amazonaws.com/$expectedBucketName"
                $script:callCount = 0

                $result = Get-WorkspaceBucket
                $result.BucketName | Should Be $expectedBucketName
                $result.BucketUrl | Should Be $expectedBucketUrl

                Assert-MockCalled -CommandName Get-S3BucketLocation -Times 2
                Assert-MockCalled -CommandName New-S3Bucket -Times 1
                Assert-MockCalled -CommandName Write-S3BucketTagging -Times 1 -Scope It
            }

            It 'Should not tag existing bucket if already tagged' {

                Mock -Command Get-S3BucketTagging -MockWith {
                    1..3
                }

                Mock -CommandName Get-S3BucketLocation -MockWith {

                    New-Object PSObject -Property @{
                        Value = $global:region
                    }
                }

                $region = 'us-east-1'
                Set-DefaultAWSRegion -Region $region

                Get-WorkspaceBucket | Out-Null
                Assert-MockCalled -CommandName Write-S3BucketTagging -Times 0 -Scope It
            }
        }
    }

    Describe 'AWS CLI Configuration Files' {

        $savedConfig = $env:AWS_CONFIG_FILE
        $savedCredentials = $env:AWS_SHARED_CREDENTIALS_FILE

        Context 'Read existing configuation' {

            $config = Read-CliConfigurationFile -Config

            It 'Reads the config file from user profile' {

                if (($config.Keys | Measure-Object).Count -eq 0)
                {
                    Set-ItResult -Inconclusive -Because "No AWS config file is present"
                }
            }

            It 'May have a [default] section' {

                if (($config.Keys | Measure-Object).Count -eq 0)
                {
                    Set-ItResult -Inconclusive -Because "No AWS config file is present"
                }
                else
                {
                    if (-not ($config.Keys | Where-Object { $_ -eq 'default'}))
                    {
                        Set-ItResult -Inconclusive -Because "A [default] section was not present"
                    }
                }
            }
        }

        Context 'Read existing credentials' {

            $config = Read-CliConfigurationFile -Credentials

            It 'Reads the credentails file from user profile' {

                if (($config.Keys | Measure-Object).Count -eq 0)
                {
                    Set-ItResult -Inconclusive -Because "No AWS credentials file is present"
                }
            }

            It 'May have a [default] section' {

                if (($config.Keys | Measure-Object).Count -eq 0)
                {
                    Set-ItResult -Inconclusive -Because "No AWS credentials file is present"
                }
                else
                {
                    if (-not $config.ContainsKey('default'))
                    {
                        Set-ItResult -Inconclusive -Because "A [default] section was not present"
                    }
                }
            }

            if ($config.ContainsKey('default'))
            {
                $script:sectionData = $config['default']

                It 'Has an access key in [default] section' {

                    $script:sectionData.ContainsKey('aws_access_key_id') | Should -BeTrue
                }

                It 'Has an secret key in [default] section' {

                    $script:sectionData.ContainsKey('aws_secret_access_key') | Should -BeTrue
                }
            }
        }

        Context 'Writing the config file' {

            $script:storedData = $null

            BeforeEach {

                $env:AWS_CONFIG_FILE = Join-Path $TestDrive 'config'
            }

            AfterEach {

                $env:AWS_CONFIG_FILE = $savedConfig
            }

            $initialData = @{
                default = @{
                    region = 'eu-west-1'
                }
            }

            $configFile = Join-Path $TestDrive 'config'
            $fileSize = 0

            It 'Creates initial config' {

                $initialData | Write-CliConfigurationFile -Config
                $configFile | Should -Exist
                $fileSize = (Get-Item $configFile).Length
            }

            It 'Updates config file' {

                $initialData['default'].Add('output', 'json')
                $initialData | Write-CliConfigurationFile -Config
                $configFile | Should -Exist
                $newFileSize = (Get-Item $configFile).Length

                $newFileSize | Should -BeGreaterThan $fileSize -Because "the file should have been appended."
            }

            It 'Reads the config file created above' {

                $script:storedData = Read-CliConfigurationFile -Config
                ($script:storedData.Keys | Measure-Object).Count | Should -BeExactly 1
            }

            It 'Has a [default] section' {

                $script:storedData.ContainsKey('default') | Should -BeTrue
                $script:sectionData = $script:storedData['default']
            }

            It 'Should have stored correct default region' {

                $script:sectionData.ContainsKey('region') | Should -BeTrue
                $script:sectionData['region'] | Should -Be 'eu-west-1'
            }

            It 'Should have stored correct output format' {

                $script:sectionData.ContainsKey('output') | Should -BeTrue
                $script:sectionData['output'] | Should -Be 'json'
            }

            $s3Options = @{
                max_concurrent_requests = 20
                max_queue_size = 10000
                multipart_threshold = "64MB"
                multipart_chunksize = "16MB"
                max_bandwidth = "50MB/s"
                use_accelerate_endpoint = "true"
                addressing_style = "path"
                }

            It 'Writes S3 options' {

                $initialData['default'].Add('s3', $s3Options)
                $initialData | Write-CliConfigurationFile -Config
                # Test it doesn't get borked reading then writing
                Read-CliConfigurationFile -Config | Write-CliConfigurationFile -Config
                $script:newConfig = Read-CliConfigurationFile -Config
            }

            $s3Options.Keys |
            ForEach-Object {

                $opt = $_

                It "Should corrently set s3 option '$opt'" {

                    $script:newConfig['default']['s3'][$opt] | Should -Be $s3Options[$opt]
                }
            }
        }

        Context 'Writing the credential file' {

            $script:storedData = $null

            BeforeEach {

                $env:AWS_SHARED_CREDENTIALS_FILE = Join-Path $TestDrive 'credentials'
            }

            AfterEach {

                $env:AWS_SHARED_CREDENTIALS_FILE = $savedCredentials
            }


            $accessKey = 'AKIAITL6SYXXQEXAMPLE'
            $secretKey = '+pdwYIYvKVpW1//FokBjqFXxOnzbmyEXAMPLE'
            $initialData = @{
                mycreds = @{
                    aws_access_key_id = $accessKey
                    aws_secret_access_key = $secretKey
                }
            }

            $credentialFile = Join-Path $TestDrive 'credentials'

            It 'Creates initial credentials' {

                $initialData | Write-CliConfigurationFile -Credentials
                $credentialFile | Should -Exist
            }


            It 'Reads the credentials file created above' {

                $script:storedData = Read-CliConfigurationFile -Credentials
                ($script:storedData.Keys | Measure-Object).Count | Should -BeExactly 1
            }

            It 'Has a [mycreds] section' {

                $script:storedData.ContainsKey('mycreds') | Should -BeTrue
            }

            if ($script:storedData.ContainsKey('mycreds'))
            {
                $script:sectionData = $script:storedData['mycreds']

                It 'Should have stored correct access key' {

                    $script:sectionData.ContainsKey('aws_access_key_id') | Should -BeTrue
                    $script:sectionData['aws_access_key_id'] | Should -Be $accessKey
                }

                It 'Should have stored correct secret key' {

                    $script:sectionData.ContainsKey('aws_secret_access_key') | Should -BeTrue
                    $script:sectionData['aws_secret_access_key'] | Should -Be $secretKey
                }

                $accessKey = 'AKIAITXXXXXXQEXAMPLE'

                $initialData['mycreds']['aws_access_key_id'] = $accessKey

                It 'Updates credentials file with new access key' {

                    $initialData | Write-CliConfigurationFile -Credentials
                    $credentialFile | Should -Exist
                }


                It 'Has stored updated access key' {

                    $script:sectionData = (Read-CliConfigurationFile -Credentials)['mycreds']
                    $script:sectionData.ContainsKey('aws_secret_access_key') | Should -BeTrue
                    $script:sectionData['aws_secret_access_key'] | Should -Be $secretKey
                }

                It 'Has not changed the secret key' {

                    $script:sectionData.ContainsKey('aws_secret_access_key') | Should -BeTrue
                    $script:sectionData['aws_secret_access_key'] | Should -Be $secretKey
                }
            }
        }
    }

    Describe 'AWS CLI External Credential Source' {

        $savedCredentials = $env:AWS_SHARED_CREDENTIALS_FILE

        Context 'Credential Process Generation' {

            $credProcess =  Get-CredentialProcess -CacheScriptPath (Join-Path ([IO.Path]::GetTempPath()) "test-cache.ps1")
            $ps = $(
                if ($PSEdition -eq 'Desktop')
                {
                    'powershell'
                }
                else
                {
                    'pwsh'
                }
            )

            It 'Should select correct PowerShell interpreter' {

                $credProcess.PowerShell | Should -Be (Get-Command $ps).Source
            }

            It 'Should select this module' {

                $credProcess.Module | Should -Be $thisModule.Name
            }
        }

        Context 'Credential Source Configuration' {

            BeforeEach {

                $env:AWS_SHARED_CREDENTIALS_FILE = Join-Path $TestDrive 'credentials'
            }

            AfterEach {

                $env:AWS_SHARED_CREDENTIALS_FILE = $savedCredentials
            }

            It 'Does something' {

                Set-ATIAMCliExternalCredentials -ProfileName eddie
            }
        }
    }
}