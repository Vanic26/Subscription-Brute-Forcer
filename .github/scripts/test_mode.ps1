$full = $env:INPUT_FULL_URL

if ([string]::IsNullOrWhiteSpace($full)) {
    Write-Host "[ERROR] No URL was entered."
    exit 1
}

$fullUrl = $full

Write-Host ""
Write-Host "============================================"
Write-Host "[TEST] Trying: $fullUrl"
Write-Host "============================================"
Write-Host ""

& "$env:GITHUB_WORKSPACE\.github\scripts\url_checker.ps1" -Uri $fullUrl -Timeout 3 > $null 2>&1
