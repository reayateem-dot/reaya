$ErrorActionPreference = 'Stop'

$region = 'eu-north-1'
$profile = 'reaya'
$stackName = 'reaya-bedrock-assistant'
$backendDirectory = $PSScriptRoot
$repositoryRoot = Split-Path $backendDirectory -Parent
$awsCommand = Get-Command aws.exe -ErrorAction SilentlyContinue
if ($awsCommand) {
    $awsPath = $awsCommand.Source
} else {
    $awsPath = Join-Path $env:LOCALAPPDATA 'Programs\Amazon\AWSCLIV2\aws.exe'
}

if (-not (Test-Path $awsPath)) {
    throw 'AWS CLI v2 was not found. Install AWS CLI v2 before deploying.'
}
if (-not (Test-Path (Join-Path $backendDirectory 'node_modules\@aws-sdk\client-bedrock-runtime'))) {
    throw 'Backend dependencies are missing. Run npm install in aws-backend first.'
}

function Invoke-AwsCli {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $output = & $awsPath @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "AWS CLI command failed: aws $($Arguments -join ' ')"
    }
    return $output
}

$accountId = (Invoke-AwsCli -Arguments @(
    'sts', 'get-caller-identity',
    '--query', 'Account',
    '--output', 'text',
    '--profile', $profile,
    '--region', $region
) | Select-Object -Last 1).Trim()

if ($accountId -notmatch '^\d{12}$') {
    throw 'AWS CLI did not return a valid account ID for the reaya profile.'
}

$bucketFile = Join-Path $backendDirectory '.deployment-bucket.txt'
if (Test-Path $bucketFile) {
    $bucketName = (Get-Content -Raw $bucketFile).Trim()
} else {
    $suffix = [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $bucketName = "reaya-bedrock-deploy-$accountId-$suffix"
}

if ($bucketName -notmatch '^reaya-bedrock-deploy-\d{12}-[a-f0-9]{8}$') {
    throw 'The saved deployment bucket name is invalid.'
}

$headArguments = @(
    's3api', 'head-bucket',
    '--bucket', $bucketName,
    '--profile', $profile,
    '--region', $region
)
& $awsPath @headArguments 2>$null | Out-Null
$headBucketExitCode = $LASTEXITCODE
if ($headBucketExitCode -ne 0) {
    Invoke-AwsCli -Arguments @(
        's3api', 'create-bucket',
        '--bucket', $bucketName,
        '--create-bucket-configuration', "LocationConstraint=$region",
        '--profile', $profile,
        '--region', $region
    ) | Out-Null
    Set-Content -Path $bucketFile -Value $bucketName -NoNewline
}

Invoke-AwsCli -Arguments @(
    's3api', 'put-public-access-block',
    '--bucket', $bucketName,
    '--public-access-block-configuration',
    'BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true',
    '--profile', $profile,
    '--region', $region
) | Out-Null

Invoke-AwsCli -Arguments @(
    's3api', 'put-bucket-encryption',
    '--bucket', $bucketName,
    '--server-side-encryption-configuration',
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}',
    '--profile', $profile,
    '--region', $region
) | Out-Null

Invoke-AwsCli -Arguments @(
    's3api', 'put-bucket-lifecycle-configuration',
    '--bucket', $bucketName,
    '--lifecycle-configuration',
    '{"Rules":[{"ID":"ExpireAssistantPackages","Status":"Enabled","Filter":{"Prefix":"assistant/"},"Expiration":{"Days":30}}]}',
    '--profile', $profile,
    '--region', $region
) | Out-Null

$stagingDirectory = Join-Path $env:TEMP ("reaya-bedrock-package-" + [Guid]::NewGuid().ToString('N'))
$archivePath = "$stagingDirectory.zip"

try {
    New-Item -ItemType Directory -Path $stagingDirectory | Out-Null
    Copy-Item (Join-Path $backendDirectory 'src\index.js') $stagingDirectory
    Copy-Item (Join-Path $backendDirectory 'package.json') $stagingDirectory
    Copy-Item (Join-Path $backendDirectory 'node_modules') $stagingDirectory -Recurse
    Compress-Archive -Path (Join-Path $stagingDirectory '*') -DestinationPath $archivePath -CompressionLevel Optimal

    $contentHash = (Get-FileHash -Path $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    $objectKey = "assistant/$contentHash.zip"
    $objectUri = "s3://$bucketName/$objectKey"

    Invoke-AwsCli -Arguments @(
        's3', 'cp', $archivePath, $objectUri,
        '--only-show-errors',
        '--profile', $profile,
        '--region', $region
    ) | Out-Null

    Invoke-AwsCli -Arguments @(
        'cloudformation', 'deploy',
        '--template-file', (Join-Path $backendDirectory 'template.yaml'),
        '--stack-name', $stackName,
        '--capabilities', 'CAPABILITY_NAMED_IAM',
        '--parameter-overrides', "CodeBucket=$bucketName", "CodeKey=$objectKey",
        '--no-fail-on-empty-changeset',
        '--profile', $profile,
        '--region', $region
    ) | Out-Null

    $apiUrl = (Invoke-AwsCli -Arguments @(
        'cloudformation', 'describe-stacks',
        '--stack-name', $stackName,
        '--query', "Stacks[0].Outputs[?OutputKey=='AssistantApiUrl'].OutputValue | [0]",
        '--output', 'text',
        '--profile', $profile,
        '--region', $region
    ) | Select-Object -Last 1).Trim()

    if ($apiUrl -notmatch '^https://[a-z0-9]+\.execute-api\.eu-north-1\.amazonaws\.com/api/chat$') {
        throw 'The deployment completed but did not return a valid eu-north-1 API URL.'
    }

    Write-Output "Assistant API: $apiUrl"
} finally {
    if (Test-Path $archivePath) {
        Remove-Item -LiteralPath $archivePath -Force
    }
    if (Test-Path $stagingDirectory) {
        Remove-Item -LiteralPath $stagingDirectory -Recurse -Force
    }
}
