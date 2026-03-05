#Requires -Version 5.1
# autologon.ps1
# Compatible with Windows PowerShell 5.1
# Requires -RunAsAdministrator
# Step 3: Enable autologon for the specified user and reboot the system

$Username = "mdelgert"
$Password = "p@ssw0rd2026!"
$Domain   = "."

$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$autologon = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Microsoft.Sysinternals.Autologon_Microsoft.Winget.Source_8wekyb3d8bbwe\Autologon.exe"

# Install Autologon
& $winget install Microsoft.Sysinternals.Autologon `
    --accept-package-agreements `
    --accept-source-agreements

# Wait briefly for the alias to appear
$timeout = [datetime]::Now.AddSeconds(10)
while (-not (Test-Path $autologon)) {
    if ([datetime]::Now -gt $timeout) {
        throw "Autologon.exe alias not created"
    }
    Start-Sleep 1
}

Write-Host "Using $autologon"

# Enable autologon
Start-Process $autologon `
    -ArgumentList "/accepteula $Username $Domain $Password" `
    -Wait

Restart-Computer -Force