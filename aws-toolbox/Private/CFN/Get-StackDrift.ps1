function Get-StackDrift
{
    param
    (
        [Amazon.CloudFormation.Model.Stack]$Stack
    )

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

    $status.StackDriftStatus
}