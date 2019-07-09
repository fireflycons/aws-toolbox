function Get-ATEC2SecurityGroupDependencies
{
    param
    (
        [Parameter(ValueFromPipeline)]
        [string[]]$GroupId,

        [switch]$AsText
    )

    begin
    {
        function Get-ENIDetails
        {
            [CmdletBinding()]
            param
            (
                [Parameter(ValueFromPipelineByPropertyName)]
                [string[]]$NetworkInterfaceId
            )

            begin
            { }

            process
            {
                $NetworkInterfaceId |
                Foreach-Object {
                    New-Object PSObject -Property @{
                        NetworkInterface = $_
                        Instance         = Get-EC2Instance -Filter @{ Name = 'network-interface.network-interface-id'; Values = $_ } |
                        Select-Object -ExpandProperty Instances |
                        Select-Object -ExpandProperty InstanceId
                    }
                }
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

                New-Object PSObject -Property @{
                    SecurityGroup     = $sgs
                    NetworkInterfaces = Get-EC2NetworkInterface -Filter @{ Name = 'group-id'; Values = $sg } |
                    Get-ENIDetails

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
            }
        }
    }

    end
    {

    }
}