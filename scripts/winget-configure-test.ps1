#Requires -Version 5.1

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: winget-configure-test.ps1"
Write-Host "Description: Configure baseline winget settings."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "ScriptSet: $ScriptSet"
Write-Host "TestParam: $TestParam"
Write-Host "=============================================================="
Write-Host ""

winget configure -f C:\Source\win11\.config\test.dsc.winget --accept-configuration-agreements

Start-Sleep -Seconds 1