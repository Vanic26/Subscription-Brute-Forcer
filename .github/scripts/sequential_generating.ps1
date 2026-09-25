$charCount = [int]$env:INPUT_CHARCOUNT
$delayMs = [int]$env:INPUT_DELAY_MS
$knownPrefix = $env:INPUT_KNOWN_PREFIX
$direction = $env:INPUT_SEQUENTIAL_DIRECTION
$generatedPosition = $env:INPUT_GENERATED_POSITION
$base = $env:INPUT_BASE_URL
$resultFile = "$env:GITHUB_WORKSPACE\found_subs.txt"
$stateFile = "$env:GITHUB_WORKSPACE\last_runner_states.txt"
$chars = "0123456789abcdefghijklmnopqrstuvwxyz"
$baseN = 36
$stopOnHit = $env:INPUT_STOP_ON_HIT
$workflowName = $env:INPUT_WORKFLOW_NAME

# ------------------------------------------------------------
# Clean existing result file
# ------------------------------------------------------------
if (Test-Path $resultFile) {

    $uniqueResults = Get-Content -Path $resultFile |
        Where-Object { $_.Trim() -ne "" } |
        Select-Object -Unique

    Set-Content -Path $resultFile -Value $uniqueResults
}

Write-Host "[STATUS] Stop on result hit: '$stopOnHit'"
Write-Host "[STATUS] Sequential direction: '$direction'"
Write-Host "[STATUS] Starting sequential checking..."

# ------------------------------------------------------------
# Calculate generated length
# ------------------------------------------------------------
$prefixLen = $knownPrefix.Length
$genLen = $charCount - $prefixLen

if ($genLen -lt 1) {
    Write-Host "[ERROR] Known prefix is longer than or equal to total characters."
    exit 1
}

# ------------------------------------------------------------
# Calculate total number of possible generated values
# ------------------------------------------------------------
$totalSequences = [math]::Pow($baseN, $genLen)

# ------------------------------------------------------------
# Resume from previous checkpoint
# ------------------------------------------------------------
$seq = 0
$lastCheckpoint = $env:CHECKPOINT_LAST

if (-not [string]::IsNullOrWhiteSpace($lastCheckpoint)) {

    $generatedPart = $lastCheckpoint

    if ($generatedPosition -eq "Front of known prefix") {

        if ($knownPrefix -and $lastCheckpoint.EndsWith($knownPrefix)) {

            $generatedPart = $lastCheckpoint.Substring(
                0,
                $lastCheckpoint.Length - $knownPrefix.Length
            )
        }
        else {

            Write-Host "[RESUME] Checkpoint does not match the current known prefix."
            Write-Host "[RESUME] Starting from 0."
            $lastCheckpoint = ""
        }
    }
    else {

        if ($knownPrefix -and $lastCheckpoint.StartsWith($knownPrefix)) {

            $generatedPart = $lastCheckpoint.Substring(
                $knownPrefix.Length
            )
        }
        else {

            Write-Host "[RESUME] Checkpoint does not match the current known prefix."
            Write-Host "[RESUME] Starting from 0."
            $lastCheckpoint = ""
        }
    }

    if ($generatedPart.Length -ne $genLen) {

        Write-Host "[RESUME] Checkpoint length does not match current generated length."
        Write-Host "[RESUME] Starting from 0."
        $seq = 0
    }
    else {

        # ------------------------------------------------------
        # Convert checkpoint back to sequence number.
        #
        # Last digit first:
        #   000
        #   001
        #   002
        #
        # First digit first:
        #   000
        #   100
        #   200
        # ------------------------------------------------------
        $value = 0

        if ($direction -eq "Last digit first") {

            # Normal base-36 representation
            foreach ($ch in $generatedPart.ToCharArray()) {

                $idx = $chars.IndexOf($ch)

                if ($idx -lt 0) {
                    Write-Host "[ERROR] Invalid character '$ch' in checkpoint."
                    exit 1
                }

                $value = ($value * $baseN) + $idx
            }
        }
        else {

            # First digit changes fastest.
            # Reverse the positions when converting back.
            for ($i = $genLen - 1; $i -ge 0; $i--) {

                $ch = $generatedPart[$i]

                $idx = $chars.IndexOf($ch)

                if ($idx -lt 0) {
                    Write-Host "[ERROR] Invalid character '$ch' in checkpoint."
                    exit 1
                }

                $value = ($value * $baseN) + $idx
            }
        }

        $seq = $value + 1

        Write-Host "[RESUME] Previous checkpoint: $lastCheckpoint"
        Write-Host "[RESUME] Starting from sequence: $seq"
    }
}
else {

    Write-Host "[RESUME] No previous checkpoint."
    Write-Host "[RESUME] Starting from sequence 0."
}

# ------------------------------------------------------------
# Sequential checking loop
# ------------------------------------------------------------
for ($test = 1; ; $test++) {

    # --------------------------------------------------------
    # Stop when the complete sequence has been generated
    # --------------------------------------------------------
    if ($seq -ge $totalSequences) {
        Write-Host ""
        Write-Host "[COMPLETE] All sequential values have been generated."
        Write-Host "[COMPLETE] Total sequences checked: $totalSequences"
        Write-Host "[STOP] No result found. Will stop current job and disabling workflow."

        gh workflow disable "$workflowName"

        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to disable workflow."
            exit 1
        }

        Write-Host "[STOP] Workflow disabled successfully."
        break
    }

    $n = $seq

    # Create generated part
    $partChars = New-Object char[] $genLen

    for ($i = 0; $i -lt $genLen; $i++) {

        $r = $n % $baseN
        $n = [math]::Floor($n / $baseN)

        if ($direction -eq "Last digit first") {
            # Last digit changes fastest
            $position = $genLen - 1 - $i
        }
        else {
            # First digit changes fastest
            $position = $i
        }

        $partChars[$position] = $chars[$r]
    }

    $part = -join $partChars

    if ($generatedPosition -eq "Front of known prefix") {
        $suffix = $part + $knownPrefix
    }
    else {
        $suffix = $knownPrefix + $part
    }

    $fullUrl = $base + $suffix

    # --------------------------------------------------------
    # Check URL
    # --------------------------------------------------------
    $checkOutput = & "$env:GITHUB_WORKSPACE\.github\scripts\url_checker.ps1" -Uri $fullUrl -Timeout 3 2>&1
    $checkResult = $LASTEXITCODE

    # --------------------------------------------------------
    # Display checker output
    # --------------------------------------------------------
    $checkOutput | ForEach-Object {
        Write-Host $_
    }

    # --------------------------------------------------------
    # Delay
    # --------------------------------------------------------
    if ($delayMs -gt 0) {
        Start-Sleep -Milliseconds $delayMs
    }

    # --------------------------------------------------------
    # Valid subscription found
    # --------------------------------------------------------
    if ($checkResult -eq 0) {

        Write-Host "[FOUND] $fullUrl"

        $existingResults = @()

        if (Test-Path $resultFile) {
            $existingResults = Get-Content -Path $resultFile
        }

        if ($existingResults -contains $fullUrl) {

            Write-Host "[DUPLICATE] Result already exists."
        }
        else {

            Add-Content -Path $resultFile -Value $fullUrl
            Write-Host "[SAVED] New result added."
        }

        # ----------------------------------------------------
        # Save latest checkpoint
        # ----------------------------------------------------
        $stateContent = @"
MODE=$env:INPUT_MODE
FULL URL=$env:INPUT_FULL_URL
BASE URL=$env:INPUT_BASE_URL
SUFFIX LENGTH=$env:INPUT_CHARCOUNT
KNOWN PREFIX=$env:INPUT_KNOWN_PREFIX
SEQUENTIAL DIRECTION=$env:INPUT_SEQUENTIAL_DIRECTION
GENERATED POSITION=$env:INPUT_GENERATED_POSITION
DELAY MS=$env:INPUT_DELAY_MS
STOP ON HIT=$env:INPUT_STOP_ON_HIT
LAST CHECKPOINT=$suffix
"@

        [System.IO.File]::WriteAllText(
            $stateFile,
            $stateContent,
            [System.Text.UTF8Encoding]::new($false)
        )

        # ----------------------------------------------------
        # STOP ON HIT
        # ----------------------------------------------------
        if ($stopOnHit -eq "true") {

            Write-Host "[STOP] Result found. Will stop current job and disabling workflow."

            gh workflow disable "$workflowName"

            if ($LASTEXITCODE -ne 0) {
                Write-Host "[ERROR] Failed to disable workflow."
                exit 1
            }

            Write-Host "[STOP] Workflow disabled successfully."

            break
        }
    }

    # --------------------------------------------------------
    # HTTP 429
    # --------------------------------------------------------
    elseif ($checkResult -eq 2) {

        Write-Host "[TOO MANY REQUESTS] Waiting 10 seconds to cool down..."

        Start-Sleep -Seconds 10

        # Do NOT increment $seq.
        # The same URL will be tested again.
        continue
    }

    # --------------------------------------------------------
    # Not found / other error
    # --------------------------------------------------------
    else {

        Write-Host "[NOT FOUND] $suffix"
    }

    # --------------------------------------------------------
    # ALWAYS save latest checkpoint
    # --------------------------------------------------------
    $stateContent = @"
MODE=$env:INPUT_MODE
FULL URL=$env:INPUT_FULL_URL
BASE URL=$env:INPUT_BASE_URL
SUFFIX LENGTH=$env:INPUT_CHARCOUNT
KNOWN PREFIX=$env:INPUT_KNOWN_PREFIX
SEQUENTIAL DIRECTION=$env:INPUT_SEQUENTIAL_DIRECTION
GENERATED POSITION=$env:INPUT_GENERATED_POSITION
DELAY MS=$env:INPUT_DELAY_MS
STOP ON HIT=$env:INPUT_STOP_ON_HIT
LAST CHECKPOINT=$suffix
"@

    [System.IO.File]::WriteAllText(
        $stateFile,
        $stateContent,
        [System.Text.UTF8Encoding]::new($false)
    )

    # --------------------------------------------------------
    # Move to next sequence
    # --------------------------------------------------------
    $global:LASTEXITCODE = 0
    $seq++
}
