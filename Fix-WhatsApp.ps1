<#
.SYNOPSIS
    Removes hardcoded WhatsApp entries from the Windows Hosts file to restore connectivity.
.DESCRIPTION
    This script backs up the current hosts file, filters out lines containing "whatsapp", 
    saves the cleaned file, and flushes the DNS cache.
.NOTES
    Requires Administrator privileges.
    
    DISCLAIMER:
    This script is provided "AS IS" without warranty of any kind. The author disclaims all warranties, 
    either express or implied. Use at your own risk. The author shall not be liable for any damages 
    arising out of the use of or inability to use this script.
#>

$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupPath = "$hostsPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"

Write-Host "Starting WhatsApp Connectivity Fix..." -ForegroundColor Cyan

# Check for Administrator privileges
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You are not running as Administrator. The script may fail to save changes."
    Write-Warning "Please right-click and 'Run as Administrator'."
}

# Step 1: Backup the existing Hosts file
if (Test-Path $hostsPath) {
    Write-Host "Backing up hosts file to: $backupPath" -ForegroundColor Yellow
    try {
        Copy-Item -Path $hostsPath -Destination $backupPath -Force
    } catch {
        Write-Host "Error backing up file. Aborting safety check." -ForegroundColor Red
        exit
    }
}

# Step 2: Read and Clean the file
try {
    $content = Get-Content -Path $hostsPath
    
    # Count how many lines contain 'whatsapp'
    $blockedLines = $content | Select-String "whatsapp"
    
    if ($blockedLines) {
        Write-Host "Found $($blockedLines.Count) hardcoded WhatsApp entries." -ForegroundColor Red
        
        # Filter OUT lines containing 'whatsapp'
        $cleanContent = $content | Where-Object { $_ -notmatch "whatsapp" }
        
        # Step 3: Write the clean content back
        [System.IO.File]::WriteAllLines($hostsPath, $cleanContent)
        Write-Host "Successfully removed blocked entries." -ForegroundColor Green
    } else {
        Write-Host "No WhatsApp entries found. File is clean." -ForegroundColor Green
    }
} catch {
    Write-Host "Failed to read/write hosts file. Ensure you are running as Administrator." -ForegroundColor Red
    exit
}

# Step 4: Flush DNS to apply changes immediately
Write-Host "Flushing DNS Cache..." -ForegroundColor Cyan
ipconfig /flushdns

Write-Host "Fix Complete. Please restart WhatsApp Desktop." -ForegroundColor Green
Read-Host -Prompt "Press Enter to exit"
