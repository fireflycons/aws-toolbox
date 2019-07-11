function Get-ATEC2SecurityGroupDependencies
{
<#
    .SYNOPSIS
        Find all dependencies of a given security group or groups.

    .DESCRIPTION
        You cannot delete a security group if it is in use anywhere.
        Usages come down to whether it is bound to any network interface (e.g. instance or laod balancer),
        or whether it is referenced as the target of a rule in another security group.

        This cmdlet enables you to determine what may be linked to the given security group so you can
        break those links prior to deleting it.

    .PARAMETER GroupId
        One or more security groups to obtain dependency information for

    .PARAMETER AsText
        If set, print a report to the console, else returns an object that can be used by a calling script.
        Where possible, if a dependency belongs to a cloudformation stack, then the owning stack name is shown in parentheses.

    .EXAMPLE
        Get-ATEC2SecurityGroupDependencies -GroupId sg-00000000 -AsText
        List dependencies of given group to console

    .EXAMPLE
        Get-ATEC2SecurityGroupDependencies -GroupId sg-00000000
        Return dependencies of given group as object

    .EXAMPLE
        (Get-ATEBEnvironmentResourceList my-eb-environment).Instances.SecurityGroups.SecurityGroupId | sort -Unique | Get-ATEC2SecurityGroupDependencies -AsText
        List dependencies of security groups attached to instances of an Elastic Beanstalk environment to console.

    .EXAMPLE
        (Get-ATEBEnvironmentResourceList my-eb-environment).LoadBalancers.SecurityGroups.SecurityGroupId | Get-ATEC2SecurityGroupDependencies -AsText
        List dependencies of security groups attached to load balancers of an Elastic Beanstalk environment to console.

    .NOTES
        IAM permissions required to run this command

        - ec2:DescribeSecurityGroups
        - ec2:DescribeTags
        - elasticloadbalancing:DescribeLoadBalancers
        - elasticloadbalancing:DescribeTags

    .INPUTS
        [string]
        Security Group ID(s)

    .OUTPUTS
        [object]
        Or nothing if -AsText
#>
    param
    (
        [Parameter(ValueFromPipeline, Position = 0)]
        [string[]]$GroupId,

        [switch]$AsText
    )

    begin
    {
        function Write-RuleReferences
        {
            param
            (
                [string]$ReferenceType,
                [object]$References
            )

            if ($null -eq $References)
            {
                Write-Host "- No $($ReferenceType.ToLower()) rule references"
            }
            else
            {
                Write-Host "- $($ReferenceType) rule references from:"

                $References |
                ForEach-Object {
                    Write-Host "  - $_"
                }
            }
        }

        function Get-ELBStack
        {
            param
            (
                [string]$ElbDescription
            )

            if ($ElbDescription -match '(ELB\s+)?\w+/(?<name>.*)?/')
            {
                $elbName = $matches.name

                try
                {
                    $elb = Get-ELB2LoadBalancer -Name $elbName
                }
                catch
                {
                    $elb = null
                }
            }
            elseif ($ElbDescription -match '(ELB\s+)?(?<name>.*)')
            {
                $elbName = $matches.name

                try
                {
                    $elb = Get-ELBLoadBalancer -LoadBalancerName $elbName
                }
                catch
                {
                    $elb = $null
                }
            }

            if ($null -eq $elb)
            {
                return 'Not a load balancer'
            }

            if ($elb -is [Amazon.ElasticLoadBalancing.Model.LoadBalancerDescription])
            {
                $tags = Get-ELBResourceTag -LoadBalancerName $elbName | Select-Object -ExpandProperty Tags

            }
            else
            {
                $tags = Get-ELB2Tag -ResourceArn $elb.LoadBalancerArn | Select-Object -ExpandProperty Tags
            }

            if ($null -eq $tags)
            {
                return '*NONE*'
            }

            $stack = $tags |
            Where-Object {
                $_.Key -eq 'aws:cloudformation:stack-name'
            } |
            Select-Object -ExpandProperty Value

            if ($stack)
            {
                return $stack
            }
            else
            {
                return '*NONE*'
            }
        }
    }

    process
    {
        $GroupId |
        Foreach-Object {

            $sgs = Get-SecurityGroupWithStack -GroupId $_

            if ($null -ne $sgs)
            {
                $sg = $sgs.SecurityGroupId

                $detail = New-Object PSObject -Property @{
                    SecurityGroup     = $sgs
                    NetworkInterfaces = Get-EC2NetworkInterface -Filter @{ Name = 'group-id'; Values = $sg }
                    IngressReferences = Get-EC2SecurityGroup -Filter @{ Name = 'ip-permission.group-id'; Values = $sg } |
                    Get-SecurityGroupWithStack |
                    Where-Object {
                        $_.SecurityGroupId -ne $sgs.SecurityGroupId
                    }
                    EgressReferences  = Get-EC2SecurityGroup -Filter @{ Name = 'egress.ip-permission.group-id'; Values = $sg } |
                    Get-SecurityGroupWithStack |
                    Where-Object {
                        $_.SecurityGroupId -ne $sgs.SecurityGroupId
                    }
                }

                if ($AsText)
                {
                    Write-Host "Dependencies for $sgs"
                    Write-Host "Attached to:"

                    if ($null -eq $detail.NetworkInterfaces)
                    {
                        Write-Host "- No network attachments"
                    }
                    else
                    {
                        $detail.NetworkInterfaces |
                        ForEach-Object {

                            if (-not [string]::IsNullOrEmpty($_.Attachment.InstanceId))
                            {
                                Write-Host "- Instance $($_.Attachment.InstanceId)"
                            }
                            elseif (-not [string]::IsNullOrEmpty($_.Description))
                            {
                                $elbStack = Get-ELBStack -ElbDescription $_.Description
                                Write-Host "- $($_.Description):$($_.AvailabilityZone) ($elbStack)"
                            }
                            else
                            {
                                Write-Host "- Unknown attachment"
                            }
                        }
                    }

                    Write-Host "Other security groups that reference this one:"
                    Write-RuleReferences -ReferenceType "Ingress" -References $detail.IngressReferences
                    Write-RuleReferences -ReferenceType "Egress" -References $detail.EgressReferences
                    Write-Host
                }
                else
                {
                    $detail
                }
            }
        }
    }

    end
    {

    }
}