# aws-toolbox

|Branch|Status|
|------|------|
|master|[![Build status](https://ci.appveyor.com/api/projects/status/t6p8w8pfvy2emlr9/branch/master?svg=true)](https://ci.appveyor.com/project/fireflycons/aws-toolbox/branch/master)|
|dev|[![Build status](https://ci.appveyor.com/api/projects/status/t6p8w8pfvy2emlr9/branch/dev?svg=true)](https://ci.appveyor.com/project/fireflycons/aws-toolbox/branch/dev)|

# Disclaimer

Ensure that you test operations from this module that make changes to your infrastructure are
well tested on a pre-production copy before you apply to any production resource!
I won't be held responsible if you blow up your production stacks.

# Installation

This module is published in the PowerShell Gallery for [Windows PowerShell](https://www.powershellgallery.com/packages?q=aws-toolbox) and [PowerShell Core/Linux](https://www.powershellgallery.com/packages?q=aws-toolbox.netcore)

Some tools in this collection can provide visual difference comparisons on various things, currenrly CloudFormation templates
and stack resource drift. You should configure a diff viewer using `Set-ATConfigurationItem` first.

Currently supported diff viewers are git, WinMerge and Visual Studio Code. If you have a diff viewer you would like to see supported
then raise an issue in GitHub.

# What this is
A module containing a collection of PowerShell scripts I've created to ease various tasks.

See the [Command Docs](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/aws-toolbox.md)
