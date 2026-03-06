#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: iso.ps1"
Write-Host "Description: Downloads the latest unattend.iso from the GitHub releases."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

Invoke-WebRequest -Uri 'https://github.com/mdelgert/win11/releases/latest/download/unattend.iso' -OutFile 'Z:\unattend.iso'
