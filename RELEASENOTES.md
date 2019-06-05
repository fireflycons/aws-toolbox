# Release Notes

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