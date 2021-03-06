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
        Write-Warning "Environment not found"
        return
    }

    $allEnvs = $env |
        Where-Object {
            ('Launching', 'Updating', 'Ready') -icontains $_.Status
        } |
        ForEach-Object {

        $thisEnvironmentId = $_.EnvironmentId
        Write-Verbose $_.EnvironmentName
        Write-Verbose "- Reading resource list"

        # Name of stack created by Elastic Beanstalk
        $ebStackName = "awseb-$thisEnvironmentId-stack"
        $resources = Get-EBEnvironmentResource -EnvironmentId $thisEnvironmentId
        $launchConfigurationNames = $resources.LaunchConfigurations.Name

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

        if ($_.Status -ieq 'Updating' -and $null -ne $_.HealthStatus)
        {
            # Look for additional autoscaling group created during immutable deployment
            # Don't need to check if HealthStatus is null, as immutable implies enhanced health enabled.

            Write-Verbose "- Looking for immutable deployment resources (update in progress)"
            $additionalAsgs = Get-ASAutoScalingGroup |
            Where-Object {
                $_.AutoScalingGroupName -like "awseb-$thisEnvironmentId-immutable-stack*"
            } |
            Select-Object AutoScalingGroupName, Instances, LaunchConfigurationName

            if ($additionalAsgs)
            {
                # Add the ASG
                $envData.AutoScalingGroups = Invoke-Command {
                    $resources.AutoScalingGroups.Name
                    $additionalAsgs.AutoScalingGroupName
                } |
                Where-Object {
                    $null -ne $_
                }

                # Add this ASG's instances
                if (($additionalAsgs.Instances | Measure-Object).Count -gt 0)
                {
                    $envData.Instances.InstanceId = Invoke-Command {
                        $resources.Instances.Id
                        $additionalAsgs.Instances.InstanceId
                    } |
                    Where-Object {
                        $null -ne $_
                    }
                }

                # ...and launch configurations
                if (($additionalAsgs.LaunchConfigurationName | Measure-Object).Count -gt 0)
                {
                    $launchConfigurationNames = Invoke-Command {
                        $launchConfigurationNames
                        $additionalAsgs.LaunchConfigurationName
                    } |
                    Where-Object {
                        $null -ne $_
                    }
                }
            }
        }

        # Find instance security groups
        Write-Verbose "- Getting instance security groups"
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
            Write-Verbose "- Getting load balancer details"
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

        if (($launchConfigurationNames | Measure-Object).Count -gt 0)
        {
            Write-Verbose "- Getting launch configuration details"
            # Get launch configurations and data of interest
            $envData.LaunchConfigurations += $launchConfigurationNames |
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