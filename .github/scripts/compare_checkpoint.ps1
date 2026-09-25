$stateFile = "$env:GITHUB_WORKSPACE\last_runner_states.txt"

$currentBase = $env:INPUT_BASE_URL
$currentPrefix = $env:INPUT_KNOWN_PREFIX
$currentCharCount = $env:INPUT_CHARCOUNT

$savedBase = ""
$savedPrefix = ""
$savedCharCount = ""
$savedCheckpoint = ""

if (Test-Path $stateFile) {

    foreach ($line in Get-Content $stateFile) {

        # Remove whitespace and invisible Unicode characters at the beginning
        $line = $line.Trim()
        $line = $line -replace '^[\uFEFF\u200B\u200C\u200D]+', ''

        if ($line.StartsWith("BASE URL=")) {
            $savedBase = $line.Substring("BASE URL=".Length).Trim()
        }
        elseif ($line.StartsWith("SUFFIX LENGTH=")) {
            $savedCharCount = $line.Substring("SUFFIX LENGTH=".Length).Trim()
        }
        elseif ($line.StartsWith("KNOWN PREFIX=")) {
            $savedPrefix = $line.Substring("KNOWN PREFIX=".Length).Trim()
        }
        elseif ($line.StartsWith("LAST CHECKPOINT=")) {
            $savedCheckpoint = $line.Substring("LAST CHECKPOINT=".Length).Trim()
        }
    }

    $inputsMatch = (
        ($savedBase -eq $currentBase) -and
        ($savedPrefix -eq $currentPrefix) -and
        ($savedCharCount -eq $currentCharCount) -and
        (-not [string]::IsNullOrWhiteSpace($savedCheckpoint))
    )

    if ($inputsMatch) {

        $lastCheckpoint = $savedCheckpoint

        Write-Host ""
        Write-Host "========== CHECKED LISTS =========="
        Write-Host "Base URL       : Matches"
        Write-Host "Suffix length  : Matches"
        Write-Host "Known prefix   : Matches"
        Write-Host "Last checkpoint: $lastCheckpoint"
        Write-Host "Action         : START FROM LAST CHECKPOINT"
        Write-Host "====================================="
        Write-Host ""
    }
    else {

        $lastCheckpoint = ""

        Write-Host ""
        Write-Host "========== CHECKED LISTS =========="

        if ($savedBase -eq $currentBase) {
            Write-Host "Base URL       : Matches"
        }
        else {
            Write-Host "Base URL       : Not Matches"
        }

        if ($savedCharCount -eq $currentCharCount) {
            Write-Host "Suffix length  : Matches"
        }
        else {
            Write-Host "Suffix length  : Not Matches"
        }

        if ($savedPrefix -eq $currentPrefix) {
            Write-Host "Known prefix   : Matches"
        }
        else {
            Write-Host "Known prefix   : Not Matches"
        }

        if ([string]::IsNullOrWhiteSpace($savedCheckpoint)) {
            Write-Host "Last checkpoint: NONE"
        }
        else {
            Write-Host "Last checkpoint: $savedCheckpoint"
        }

        Write-Host "Action         : START FROM BEGINNING"
        Write-Host "====================================="
        Write-Host ""
    }
}
else {

    $lastCheckpoint = ""

    Write-Host ""
    Write-Host "========== CHECKED LISTS =========="
    Write-Host "No previous state file found."
    Write-Host "Action         : START FROM BEGINNING"
    Write-Host "====================================="
    Write-Host ""
}

# Export values for later workflow steps

"CHECKPOINT_BASE=$currentBase" | Out-File `
    -FilePath $env:GITHUB_ENV `
    -Encoding utf8 -Append

"CHECKPOINT_PREFIX=$currentPrefix" | Out-File `
    -FilePath $env:GITHUB_ENV `
    -Encoding utf8 -Append

"CHECKPOINT_LENGTH=$currentCharCount" | Out-File `
    -FilePath $env:GITHUB_ENV `
    -Encoding utf8 -Append

"CHECKPOINT_LAST=$lastCheckpoint" | Out-File `
    -FilePath $env:GITHUB_ENV `
    -Encoding utf8 -Append
