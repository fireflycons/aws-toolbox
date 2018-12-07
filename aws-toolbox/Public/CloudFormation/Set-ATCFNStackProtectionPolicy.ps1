function Set-ATCFNStackProtectionPolicy
{
<#
    .SYNOPSIS
        Set or remove stack policy to prevent replacement or deletion of resources

    .DESCRIPTION
        WARNING - This command modifies resources. Test properly in stacks that you don't mind breaking before running in a prod environment.

        WARNING - Setting policy on the objects within the nested stack does NOT prevent the nested stack being deleted by its parent.

        This is a fairly simple utility to protect/unprotect all resources within a stack
        such that you can prevent accidental deletions or replacements which would interrupt service.

        Policy for entire nested stacks is REPLACED by this script, so only use it if you want to set blanket policy
        Don't use it if you want finer-grained policies.

        If the stack being processed is a nested stack, policy is set in the parent stack to prevent delete/replace operations.
        Parent stack policy is additive, i.e. other policies are not replaced.
        Attempts to remove one of the nested stacks will result in an error during changeset calculation and thus prevent nested stack deletion.

    .PARAMETER Stack
        One or more stacks by name, or as stack objects (output of Get-CFNStack)
        This parameter accepts pipeline input

    .PARAMETER Action
        Action to perform for all resources within the given stacks

    .PARAMETER PassThru
        If set, ARNS of all stacks that were changed are emitted.

    .PARAMETER Force
        If set, do not abort if any of the stacks in scope are updating. Policy will be set on those which are not updating only.
        Probably not what you want, but you can re-run the command once all stacks are stable.

    .EXAMPLE
        Get-CFNStack | Where-Object { $_.StackName -like 'MyStack-MyNestedStack*' } | Set-ATCFNStackProtectionPolicy -Action Protect
        Protect all resources in all stacks with names beginning with MyStack-MyNestedStack

    .NOTES
        IAM permissions required to run this command
        - cloudformation:DescribeStacks
        - cloudformation:DescribeStackResources
        - cloudformation:GetStackPolicy
        - cloudformation:SetStackPolicy

    .INPUTS
        [string] - Stack Name
        [Amazon.CloudFormation.Model.Stack] - Stack object

    .OUTPUTS
        [string]
        ARNs of stacks that were successfully updated

        Or none, if -PassThru not specified.

    .LINK
        https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackProtectionPolicy.md
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [object[]]$Stack,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Protect', 'Unprotect')]
        [string]$Action,

        [switch]$Force,

        [switch]$PassThru
    )

    begin
    {
        $ErrorActionPreference = 'Stop'

        #region Local Functions

        function New-PolicyObject
        {
            <#
            .SYNOPSIS
                Create a single policy stanza - Effect/Action/Principal/Resource
        #>
            param
            (
                [ValidateSet('Allow', 'Deny')]
                [string]$Effect,
                [string]$Action,
                [string]$Resource
            )

            New-Object PSObject -Property @{
                Effect    = $Effect
                Action    = $Action
                Principal = '*'
                Resource  = $Resource
            }
        }

        function New-NestedStackPolicy
        {
            <#
            .SYNOPSIS
                Create a replacement stack policy
        #>
            param
            (
                [ValidateSet('Allow', 'Deny')]
                [string]$Effect,
                [string]$Resource = '*'
            )

            $policy = New-Object PSObject -Property @{
                Statement = @(
                    New-PolicyObject -Effect Allow -Action 'Update:*' -Resource $Resource
                )
            }

            if ($Effect -ieq 'Deny')
            {
                $policy.Statement += @(
                    New-PolicyObject -Effect Deny -Action 'Update:Replace' -Resource $Resource
                    New-PolicyObject -Effect Deny -Action 'Update:Delete' -Resource $Resource
                )
            }

            $policy
        }

        #endregion

        # Map command line arg value to effect value
        $policyEffect = @{
            Protect   = 'Deny'
            Unprotect = 'Allow'
        }

        # Where to build list of policies to apply.
        $policyList = @{}

        # Stable stack states. Can't apply policy if a stack is not in one of these states
        $stableStates = @(
            'CREATE_COMPLETE'
            'ROLLBACK_COMPLETE'
            'UPDATE_COMPLETE'
            'UPDATE_ROLLBACK_COMPLETE'
        )

        # Store parent stack states so we don't have to keep calling Get-CFNStack on the same stack
        $parentStackStates = @{}

        # Record any exception for later.
        $exception = $null
    }

    process
    {
        if (-not $exception)
        {
            try
            {
                foreach ($s in $Stack)
                {
                    if ($s -is [string])
                    {
                        # Stack by name
                        $thisStack = Get-CFNStack -StackName $s
                    }
                    else
                    {
                        # Stack by object
                        $thisStack = $s
                    }

                    $thisStackId = $thisStack.StackId
                    $parentStackId = $thisStack.ParentId
                    $thisStackName = $thisStack.StackName

                    # Check stack is stable
                    if ($thisStack.StackStatus.Value -eq 'DELETE_COMPLETE')
                    {
                        # If it's deleted, warn and ignore - continue to next stack
                        Write-Warning "Stack $thisStackName has been deleted."
                        continue
                    }

                    if (-not [string]::IsNullOrEmpty($parentStackId) -and -not ($Force -or $parentStackStates.ContainsKey($parentStackId)))
                    {
                        $parentStack = Get-CFNStack -StackName $parentStackId

                        if ($stableStates -inotcontains $parentStack.StackStatus.Value)
                        {
                            throw "Cannot continue: Stack $($parentStack.StackName), parent of $thisStackName is currently $($parentStack.StackStatus.Value)"
                        }

                        $parentStackStates.Add($parentStackId, $parentStack.StackStatus.Value)
                    }

                    if ($stableStates -inotcontains $thisStack.StackStatus.Value -and -not $Force)
                    {
                        throw "Cannot continue: Stack $thisStackName is currently $($thisStack.StackStatus.Value)"
                    }

                    Write-Verbose "$($Action)ing stack $thisStackName"

                    # Create replacement policy
                    $stackPolicy = New-NestedStackPolicy -Effect $policyEffect[$Action]

                    # Add to list for processing at the end
                    $policyList.Add($thisStackId, $stackPolicy)

                    if (-not [string]::IsNullOrEmpty($parentStackId))
                    {
                        # Protect the nested stacks from deletion by the parent.
                        # This gives a messy failure, but it is nevertheless a failure!
                        # Error validating existing stack policy: Unknown logical id 'LogicalResourceId/MyNestedStack' in statement {} - stack policies can only be applied to logical ids referenced in the template

                        # Get the current parent stack policy
                        $parentPolicy = $(
                            if ($policyList.ContainsKey($parentStackId))
                            {
                                $policyList[$parentStackId]
                            }
                            else
                            {
                                Get-CFNStackPolicy -StackName $parentStackId | ConvertFrom-Json
                            }
                        )

                        # Get logical resource name for the nested stack
                        $logicalResourceId = Get-CFNStackResourceSummary -StackName $parentStackId |
                            Where-Object {
                            $_.PhysicalResourceId -eq $thisStackId
                        } |
                            Select-Object -ExpandProperty LogicalResourceId |
                            ForEach-Object {
                            "LogicalResourceId/$_"
                        }

                        switch ($action)
                        {
                            'Unprotect'
                            {
                                if ($null -eq $parentPolicy)
                                {
                                    # Nothing to do - policy never created on the parent stack
                                    continue
                                }

                                # Filter out policy stanzas for this nested stack
                                $parentPolicy.Statement = $parentPolicy.Statement |
                                    Where-Object {
                                    $_.Resource -ine $logicalResourceId
                                }

                                # Since policy cannot be completely removed, we need to add a blanket allow
                                if (($parentPolicy.Statement | Measure-Object).Count -eq 0)
                                {
                                    $parentPolicy.Statement = @(
                                        New-PolicyObject -Effect Allow -Action 'Update:*' -Resource '*'
                                    )
                                }
                            }

                            'Protect'
                            {
                                if ($null -eq $parentPolicy)
                                {
                                    # Create new policy with default allow all
                                    $parentPolicy = New-Object PSObject -Property @{
                                        Statement = @(
                                            New-PolicyObject -Effect Allow -Action 'Update:*' -Resource '*'
                                        )
                                    }
                                }

                                # Filter out policy stanzas for this nested stack
                                $parentPolicy.Statement = $parentPolicy.Statement |
                                    Where-Object {
                                    $_.Resource -ine $logicalResourceId
                                }

                                $newStanzas = @(
                                    New-PolicyObject -Effect Deny -Action 'Update:Replace' -Resource $logicalResourceId
                                    New-PolicyObject -Effect Deny -Action 'Update:Delete' -Resource $logicalResourceId
                                )

                                if (($parentPolicy.Statement | Measure-Object).Count -eq 0)
                                {
                                    $parentPolicy.Statement = $newStanzas
                                }
                                else
                                {
                                    [array]$parentPolicy.Statement += $newStanzas
                                }
                            }
                        }

                        $policyList[$parentStackId] = $parentPolicy
                    }
                }
            }
            catch
            {
                # If we re-throw here and stuff is still coming through the pipeline
                # then the pipe may continue and an exception will be thrown at each iteration.
                $exception = $_
            }
        }
    }

    end
    {
        # If we caught an exception during the pipeline processing, throw it now
        if ($exception)
        {
            throw $exception.Exception
        }

        # Apply the policy changes
        # We only get here if all stacks are OK, or some were updating and -Force was specified
        $policyList.Keys |
            ForEach-Object {

            $stackId = $_
            $stackName = $(
                $stackId -match 'stack/([\w\-]+)/' | Out-Null
                $Matches.1
            )

            $stackPolicy = $policyList[$stackId]
            Write-Verbose "Applying policy to $stackName"

            try
            {
                Set-CFNStackPolicy -StackName $stackId -StackPolicyBody ($stackPolicy | ConvertTo-Json) -Force

                if ($PassThru)
                {
                    # Emit stack ARN
                    $stackId
                }
            }
            catch
            {
                if ($_.Exception.Message -imatch 'SetStackPolicy cannot be called when stack is in the (?<state>\w+) state')
                {
                    Write-Warning "Stack $stackName ignored due to $($Matches.state) and -Force was present."
                }
                else
                {
                    throw
                }
            }
        }
    }
}