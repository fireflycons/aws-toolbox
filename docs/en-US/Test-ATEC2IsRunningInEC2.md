---
external help file: aws-toolbox-help.xml
Module Name: aws-toolbox
online version: https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Test-ATEC2IsRunningInEC2.md
schema: 2.0.0
---

# Test-ATEC2IsRunningInEC2

## SYNOPSIS
Determine if this code is executing on an EC2 instance

## SYNTAX

```
Test-ATEC2IsRunningInEC2
```

## DESCRIPTION
Tests for executing on EC2 by trying to read EC2 instance metadata URL

## EXAMPLES

### EXAMPLE 1
```
Test-ATEC2IsRunningInEC2
```

Returns true if EC2; else false

## PARAMETERS

## INPUTS

## OUTPUTS

### [boolean] - True if running on an EC2 instance.
## NOTES
The result of this call is cached in session variable AwsToolboxIsEC2 so subsequent calls to this function are faster.

## RELATED LINKS

[https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Test-ATEC2IsRunningInEC2.md](https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Test-ATEC2IsRunningInEC2.md)

