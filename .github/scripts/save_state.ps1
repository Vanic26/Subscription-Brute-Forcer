$stateFile = "$env:GITHUB_WORKSPACE\last_runner_states.txt"

$mode = $env:INPUT_MODE
$fullUrl = $env:INPUT_FULL_URL
$baseUrl = $env:INPUT_BASE_URL
$charCount = $env:INPUT_CHARCOUNT
$knownPrefix = $env:INPUT_KNOWN_PREFIX
$sequentialDirection = $env:INPUT_SEQUENTIAL_DIRECTION
$generatedPosition = $env:INPUT_GENERATED_POSITION
$delayMs = $env:INPUT_DELAY_MS
$stopOnHit = $env:INPUT_STOP_ON_HIT

$lastCheckpoint = $env:CHECKPOINT_LAST

$stateContent = @"
MODE=$mode
FULL URL=$fullUrl
BASE URL=$baseUrl
SUFFIX LENGTH=$charCount
KNOWN PREFIX=$knownPrefix
SEQUENTIAL DIRECTION=$sequentialDirection
GENERATED POSITION=$generatedPosition
DELAY MS=$delayMs
STOP ON HIT=$stopOnHit
LAST CHECKPOINT=$lastCheckpoint
"@

[System.IO.File]::WriteAllText(
    $stateFile,
    $stateContent,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host ""
Write-Host "========== CURRENT STATE SAVED =========="
Write-Host "MODE                  : $mode"
Write-Host "FULL URL              : $fullUrl"
Write-Host "BASE URL              : $baseUrl"
Write-Host "SUFFIX LENGTH         : $charCount"
Write-Host "KNOWN PREFIX          : $knownPrefix"
Write-Host "SEQUENTIAL DIRECTION  : $sequentialDirection"
Write-Host "GENERATED POSITION    : $generatedPosition"
Write-Host "DELAY MS              : $delayMs"
Write-Host "STOP ON HIT           : $stopOnHit"
Write-Host "LAST CHECKPOINT       : $lastCheckpoint"
Write-Host "=========================================="
Write-Host ""
