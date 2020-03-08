function Get-ATEC2LatestAMI
{
    <#
    .SYNOPSIS
        Build a CloudFormation mapping for the latest version of an AMI in all accessible regions.

    .DESCRIPTION
        Given an AMI search filter, the script enumerates all known regions looking for the newest AMI that matches the criteria
        Depending on where you are and your account permissions, some regions will not return a value e.g. China and Gov Cloud.
        Ensure you have the latest version of AWS Tools if AWS has recently added new regions.

    .PARAMETER ImageName
        Name of image to search for (may include wildcards).

    .PARAMETER Filter
        Filter in Amazon filter syntax to more accurately specify an image to search for.

    .PARAMETER MappingName
        Name of the mapping to generate.

    .OUTPUTS
        A hashtable of hashtables which can be piped to ConvertTo-Json to get a block of code that can be pasted into a CF template.
        If you have installed a YAML converter like https://github.com/cloudbase/powershell-yaml, then the output can also be piped to ConvertTo-Yaml.
        Or you can use the result object itself in some other process.

    .NOTES
        IAM permissions required to run this command
        - ec2:DescribeImages

    .EXAMPLE
        Get-LatestAMI -ImageName 'amzn-ami-vpc-nat-hvm*' -MappingName 'NatAMI' | ConvertTo-Json
        Gets the latest Amazon Linux NAT instance AMIs.

    .EXAMPLE
        Get-LatestAMI -Filter @{'Name' = 'name'; Values = 'amzn-ami-vpc-nat-hvm*'} -MappingName 'NatAMI' | ConvertTo-Json
        Gets the latest Amazon Linux NAT instance AMIs using a filter expression.

    .LINK
        https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Get-ATEC2LatestAMI.md
#>
    param
    (
        [Parameter(ParameterSetName = 'ByName', Mandatory = $true)]
        [string]$ImageName,

        [Parameter(ParameterSetName = 'ByFilter', Mandatory = $true)]
        $Filter,

        [Parameter(Mandatory = $true)]
        [string]$MappingName
    )

    if ($PSCmdLet.ParameterSetName -ieq 'ByName')
    {
        # Set a filter from the user supplied name
        $Filter = @(
            @{'Name' = 'name'; Values = $ImageName}
        )
    }

    # Create hashtable for results. Key: Region name, Value = AMI definition
    $regionsHash = @{}

    # Iterate all regions. Ensure you have latest AWSPowerShell installed to cover any new regions.
    [Amazon.RegionEndpoint]::EnumerableAllRegions.SystemName |
        ForEach-Object {

        $region = $_
        Write-Host -NoNewLine "$region ... "

        try
        {
            # Get newest AMI matching filter condition for this region
            $ami = Get-EC2Image -Filter $Filter -Region $region | Sort-Object CreationDate -Descending | Select-Object -First 1

            if ($ami)
            {
                # Add the found AMI to the regions hash
                $regionsHash.Add($region, @{'AMI' = $ami.ImageId })
                Write-Host -ForegroundColor Green "$($ami.ImageId) ($($ami.Name))"
            }
            else
            {
                # Nothing found matching filters
                Write-Host -ForegroundColor Yellow "No match"
            }
        }
        catch
        {
            # Most likely this is a region to which your account doesn't have access, e.g. GovCloud.
            Write-Host -ForegroundColor Red $_.Exception.Message
        }
    }

    # Wrap up with the mapping name and emit result
    @{$MappingName = $regionsHash }
}