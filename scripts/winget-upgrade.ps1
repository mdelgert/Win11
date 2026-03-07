#Requires -RunAsAdministrator
#Requires -Version 5.1
# This script downloads and installs the latest WinGet client from the official Microsoft GitHub repository.
# https://github.com/microsoft/winget-cli/discussions/5164

$ErrorActionPreference = 'Stop'

$tag = 'v1.12.440'
# $downloadUrl = "https://github.com/microsoft/winget-cli/releases/download/$tag/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$downloadUrl = "https://github.com/microsoft/winget-cli/releases/download/v1.28.190/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$tempDir = 'C:\Setup'
$bundlePath = Join-Path $tempDir 'Microsoft.DesktopAppInstaller.msixbundle'

New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

Write-Host "Downloading WinGet bundle from $downloadUrl"
Invoke-WebRequest -Uri $downloadUrl -OutFile $bundlePath -UseBasicParsing

if (-not (Test-Path $bundlePath)) {
    throw "Download failed. File not found: $bundlePath"
}

Write-Host "Installing $bundlePath"
Add-AppxPackage -Path $bundlePath -ForceApplicationShutdown -ErrorAction Stop

Write-Host "Install complete."

$found = Get-Command winget.exe -ErrorAction SilentlyContinue
if ($found) {
    Write-Host "winget is available at: $($found.Source)"
} else {
    Write-Warning "winget was installed, but the current session may not see it yet. A sign-out/sign-in or reboot may be needed."
}