# aws-toolbox

[![Build status](https://ci.appveyor.com/api/projects/status/t6p8w8pfvy2emlr9?svg=true)](https://ci.appveyor.com/project/fireflycons/aws-toolbox)


# Disclaimer

Ensure that you test operations from this module that make changes to your infrastructure are
well tested on a pre-production copy before you apply to any production resource!
I won't be held responsible if you blow up your production stacks.

# What this is
A module containing a collection of PowerShell scripts I've created to ease various tasks.

See the [Command Docs](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/aws-toolbox.md)

# How to Install

The module is published on the PowerShell Gallery and can be installed by following the instructions there.

Up until now, there were two versions of this module published, one for Windows PowerShell and another for PowerShell Core for Linux/Mac. From now on, there is only the one module which works on all platforms.

The module is now built on the modular [AWS.Tools](https://github.com/aws/aws-tools-for-powershell/issues/67), so if upgrading from an earler version you should remove `AWSPowerShell` and install `AWS.Tools`

## PowerShell (all platforms)
![PowerShell Gallery](https://img.shields.io/powershellgallery/v/aws-toolbox)

https://www.powershellgallery.com/packages/aws-toolbox


Some tools in this collection can provide visual difference comparisons on various things, currenrly CloudFormation templates
and stack resource drift. You should configure a diff viewer using `Set-ATConfigurationItem` first.

Currently supported diff viewers are git, WinMerge and Visual Studio Code. If you have a diff viewer you would like to see supported
then raise an issue in GitHub.

