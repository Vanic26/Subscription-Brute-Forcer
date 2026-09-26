$charCount = [int]$env:INPUT_CHARCOUNT
$knownPrefix = $env:INPUT_KNOWN_PREFIX
$chars = "0123456789abcdefghijklmnopqrstuvwxyz"
$baseN = 36
$prefixLen = $knownPrefix.Length
$genLen = $charCount - $prefixLen

if ($genLen -lt 1) {
    Write-Host "[ERROR] Known prefix is more than or equal to total suffix count."
    exit 1
}
Write-Host ""
Write-Host "================================"
Write-Host "Total suffix count       : $charCount"
Write-Host "Known prefix count       : $prefixLen"
Write-Host "Characters to generate   : $genLen"
Write-Host "================================"
Write-Host ""
