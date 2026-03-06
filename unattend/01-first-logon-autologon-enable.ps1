Write-Host ""
Write-Host "==============================="
Write-Host "Running step 01-autologon-enable.ps1"
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "==============================="
Write-Host ""

# Configuration
$autoLogonDir = "C:\Setup\AutoLogon"
$autoLogonExe = Join-Path -Path $autoLogonDir -ChildPath "AutoLogon64.exe"
$username = "mdelgert"
$password = "p@ssw0rd2026!1"
$domain   = "."

# Ensure AutoLogon executable exists
if (-not (Test-Path -Path $autoLogonExe)) {
    Write-Host "ERROR: AutoLogon executable not found at $autoLogonExe"
    exit 1
}

Write-Host "Enabling autologon for user $username..."
try {
    Start-Process -FilePath $autoLogonExe `
        -ArgumentList "/accepteula $username $domain $password" `
        -Wait -NoNewWindow
    Write-Host "Autologon enabled successfully."
}
catch {
    Write-Host "ERROR: Failed to enable autologon - $($_.Exception.Message)"
    exit 1
}

Write-Host "AutoLogon enable complete"
