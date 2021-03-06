# Release Notes

## 1.0.1 

* Add missing dependency `AWS.Tools.AutoScaling`

## 1.0.0

* Convert to use AWS.Tools instead of the old monolithic AWSPowerShell. AWS Tools is cross-pltform therefore there is no longer a need to publish an addtional .netcore version of this module - it is now inherently cross-platform.

## 0.18.0

* Enhance `Get-ATEBEnvironmentResourceList` to return temporary infrastructre created during the course of an Immutable Deployment

## 0.17.3

* Bug fix in `Get-ATIAMSessionCredentials` where a null object reference exception is thrown if converting IAM::User credentials

## 0.17.2

* Create a mechanism to cache external credeentials so that this module is not reloaded for every invocation of AWS CLI resulting in poor performance

## 0.17.1

* Add `-AwsCli` switch to `Get-ATIAMSessionCredentials` to output in external credential format for AWS CLI
* Add `Set-ATIAMCliExternalCredentials` cmdlet to insert aws-toolbox as an external credential process for supplying SAML credentials to AWS CLI

## 0.16.0

* `Set-ATSSMWindowsAdminUser` Use ADSI to get better control over setting of credentials. If user exists update password, else create user and add to administrators.

## 0.15.0

* New Command `Get-ATEC2SecurityGroupDependencies`. Given a security group ID or IDs, find all network interfaces and other security groups that refer to the input IDs.
Useful before trying to delete a group, as it will not delete if it has any dependecies.

## 0.14.1

* Fix a bug that arose today. Seems AWS have changed S3 URL format for urls with region in. Was s3-eu-west-1, now s3.eu-west-1. Either way, support both.

## 0.14.0

* New command `Compare-ATCFNStackResourceDrift`. Formats all resource drifts into two files that can be visually compared in the configured diff tool.
* Fix bug in plugin-config.json

## 0.13.0

* Fix 'Cannot pipe output of Invoke-ATSSMPowerShellScript -AsText to e.g. Out-File'
* Add a configuration system - currently to configure which app is used for diffs
    * Supports WinMerge, VSCode and Git as diff tools

## v0.12.1

* Fix bug in `Compress-ATLMLambdaPackage`

## v0.12.0

* New command `Compress-ATLMLambdaPackage` packages up a zip file of lambda code for updating lambda functions.

## v0.11.0

* Tag S3 worksapce bucket on creation, or if untagged.

## v0.10.0

Fixes

* `Get-ATEBEnvironmentResourceList` should filter out terminated environments
* Invoke-SSM* script commands only processing one instance

## v0.9.0

* Support PowerShell Core/Linux

Added

* `Invoke-ATSSMShellScript` Run shell commands on Linux instances via SSM

Enhanced

* `Get-ATEBInstanceLogs` Now supports Linux environments

## v0.8.0

Added

* `Get-ATIAMSessionCredentials` If your organisation uses federated authentication (SAML etc) for API authentication with AWS, this cmdlet enables you to get a set of temporary keys for use with applications that do not understand/support this authentication method.

## v0.7-alpha

Added

* `Get-ATEBInstanceLogs` - Download Elastic Beanstalk logs from environment instances using SSM - Currently only Windows instances supported, but this will change!
* `Set-ATSSMWindowsAdminUser` - Set up an admin user on Windows instances using SSM.

## v0.61-alpha

Enhanced

* `Invoke-ATSSMPowerShellScript` Added `-UseS3` switch to enable passing of command output > 2000 bytes through S3.

## v0.4-alpha

Fixed bugs in `Invoke-ATSSMPowerShellScript`

## v0.3-alpha

Added

* `Invoke-ATSSMPowerShellScript` - Run PowerShell on hosts using SSM AWS-RunPowerShellScript.

Enhanced

* `Get-ATEBEnvironmentResourceList`

## v0.2-alpha

Added new commands

* `Get-ATEBEnvironmentResourceList` - Gets a list of Elastic Beanstalk resources
* `Compare-ATDeployedStackWithSourceTemplate` - Checks a CloudFormation stack, checking drift and comparing a local template with that last deployed.

## v0.1-alpha

Initial publish