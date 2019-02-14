<#
    .SYNOPSIS
        Compare a template file with what is currently deployed in CloudFormation.

    .DESCRIPTION
        This function will display any current drift report, but will additionally
        compare a CloudFormation template file with what is currently deployed in the target stack.
        This will show changes that cannot be picked up simply by drift reporting, e.g. a property
        that has been changed from a literal value to an expression (e.g. Ref, Fn::If). Where these
        evaluate to the same value as the original literal, this is not reported by drift.

        If running on Windows, this function will look for WinMerge to display the differences, else
        it will fall back to git diff, which is the default on non-windows systems.

    .PARAMETER StackName
        Name or ARN of an existing CloudFormation Stack

    .PARAMETER TemplateFilePath
        Path on disk to a CloudFormation template to compare to the stack

    .PARAMETER TemplateUri
        URI of a template stored in S3 to compare to the stack

    .LINK
        http://winmerge.org/
#>
function Compare-ATDeployedStackWithSourceTemplate
{
    param
    (
        [string]$StackName,

        [Parameter(ParameterSetName='FromFile')]
        [string]$TemplateFilePath,

        [Parameter(ParameterSetName='FromS3')]
        [string]$TemplateUri
    )

    $tempStackTemplateFile = Join-Path $env:TEMP ([Guid]::NewGuid().ToString() + ".cftemplate.json")
    try
    {
        $stack = Get-CFNStack -StackName $StackName
        $currentStackTemplate = Get-CFNTemplate -StackName $stack.StackId

        if ($stack.PSObject.Properties.Name -icontains 'DriftInformation')
        {
            if ($stack.DriftInformation.StackDriftStatus -ieq 'DRIFTED')
            {
                Write-Warning "Stack has drifed, last check: $($stack.DriftInformation.LastCheckTimestamp)"
                Write-Host (
                    Get-CFNDetectedStackResourceDrift -StackName $stack.StackId -StackResourceDriftStatusFilter @('DELETED', 'MODIFIED') |
                    Select-Object StackResourceDriftStatus, LogicalResourceId |
                    Out-String
                )
            }
            else
            {
                Write-Host "Stack drift: ($stack.DriftInformation.StackDriftStatus)"
            }
        }
        else
        {
            Write-Warning 'Upgrade your version of AWSPowerShell to see drift information'
        }

        $diffTool = New-DiffTool

        if (-not $diffTool)
        {
            throw "Cannot find a suitable tool to show differences"
        }

        $currentStackTemplate | Out-File -FilePath $tempStackTemplateFile

        $stackName = "$(Get-IAMAccountAlias) - $($stack.StackId)"

        switch ($PSCmdlet.ParameterSetName)
        {
            'FromFile' {

                $diffTool.Invoke($TemplateFilePath, $tempStackTemplateFile, $TemplateFilePath, $stack.StackId)
            }
        }
    }
    catch
    {
        Write-Host $_.Exception.Message
    }
    finally
    {
        if (Test-Path -Path $tempStackTemplateFile)
        {
            Remove-Item -Path $tempStackTemplateFile
        }
    }
}