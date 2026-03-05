#Requires -Version 5.1
# base.ps1
# Compatible with Windows PowerShell 5.1
# Requires -RunAsAdministrator
# Installs apps via winget, clones a repo, configures autologon, and reboots.

$ErrorActionPreference = 'Stop'

# =========================
# Configuration
# =========================
$autologonUsername = 'mdelgert'
$autologonPassword = 'p@ssw0rd2026!'
$autologonDomain   = '.'
$repoUrl   = 'https://github.com/mdelgert/Win11.git'
$winget    = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$autologon = "C:\Program Files\WinGet\Packages\Microsoft.Sysinternals.Autologon_Microsoft.Winget.Source_8wekyb3d8bbwe\Autologon.exe"
$sourceDir = Join-Path -Path $env:SystemDrive -ChildPath 'source'
$wingetTimeoutMinutes = 5
$wingetPollSeconds    = 1
$rebootDelaySeconds   = 10
$apps = @(
    'Git.Git',
    'Microsoft.Sysinternals.Autologon'
)

# =========================
# Main
# =========================

# Step 1 — Wait for winget to become available
$timeout = [datetime]::Now.AddMinutes( $wingetTimeoutMinutes )

while( $true ) {
    if( Test-Path -Path $winget ) {
        "Found winget at '${winget}'" | Write-Host
        break
    }

    if( [datetime]::Now -gt $timeout ) {
        throw "winget was not found within ${wingetTimeoutMinutes} minutes."
    }

    'Waiting for winget to become available...' | Write-Host
    Start-Sleep -Seconds $wingetPollSeconds
}

# Step 2 — Install apps
foreach( $id in $apps ) {
    "Installing $id ..." | Write-Host

    & $winget install `
        --exact --id $id `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --source winget `
        --scope machine

    if( $LASTEXITCODE -ne 0 ) {
        "winget returned exit code $LASTEXITCODE for $id" | Write-Warning
    } else {
        "Installed $id" | Write-Host
    }
}

# Step 3 — Create source directory and clone repo
$repoName = [System.IO.Path]::GetFileNameWithoutExtension( ($repoUrl -split '/')[-1] )
$repoDir  = Join-Path -Path $sourceDir -ChildPath $repoName

if( -not (Test-Path -Path $sourceDir) ) {
    "Creating directory '${sourceDir}' ..." | Write-Host
    New-Item -Path $sourceDir -ItemType Directory -Force | Out-Null
}

if( -not (Test-Path -Path $repoDir) ) {
    "Cloning ${repoUrl} to '${repoDir}' ..." | Write-Host
    git clone $repoUrl $repoDir

    if( $LASTEXITCODE -ne 0 ) {
        "git clone returned exit code $LASTEXITCODE" | Write-Warning
    } else {
        "Cloned ${repoUrl} into '${repoDir}'" | Write-Host
    }
} else {
    "Repository folder '${repoDir}' already exists. Skipping clone." | Write-Host
}

# Step 4 — Configure autologon and reboot
"Configuring autologon for '${autologonUsername}' ..." | Write-Host
Start-Process -FilePath $autologon `
    -ArgumentList "/accepteula $autologonUsername $autologonDomain $autologonPassword" `
    -Wait

"Rebooting in ${rebootDelaySeconds} seconds ..." | Write-Host
Start-Sleep -Seconds $rebootDelaySeconds
Restart-Computer -Force