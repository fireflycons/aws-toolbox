function Test-ATEC2IsRunningInEC2
{
    <#
    .SYNOPSIS
        Determine if this code is executing on an EC2 instance

    .DESCRIPTION
        Tests for executing on EC2 by trying to read EC2 instance metadata URL

    .OUTPUTS
        [boolean] - True if running on an EC2 instance.

    .EXAMPLE
        Test-ATEC2IsRunningInEC2
        Returns true if EC2; else false

    .NOTES
        The result of this call is cached in session variable AwsToolboxIsEC2 so subsequent calls to this function are faster.

    .LINK
        https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Test-ATEC2IsRunningInEC2.md
#>

    if (-not (Test-Path -Path variable:AwsToolboxIsEC2))
    {
        try
        {
            Invoke-RestMethod -Uri 'http://169.254.169.254/latest/meta-data/instance-id' | Out-Null
            Set-Variable -Name AwsToolboxIsEC2 -Value $true -Scope Global -Visibility Public
        }
        catch
        {
            Set-Variable -Name AwsToolboxIsEC2 -Value $false -Scope Global -Visibility Public
        }
    }

    return $AwsToolboxIsEC2
}
