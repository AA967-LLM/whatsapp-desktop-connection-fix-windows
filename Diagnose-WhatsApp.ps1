<#
.SYNOPSIS
    Diagnoses connectivity issues with WhatsApp Desktop.
.DESCRIPTION
    Checks WebView2 status, TLS Registry settings, Connection to Port 443, 
    and scans the Hosts file for interference.

    DISCLAIMER:
    This script is provided "AS IS" without warranty of any kind. Use at your own risk.
#>

Write-Host "=== WHATSAPP DIAGNOSTIC REPORT ===" -ForegroundColor Cyan

# 1. Check WebView2 Runtime (The Engine)
try {
    $wv2 = Get-ItemProperty -Path "HKLM:\SOFTWARE\WOW6432Node\Microsoft\EdgeUpdate\Clients\{F3017226-FE2A-4295-8BDF-00C3A9A7E4C5}" -Name "pv" -ErrorAction Stop
    Write-Host "[OK] WebView2 Version: $($wv2.pv)" -ForegroundColor Green
} catch {
    Write-Host "[WARN] WebView2 not detected (Or Access Denied)." -ForegroundColor Yellow
}

# 2. Test Connection to Server
Write-Host "`nTesting Connection..."
try {
    $conn = Test-NetConnection -ComputerName web.whatsapp.com -Port 443
    if ($conn.TcpTestSucceeded) {
        Write-Host "[OK] Connection to WhatsApp Server: SUCCESS" -ForegroundColor Green
    } else {
        Write-Host "[FAIL] Connection to WhatsApp Server: FAILED" -ForegroundColor Red
    }
} catch {
    Write-Host "[FAIL] Network test failed to run." -ForegroundColor Red
}

# 3. Check TLS Protocols (Security Language)
Write-Host "`nChecking Security Protocols (TLS)..."
$tls12 = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2\Client' -Name 'Enabled' -ErrorAction SilentlyContinue
$tls13 = Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.3\Client' -Name 'Enabled' -ErrorAction SilentlyContinue

if ($tls12.Enabled -eq 1) { Write-Host "[OK] TLS 1.2: Enabled" -ForegroundColor Green } else { Write-Host "[INFO] TLS 1.2: System Default" -ForegroundColor Gray }
if ($tls13.Enabled -eq 1) { Write-Host "[OK] TLS 1.3: Enabled" -ForegroundColor Green } else { Write-Host "[INFO] TLS 1.3: System Default" -ForegroundColor Gray }

# 4. Check Hosts File (The Root Cause)
Write-Host "`nScanning Hosts File for Blocks..."
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
if (Select-String -Path $hosts -Pattern "whatsapp") {
    Write-Host "[CRITICAL] Found hardcoded WhatsApp entries in Hosts file!" -ForegroundColor Red
    Write-Host "This is likely the cause of the connection failure." -ForegroundColor Red
} else {
    Write-Host "[OK] Hosts file is clean." -ForegroundColor Green
}

Write-Host "`n=== END REPORT ===" -ForegroundColor Cyan
Read-Host -Prompt "Press Enter to exit"
