#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 20-reboot.ps1"
Write-Host "Description: Script to reboot the machine."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

Write-Host "Rebooting the machine in 3 seconds..."

Start-Sleep -Seconds 3

Restart-Computer -Force