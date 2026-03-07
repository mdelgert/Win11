#Requires -Version 5.1
<#
File: runonce.ps1

Purpose:
  Register setup.ps1 in RunOnce, optionally pass the next script group,
  then reboot the machine.

Why this script exists:
  Some setup actions require a reboot before continuing.
  This script allows the machine to restart and then continue using the
  same main entry script: setup.ps1.

How it works:
  1. Builds a RunOnce command
  2. Points RunOnce to setup.ps1
  3. Passes -ScriptSet if provided
  4. Waits briefly
  5. Reboots the machine

Typical usage:
  Resume default behavior:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\99-resume.ps1

  Resume a specific group after reboot:
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\99-resume.ps1 -NextScriptSet postreboot

Expected setup path:
  C:\Setup\win11\setup.ps1

Notes:
  - Intended to be called by setup.ps1 or one of its child scripts
  - Uses HKLM RunOnce, so it should run elevated
  - The RunOnce entry is consumed automatically by Windows after execution
  - Keep the NextScriptSet value aligned with a valid ScriptSet in setup.ps1

  99-resume.ps1 -NextScriptSet secondReboot -DelaySeconds 5 -PreviewOnly
#>

[CmdletBinding()]
param(
  [string]$NextScriptSet = "default",
  [int]$DelaySeconds = 3,
  [switch]$PreviewOnly
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: runonce.ps1"
Write-Host "Description: Register setup.ps1 in RunOnce and reboot."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "NextScriptSet: $NextScriptSet"
Write-Host "DelaySeconds: $DelaySeconds"
Write-Host "PreviewOnly: $PreviewOnly"
Write-Host "=============================================================="
Write-Host ""

$runOncePath = 'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce'
$setupScript = 'C:\Setup\win11\setup.ps1'

if (-not (Test-Path -Path $setupScript)) {
    throw "setup.ps1 not found at $setupScript"
}

if ([string]::IsNullOrWhiteSpace($NextScriptSet)) {
    throw "NextScriptSet cannot be empty."
}

$resumeCommand = "powershell.exe -NoProfile -ExecutionPolicy Bypass -File `"$setupScript`" -ScriptSet $NextScriptSet"

Write-Host "Execution plan:"
Write-Host "1) Ensure setup script exists: $setupScript"
Write-Host "2) Write RunOnce value: HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce\ResumeWin11Setup"
Write-Host "3) Value command: $resumeCommand"
Write-Host "4) Wait $DelaySeconds second(s)"
Write-Host "5) Restart computer"
Write-Host ""

Write-Host "RunOnce path: $runOncePath"
Write-Host "Resume command:"
Write-Host $resumeCommand

if ($PreviewOnly) {
  Write-Host "PreviewOnly is set. No registry changes were made and no reboot will occur."
  return
}

New-Item -Path $runOncePath -Force | Out-Null
Set-ItemProperty -Path $runOncePath -Name 'ResumeWin11Setup' -Value $resumeCommand

Write-Host "RunOnce entry saved."
Write-Host "Rebooting the machine in $DelaySeconds seconds..."

Start-Sleep -Seconds $DelaySeconds

Restart-Computer -Force