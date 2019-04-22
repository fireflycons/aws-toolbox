<#
    .SYNOPSIS
        Compare a template file with what is currently deployed in CloudFormation.
        Also report stack drift (items that have been updated by other means since last CloudFormation stack update).

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

    .PARAMETER WaitForDiff
        If a GUI diff tool is used to compare templates and this is set,
        then the function does not return until the diff tool has been closed.
        If not set, then the temp file used to store AWS's view of the template is not cleaned up.

    .EXAMPLE
        Compare-ATDeployedStackWithSourceTemplate -StackName my-stack -TemplateFilePath .\my-stack.json -WaitForDiff
        Runs drift detection, then compares the text of my-stack.json with the current template stored with my-stack in CloudFormation.  Waits for you to close the diff tool.

    .EXAMPLE
        Compare-ATDeployedStackWithSourceTemplate -StackName my-stack -TemplateURI https://s3-eu-west-1.amazonaws.com/my-bucket/my-stack.json -WaitForDiff
        Runs drift detection, then compares the text of my-stack.json located in S3 with the current template stored with my-stack in CloudFormation.  Waits for you to close the diff tool.

    .LINK
        http://winmerge.org/
#>
function Compare-ATDeployedStackWithSourceTemplate
{
    param
    (
        [string]$StackName,

        [Parameter(ParameterSetName = 'FromFile')]
        [string]$TemplateFilePath,

        [Parameter(ParameterSetName = 'FromS3')]
        [string]$TemplateUri,

        [switch]$WaitForDiff
    )

    try
    {
        $stack = Get-CFNStack -StackName $StackName

        # Detect last CF update
        $event = Get-CFNStackEvent -StackName $stack.StackId | Select-Object -First 1

        Write-Host "Last CloudFormation Update: $($event.Timestamp.ToString('dd MMM yyyy, HH:mm:ss'))"

        if ($null -ne (Get-Command -Name Start-CFNStackDriftDetection -ErrorAction SilentlyContinue))
        {
            # Initiate drift detection
            Write-Host "Initiating drift detection"
            $detectionId = Start-CFNStackDriftDetection -StackName $stack.StackId

            # Wait for it to complete
            $status = New-Object Amazon.CloudFormation.Model.DescribeStackDriftDetectionStatusResponse
            $status.DetectionStatus = 'DETECTION_IN_PROGRESS'

            while ($status.DetectionStatus -eq 'DETECTION_IN_PROGRESS')
            {
                Start-Sleep -Seconds 1
                $status = Get-CFNStackDriftDetectionStatus -StackDriftDetectionId $detectionId
            }


            if ($status.StackDriftStatus -eq 'DRIFTED')
            {
                Write-Warning "Stack has drifted..."
                Write-Host (
                    Get-CFNDetectedStackResourceDrift -StackName $stack.StackId -StackResourceDriftStatusFilter @('DELETED', 'MODIFIED') |
                        Select-Object StackResourceDriftStatus, LogicalResourceId |
                        Out-String
                )
            }
            else
            {
                Write-Host "Stack drift: $($status.StackDriftStatus)"
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

        # Write AWS view of template to temp file
        $tmpDir = Join-Path ([IO.Path]::GetTempPath()) 'TempCloudFormation'

        if (-not (Test-Path -Path $tmpDir -PathType Container))
        {
            # Create a tmp folder for downloaded cloudformation templates
            # Makes it easier to spot and clean up.
            New-Item -Path $tmpDir -ItemType Directory | Out-Null
        }

        $uniqueId = [Guid]::NewGuid().ToString()
        $awsStackTemplateFile = Join-Path $tmpDir ($uniqueId + ".cftemplate.json")
        $uriTemplateFile = Join-Path $tmpDir ($uniqueId + ".uritemplate.json")

        switch ($PSCmdlet.ParameterSetName)
        {
            'FromFile'
            {

                # Try to write the temp file with the same encoding as the template on file system, so as not to confuse git diff
                $encoding = Get-FileEncoding -Path $TemplateFilePath
                [IO.File]::WriteAllText($awsStackTemplateFile, (Get-CFNTemplate -StackName $stack.StackId), $encoding)

                $diffTool.Invoke($TemplateFilePath, $awsStackTemplateFile, $TemplateFilePath, $stack.StackId, [bool]$WaitForDiff)
            }

            'FromS3'
            {

                # Break up the URL. Need to get from S3 via API, as URL is probably protected.
                $uri = [Uri]$TemplateUri
                $bucketName = ($uri.Segments | Select-Object -Skip 1 -First 1).Trim('/')
                $key = ($uri.Segments | Select-Object -Skip 2) -join [string]::Empty
                Read-S3Object -BucketName $bucketName -Key $key -File $uriTemplateFile | Out-Null

                # Try to write the temp file with the same encoding as the downloaded URI template, so as not to confuse git diff
                $encoding = Get-FileEncoding -Path $uriTemplateFile
                [IO.File]::WriteAllText($awsStackTemplateFile, (Get-CFNTemplate -StackName $stack.StackId), $encoding)

                $diffTool.Invoke($uriTemplateFile, $awsStackTemplateFile, $TemplateUri, $stack.StackId, [bool]$WaitForDiff)
            }
        }
    }
    catch
    {
        Write-Host $_.Exception.Message
    }
    finally
    {
        ($awsStackTemplateFile, $uriTemplateFile) |
            Where-Object {
            $null -ne $_ -and (Test-Path -Path $_)
        } |
            Foreach-Object {

            # Delete temp file if diff tool is GUI and we waited for it, or if diff tool is not GUI (ran synchronously)
            if (($diffTool.IsGui -and $WaitForDiff) -or -not $diffTool.IsGui)
            {
                Remove-Item $_
            }
            else
            {
                Write-Warning "Not deleting temporary file: $_"
            }
        }
    }
}