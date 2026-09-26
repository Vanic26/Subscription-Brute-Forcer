$stateFile = "$env:GITHUB_WORKSPACE\last_runner_states.txt"

$saved = @{
    MODE                  = ""
    FULL_URL              = ""
    BASE_URL              = ""
    SUFFIX_LENGTH         = ""
    KNOWN_PREFIX          = ""
    SEQUENTIAL_DIRECTION  = ""
    GENERATED_POSITION    = ""
    DELAY_MS              = ""
    STOP_ON_HIT           = ""
    LAST_CHECKPOINT       = ""
}

# ------------------------------------------------------------
# Read existing state file
# ------------------------------------------------------------
if (Test-Path $stateFile) {

    foreach ($line in Get-Content $stateFile) {

        $line = $line.Trim()

        # Remove BOM / zero-width characters
        $line = $line -replace '^[\uFEFF\u200B\u200C\u200D]+', ''

        if ($line -match '^MODE=(.*)$') {
            $saved.MODE = $Matches[1]
        }
        elseif ($line -match '^FULL URL=(.*)$') {
            $saved.FULL_URL = $Matches[1]
        }
        elseif ($line -match '^BASE URL=(.*)$') {
            $saved.BASE_URL = $Matches[1]
        }
        elseif ($line -match '^SUFFIX LENGTH=(.*)$') {
            $saved.SUFFIX_LENGTH = $Matches[1]
        }
        elseif ($line -match '^KNOWN PREFIX=(.*)$') {
            $saved.KNOWN_PREFIX = $Matches[1]
        }
        elseif ($line -match '^SEQUENTIAL DIRECTION=(.*)$') {
            $saved.SEQUENTIAL_DIRECTION = $Matches[1]
        }
        elseif ($line -match '^GENERATED POSITION=(.*)$') {
            $saved.GENERATED_POSITION = $Matches[1]
        }
        elseif ($line -match '^DELAY MS=(.*)$') {
            $saved.DELAY_MS = $Matches[1]
        }
        elseif ($line -match '^STOP ON HIT=(.*)$') {
            $saved.STOP_ON_HIT = $Matches[1]
        }
        elseif ($line -match '^LAST CHECKPOINT=(.*)$') {
            $saved.LAST_CHECKPOINT = $Matches[1]
        }
    }
}

# ------------------------------------------------------------
# Determine input source
# ------------------------------------------------------------
if ($env:GITHUB_EVENT_NAME_INPUT -eq "schedule") {
    Write-Host ""
    Write-Host "============================================"
    Write-Host "[MODE] Scheduled run."
    Write-Host "[MODE] Loading latest inputs from last_runner_states.txt"

    if ([string]::IsNullOrWhiteSpace($saved.MODE)) {
        Write-Host "[ERROR] No saved MODE found in last_runner_states.txt."
        Write-Host "[ERROR] Run the workflow manually once first."
        exit 1
    }

    $runMode = $saved.MODE
    $runFullUrl = $saved.FULL_URL
    $runBaseUrl = $saved.BASE_URL
    $runCharCount = $saved.SUFFIX_LENGTH
    $runKnownPrefix = $saved.KNOWN_PREFIX
    $runSequentialDirection = $saved.SEQUENTIAL_DIRECTION
    $runGeneratedPosition = $saved.GENERATED_POSITION
    $runDelayMs = $saved.DELAY_MS
    $runStopOnHit = $saved.STOP_ON_HIT
}
else {

    Write-Host "[MODE] Manual run."
    Write-Host "[MODE] Loading inputs from workflow_dispatch."
    Write-Host ""

    $runMode = $env:INPUT_MODE
    $runFullUrl = $env:INPUT_FULL_URL
    $runBaseUrl = $env:INPUT_BASE_URL
    $runCharCount = $env:INPUT_CHARCOUNT
    $runKnownPrefix = $env:INPUT_KNOWN_PREFIX
    $runSequentialDirection = $env:INPUT_SEQUENTIAL_DIRECTION
    $runGeneratedPosition = $env:INPUT_GENERATED_POSITION
    $runDelayMs = $env:INPUT_DELAY_MS
    $runStopOnHit = $env:INPUT_STOP_ON_HIT
}

# ------------------------------------------------------------
# Validate values
# ------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($runMode)) {
    Write-Host "[ERROR] MODE is empty."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($runCharCount)) {
    Write-Host "[ERROR] SUFFIX_LENGTH / charcount is empty."
    exit 1
}

if ([string]::IsNullOrWhiteSpace($runSequentialDirection)) {
    $runSequentialDirection = "Last digit first"
}

if ([string]::IsNullOrWhiteSpace($runGeneratedPosition)) {
    $runGeneratedPosition = "Back of known prefix"
}

if ([string]::IsNullOrWhiteSpace($runDelayMs)) {
    $runDelayMs = "500"
}

if ([string]::IsNullOrWhiteSpace($runStopOnHit)) {
    $runStopOnHit = "true"
}

# ------------------------------------------------------------
# Display effective inputs
# ------------------------------------------------------------
Write-Host "============================================"
Write-Host "V2Ray Subscription Brute Forcer"
Write-Host "============================================"
Write-Host "Run Event             : $env:GITHUB_EVENT_NAME_INPUT"
Write-Host "Mode                  : $runMode"
Write-Host "Full URL              : $runFullUrl"
Write-Host "Base URL              : $runBaseUrl"
Write-Host "Suffix length         : $runCharCount"
Write-Host "Known prefix          : $runKnownPrefix"
Write-Host "Sequential direction  : $runSequentialDirection"
Write-Host "Generated position    : $runGeneratedPosition"
Write-Host "Delay ms              : $runDelayMs"
Write-Host "Stop on hit           : $runStopOnHit"
Write-Host "============================================"
Write-Host ""

# ------------------------------------------------------------
# Expose effective inputs as STEP OUTPUTS.
# ------------------------------------------------------------
"mode=$runMode" >> $env:GITHUB_OUTPUT
"full_url=$runFullUrl" >> $env:GITHUB_OUTPUT
"base_url=$runBaseUrl" >> $env:GITHUB_OUTPUT
"charcount=$runCharCount" >> $env:GITHUB_OUTPUT
"known_prefix=$runKnownPrefix" >> $env:GITHUB_OUTPUT
"sequential_direction=$runSequentialDirection" >> $env:GITHUB_OUTPUT
"generated_position=$runGeneratedPosition" >> $env:GITHUB_OUTPUT
"delay_ms=$runDelayMs" >> $env:GITHUB_OUTPUT
"stop_on_hit=$runStopOnHit" >> $env:GITHUB_OUTPUT
