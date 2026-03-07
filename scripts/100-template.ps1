#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 100-template.ps1"
Write-Host "Description: Template for future scripts. Copy and paste this code into a new .ps1 file and modify as needed."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

Start-Sleep -Seconds 2