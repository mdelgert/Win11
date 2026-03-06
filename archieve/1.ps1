# Requires -RunAsAdministrator
# Compatible with Windows PowerShell 5.1
# Script to run on first logon to set up the environment

$timeout = [datetime]::Now.AddMinutes(5)
$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$repoUrl = "https://github.com/mdelgert/win11.git"
$repoDir = "C:\source\win11"
$setupScript = "$repoDir\setup.ps1"

# Install git using winget
while ($true) {
    if ($winget | Test-Path) {
        & $winget install --exact --id Git.Git --silent --accept-package-agreements --accept-source-agreements --source winget --scope machine
        break
    }
    if ([datetime]::Now -gt $timeout) {
        Write-Warning "File '${winget}' does not exist."
        return
    }
    Write-Host "Waiting for '${winget}' to become available..."
    Start-Sleep -Seconds 1
}

# Clone the repository
git clone $repoUrl $repoDir

# Wait for the setup script to become available and execute it
while ($true) {
    if ($setupScript | Test-Path) {
        & $setupScript
        return
    }
    if ([datetime]::Now -gt $timeout) {
        Write-Warning "File '${setupScript}' does not exist."
        return
    }
    Write-Host "Waiting for '${setupScript}' to become available..."
    Start-Sleep -Seconds 1
}