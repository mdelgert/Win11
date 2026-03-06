#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "STEP 1: Running 10-template.ps1"
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

Start-Sleep -Seconds 2