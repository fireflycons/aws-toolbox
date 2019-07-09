function Get-SecurityGroupWithStack
{
    <#
        .SYNOPSIS
            Return security group ID with the name of the stack that created the group
            Helps us to spot default SGs created by EB
    #>
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipelineByPropertyName)]
        [string[]]$GroupId
    )

    begin
    {}

    process
    {
        $GroupId |
        ForEach-Object {
            $sg = Get-EC2SecurityGroup -GroupId $_

            if ($null -ne $sg)
            {
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
    }

    end
    {}
}

