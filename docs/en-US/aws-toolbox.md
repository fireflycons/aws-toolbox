---
Module Name: aws-toolbox
Module Guid: e3c04d58-4e7d-4572-9e81-3b3a93f1a518
Download Help Link: {{Please enter FwLink manually}}
Help Version: {{Please enter version of help manually (X.X.X.X) format}}
Locale: en-US
---

# aws-toolbox Module
## Description
A module containing a collection of PowerShell scripts I've created to ease various AWS tasks.

## CloudFormation Cmdlets
### [Compare-ATDeployedStackWithSourceTemplate](Compare-ATDeployedStackWithSourceTemplate.md)
Compare a template file with what is currently deployed in CloudFormation and report on stack drift.

### [Compare-ATCFNStackResourceDrift](Compare-ATCFNStackResourceDrift.md)
Get detailed information on stack drift.

### [Set-ATCFNStackProtectionPolicy](Set-ATCFNStackProtectionPolicy.md)
Set or remove stack policy to prevent replacement or deletion of resources.

## CloudWatch Cmdlets
### [Read-ATCWLFlowLog](Read-ATCWLFlowLog.md)
Read a flow log into a list of PowerShell custom objects.

## Elastic Beanstalk Cmdlets
### [Get-ATEBEnvironmentResourceList](Get-ATEBEnvironmentResourceList.md)
Gets a list of resources associated with Elastic Beanstalk environents.

### [Get-ATEBInstanceLogs](Get-ATEBInstanceLogs.md)
Retrieve CloudFormation Init and Elastic Beanstalk instance logs from one or more instances.

## EC2 Cmdlets
### [Get-ATEC2LatestAMI](Get-ATEC2LatestAMI.md)
Build a CloudFormation mapping for the latest version of an AMI in all accessible regions.

### [Read-ATEC2LoadBalancerLogs](Read-ATEC2LoadBalancerLogs.md)
Read Load Balancer logs into a list of PowerShell custom objects.

### [Test-ATEC2IsRunningInEC2](Test-ATEC2IsRunningInEC2.md)
Tests for executing on EC2 by trying to read EC2 instance metadata URL.

### [Get-ATEC2SecurityGroupDependencies](Get-ATEC2SecurityGroupDependencies.md)
Find dependencies and attachments of given security group(s)

## IAM Cmdlets
### [Get-ATIAMSessionCredentials](Get-ATIAMSessionCredentials.md)
Gets keys from a federated AWS login

## Lambda Cmdlets
### [Compress-ATLMLambdaPackage](Compress-ATLMLambdaPackage.md)
Packages lambda function code to a zip file

## SSM Cmdlets
### [Invoke-ATSSMPowerShellScript](Invoke-ATSSMPowerShellScript.md)
Run PowerShell on hosts using SSM AWS-RunPowerShellScript.

### [Invoke-ATSSMShellScript](Invoke-ATSSMPhellScript.md)
Run bash scripts on hosts using SSM AWS-RunShellScript.

### [Set-ATSSMWindowsAdminUser](Set-ATSSMWindowsAdminUser.md)
Use SSM to set up an admin user on one or more Windows instances

## Utility Cmdlets
### [Set-ATConfigurationItem](Set-ATConfigurationItem.md)
Set configurable items for this module

### [Invoke-ATDiffTool](Invoke-ATDiffTool)
Runs the configured diff tool on a pair of files