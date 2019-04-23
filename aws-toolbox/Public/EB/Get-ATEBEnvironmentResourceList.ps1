function Get-ATEBEnvironmentResourceList
{
    <#
        .SYNOPSIS
            Gets a list of resources associated Elastic Beanstalk environents.

        .DESCRIPTION
            This command gets essential information about the resources in a beanstalk environment.
            Resource information is retured as an object by default so you can do further processing,
            however addition of -AsText switch instead prints out the information and the command returns nothing

        .PARAMETER EnvironmentId
            ID of an Elastic Beanstalk environment

        .PARAMETER EnvironmentName
            Name of an Elastic Beanstalk environment

        .PARAMETER ApplicationName
            Name of an Elastic Beanstalk application. All environments are returned.

        .PARAMETER AsText
            Print the environment information to the console instead of returning it as an object

        .EXAMPLE
            Get-ATEBEnvironmentResourceList -EnvironmentName production -AsText
            Lists the resources of the given environment to the console.

        .EXAMPLE
            Get-ATEBEnvironmentResourceList -EnvironmentId e-edxny3zkbp -AsText
            Lists the resources of the given environment to the console.

        .EXAMPLE
            Get-ATEBEnvironmentResourceList -ApplicationName MYApplication -AsText
            Lists the resources of all environments in the given EB application to the console.

        .EXAMPLE
            Invoke-ATSSMPowerShellScript -InstanceIds (Get-ATEBEnvironmentResourceList -EnvironmentName production).Instances.InstanceId -AsJson -ScriptBlock { Invoke-RestMethod http://localhost/status | ConvertTo-Json }
            Used in conjunction with Invoke-ATSSMPowerShellScript, send a command to all instances in the given Windows environment.

        .EXAMPLE
            Invoke-ATSSMShellScript -InstanceIds (Get-ATEBEnvironmentResourceList -EnvironmentName production).Instances.InstanceId -CommandText "ls -la /"
            Used in conjunction with Invoke-ATSSMShellScript, send a command to all instances in the given Linux environment.

        .OUTPUTS
            [PSObject[]] Information about each environment returned
            or nothing if -AsText specified.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Name')]
    param
    (
        [Parameter(ParameterSetName = 'Id')]
        [string]$EnvironmentId,

        [Parameter(ParameterSetName = 'Name', Position = 0)]
        [string]$EnvironmentName,

        [Parameter(ParameterSetName = 'App')]
        [string]$ApplicationName,

        [switch]$AsText
    )

    function Get-SecurityGroupWithStack
    {
        <#
            .SYNOPSIS
                Return security group ID with the name of the stack that created the group
                Helps us to spot default SGs created by EB
        #>
        param
        (
            [string[]]$GroupId
        )

        $GroupId |
            ForEach-Object {
            $sg = Get-EC2SecurityGroup -GroupId $_

            # Determine how it was created from tags
            $stackName = $sg.Tags |
                Where-Object {
                $_.Key -ieq 'aws:cloudformation:stack-name'
            } |
                Select-Object -ExpandProperty Value

            if (-not $stackName)
            {
                $stackName = '*NONE*'
            }

            New-Object PSObject -Property @{
                SecurityGroupId = $_
                OwningStack     = $stackName
            } |
                Add-Member -PassThru -MemberType ScriptMethod -Name ToString -Force -Value {
                "$($this.SecurityGroupId) ($($this.OwningStack))"
            }
        }
    }

    # Pass relevant arguments from function call to Get-EBEnvironment
    $envArgs = @{}

    $PSBoundParameters.Keys |
        Where-Object {
        ('EnvironmentId', 'EnvironmentName', 'ApplicationName') -icontains $_
    } |
        ForEach-Object {
        $envArgs.Add($_, $PSBoundParameters[$_])
    }

    $env = Get-EBEnvironment @envArgs

    if (-not $env)
    {
        Write-Host "Environment not found"
        return
    }

    $allEnvs = $env |
        Where-Object {
            ('Updating', 'Ready') -icontains $_.Status
        } |
        ForEach-Object {

        # Name of stack created by Elastic Beanstalk
        $ebStackName = "awseb-$($_.EnvironmentId)-stack"
        $resources = Get-EBEnvironmentResource -EnvironmentId $_.EnvironmentId

        # Create summary object
        $envData = New-Object PSObject -Property @{
            StackName            = $ebStackName
            ApplicationName      = $_.ApplicationName
            EnviromentName       = $_.EnvironmentName
            EnvironmentId        = $_.EnvironmentId
            RunningVersion       = $_.VersionLabel
            LastUpdated          = $_.DateUpdated
            Health               = $_.Health.Value
            Instances            = New-Object PSObject -Property @{
                InstanceId     = $resources.Instances.Id
                SecurityGroups = @()
            }
            LoadBalancers        = @()
            AutoScalingGroups    = $resources.AutoScalingGroups.Name
            LaunchConfigurations = @()
        }

        # Find instance security groups
        $reservation = Get-EC2Instance -Filter @{
            Name   = 'instance-id'
            Values = $resources.Instances.Id | Select-Object -First 1
        }

        if ($null -ne $reservation)
        {
            $instance = $reservation.Instances | Select-Object -First 1
            $envData.Instances.SecurityGroups = Get-SecurityGroupWithStack -GroupId $instance.SecurityGroups.GroupId
        }

        if (($resources.LoadBalancers | Measure-Object).Count -gt 0)
        {
            # Get load balancer(s) and associated security groups
            $envData.LoadBalancers = $resources.LoadBalancers.Name |
                ForEach-Object {

                try
                {
                    # Try classic load balancer
                    $elb = Get-ELBLoadBalancer -LoadBalancerName $_
                }
                catch
                {
                    # try application load balancer
                    $elb = $(
                        if ($_.Name -ilike 'arn:aws*')
                        {
                            Get-ELB2LoadBalancer -LoadBalancerArn $_
                        }
                        else
                        {
                            Get-ELB2LoadBalancer -Name $_
                        }
                    )
                }

                New-Object PSObject -Property @{
                    Name           = $elb.LoadBalancerName
                    SecurityGroups = Get-SecurityGroupWithStack -GroupId $elb.SecurityGroups
                }
            }
        }

        if (($resources.LaunchConfigurations | Measure-Object).Count -gt 0)
        {
            # Get launch configurations and data of interest
            $envData.LaunchConfigurations = $resources.LaunchConfigurations.Name |
                Foreach-Object {

                $lc = Get-ASLaunchConfiguration -LaunchConfigurationName $_
                New-Object PSObject -Property @{
                    Name         = $lc.LaunchConfigurationName
                    ImageId      = $lc.ImageId
                    InstanceType = $lc.InstanceType
                }
            }
        }

        $envData
    }

    if (-not $AsText)
    {
        return $allEnvs
    }

    $allEnvs |
        ForEach-Object {

        Write-Host "Application       : $($_.ApplicationName)"
        Write-Host "Environment       : $($_.EnviromentName) ($($_.EnvironmentId))"
        Write-Host "Health            : $($_.Health)"
        Write-Host "Running Version   : $($_.RunningVersion)"
        Write-Host "Stack Name        : $($_.StackName)"
        Write-Host "Last Updated      : $($_.LastUpdated.ToString('yyyy-MM-dd HH:mm:ss'))"
        Write-Host "AutoScaling Groups: $($_.AutoScalingGroups -join ', ')"
        Write-Host "Instances         :"
        Write-Host "    Instance IDs   : $($_.Instances.InstanceId -join ', ')"
        Write-Host "    Security Groups: $(($_.Instances.SecurityGroups | Foreach-Object { $_.ToString() }) -join ', ')"
        Write-Host "Launch Configurations:"
        $_.LaunchConfigurations |
            ForEach-Object {
            Write-Host "    Name         : $($_.Name)"
            Write-Host "    Image ID     : $($_.ImageId)"
            Write-Host "    Instance Type: $($_.InstanceType)"
        }
        Write-Host "Load Balancers    :"
        $_.LoadBalancers |
            ForEach-Object {
            Write-Host "    Name           : $($_.Name)"
            Write-Host "    Security Groups: $(($_.SecurityGroups | Foreach-Object { $_.ToString() }) -join ', ')"
        }

        Write-Host
    }
}