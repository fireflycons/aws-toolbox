function Set-ATCFNStackDeletionPolicy
{
<#
    .SYNOPSIS
        Set or remove stack policy to prevent replacement or deletion of resources

    .DESCRIPTION
        WARNING - Setting policy on the objects within the nested stack does NOT prevent the nested stack being deleted by its parent!

        This is a fairly simple utility to protect/unprotect all resources within a stack
        such that you can prevent accidental deletions or replacements which would interrupt service.

        Policy for the entire stack is REPLACED by this script, so only use it if you want to set blanket policy
        Don't use it if you want finer-grained policies.

        If the stack being processed is a nested stack, policy is set in the parent stack to prevent delete/replace operations.
        Attempts to remove one of the nested stacks will result in an error during changeset calculation and thus prevent nested stack deletion.

    .PARAMETER Stack
        One or more stacks by name, or as stack objects (output of Get-CFNStack)
        This parameter accepts pipeline input

    .PARAMETER Action
        Action to perform for all resources within the given stacks

    .EXAMPLE
        Get-CFNStack | Where-Object { $_.StackName -like 'MyStack-MyNestedStack*' } | Set-ATCFNStackDeletionPolicy -Action Protect
        Protect all resources in all stacks with names beginning with MyStack-MyNestedStack

    .NOTES
        IAM permissions required to run this command
        - cloudformation:DescribeStacks
        - cloudformation:DescribeStackResources
        - cloudformation:GetStackPolicy
        - cloudformation:SetStackPolicy

    .LINK
        https://github.com/fireflycons/aws-toolbox/tree/master/docs/en-US/Set-ATCFNStackDeletionPolicy.md
#>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [object[]]$Stack,

        [Parameter(Mandatory = $true)]
        [ValidateSet('Protect', 'Unprotect')]
        [string]$Action
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

        # Wehre to build list of policies to apply.
        $policyList = @{}
    }

    process
    {
        try
        {
            foreach ($s in $Stack)
            {
                if ($s -is [string])
                {
                    # Stack by name
                    $cfStack = Get-CFNStack -StackName $s
                    $thisStackId = $cfStack.StackId
                    $parentStackId = $cfStack.ParentId
                    $thisStackName = $s
                }
                else
                {
                    # Stack by object
                    $thisStackId = $s.StackId
                    $parentStackId = $s.ParentId
                    $thisStackName = $s.StackName
                }

                Write-Host "$($Action)ing stack $thisStackName"

                # Create replacement policy
                $stackPolicy = New-NestedStackPolicy -Effect $policyEffect[$Action]

                # Add to list for processing at the end
                $policyList.Add($thisStackId, $stackPolicy)

                if (-not [string]::IsNullOrEmpty($parentStackId))
                {
                    # Protect the nested stacks from deletion.
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
            $_.ScriptStackTrace
            throw
        }
    }

    end
    {
        # Apply the policy changes
        $policyList.Keys |
            ForEach-Object {

            $stackId = $_
            $stackName = $(
                $stackId -match 'stack/([\w\-]+)/' | Out-Null
                $Matches.1
            )

            $stackPolicy = $policyList[$stackId]
            Write-Host "Applying policy to $stackName"
            Set-CFNStackPolicy -StackName $stackId -StackPolicyBody ($stackPolicy | ConvertTo-Json) -Force
        }
    }
}