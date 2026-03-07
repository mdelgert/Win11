#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 99-resume.ps1"
Write-Host "Description: Script to reboot and resume scripts."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

$runOncePath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
$resumeCommand = 'powershell.exe -NoProfile -ExecutionPolicy Bypass -File C:\Setup\win11\setup.ps1'
New-Item -Path $runOncePath -Force | Out-Null
Set-ItemProperty -Path $runOncePath -Name 'ResumeWin11Setup' -Value $resumeCommand

Write-Host "Rebooting the machine in 3 seconds..."

Start-Sleep -Seconds 3

Restart-Computer -Force