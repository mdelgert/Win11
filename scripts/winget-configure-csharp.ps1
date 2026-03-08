#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: winget-configure-csharp.ps1"
Write-Host "Description: Configure C# development environment."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

winget configure -f C:\source\win11\.config\learn_csharp_vs_community.winget --accept-configuration-agreements

Start-Sleep -Seconds 1