param(
    [string]$Uri,
    [int]$Timeout = 2
)

$ErrorActionPreference = "Stop"

try {
    $r = Invoke-WebRequest `
        -Uri $Uri `
        -UseBasicParsing `
        -TimeoutSec $Timeout `
        -UserAgent "Mozilla/5.0"

    $c = $r.Content
    $s = $c.Length

    Write-Host "[RESPOND] HTTP $($r.StatusCode)  Size: $s"

    $ok = $false

    # ------------------------------------------------
    # 1. Direct V2Ray / proxy subscription content
    # ------------------------------------------------
    if ($c -match "vless://|vmess://|trojan://|ss://|hysteria2?://|tuic://|anytls://|socks://") {
        $ok = $true
    }

    # ------------------------------------------------
    # 2. Base64 encoded subscription
    # ------------------------------------------------
    elseif ($s -gt 1500 -and $c -match "^[A-Za-z0-9+/=`r`n]+$") {
        $ok = $true
    }

    # ------------------------------------------------
    # 3. Subscription URL contained in response
    # ------------------------------------------------
    elseif (
        $c -match 'https?://[^"''<>\s]+/(?:api|sub|subscribe|subscription)/[^"''<>\s]+'
    ) {
        $ok = $true
    }

    # ------------------------------------------------
    # 4. Common subscription-page keywords
    # ------------------------------------------------
    elseif (
        $c -match "subscription" -or
        $c -match "subscribe" -or
        $c -match "traffic" -or
        $c -match "expire" -or
        $c -match "device"
    ) {
        $ok = $true
    }

    # ------------------------------------------------
    # Result
    # ------------------------------------------------
    if ($ok) {
        Write-Host "[VALID] Subscription detected."
        exit 0
    }
    else {
        Write-Host "[INVALID] Not a valid subscription response."
        exit 1
    }
}
catch {

    if (
        $_.Exception.Response -and
        [int]$_.Exception.Response.StatusCode -eq 429
    ) {
        Write-Host "[RATE LIMITED]"
        exit 2
    }

    if ($_.Exception.Response) {
        $status = [int]$_.Exception.Response.StatusCode
        Write-Host "[ERROR] HTTP $status - $($_.Exception.Message)"
    }
    else {
        Write-Host "[ERROR] $($_.Exception.Message)"
    }

    exit 1
}
