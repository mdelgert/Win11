#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: source.ps1"
Write-Host "Description: Pull latest from github and run setup script."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

$localSetupScript = "C:\Setup\win11\setup.ps1"

git pull

powershell.exe -NoProfile -ExecutionPolicy Bypass -File $localSetupScript -ScriptSet "secondReboot"

Start-Sleep -Seconds 1