#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 00-remove-autologoncount.ps1"
Write-Host "Description: Wait for Winlogon AutoLogonCount to appear, then remove it."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

<#
Purpose
-------
This script waits for the Winlogon registry value 'AutoLogonCount' to appear,
then removes it.

Why this is needed
------------------
This unattended install flow uses the Schneegans unattend generator:
https://schneegans.de/windows/unattend-generator/

That generator uses the normal Windows unattended autologon process for the
initial setup sign-in. Microsoft documents that LogonCount / AutoLogonCount
is part of that one-time unattended autologon behavior.

In this setup, AutoLogonCount eventually gets written with a value of 0 during
the setup cleanup phase. Once that happens, the one-time unattended autologon
is considered exhausted, which can interfere with a later persistent autologon
configuration.

This script solves that by:
  1. Waiting until AutoLogonCount actually exists
  2. Removing it as soon as it appears
  3. Failing hard if it never appears within the retry window

Behavior
--------
- Retries every 2 seconds
- Stops after 60 attempts
- Throws an error if the value never appears
#>

$registryPath = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon'
$valueName = 'AutoLogonCount'
$maxRetries = 60
$delaySeconds = 2
$found = $false

for ($attempt = 1; $attempt -le $maxRetries; $attempt++) {
    Write-Host "Checking for registry value '$valueName' (attempt $attempt of $maxRetries)..."

    $value = Get-ItemProperty -Path $registryPath -Name $valueName -ErrorAction SilentlyContinue

    if ($null -ne $value) {
        Write-Host "Found registry value '$valueName'. Removing it now..."
        Remove-ItemProperty -Path $registryPath -Name $valueName -ErrorAction Stop
        Write-Host "Removed registry value '$valueName'."
        $found = $true
        break
    }

    Start-Sleep -Seconds $delaySeconds
}

if (-not $found) {
    throw "Registry value '$valueName' was not found after $maxRetries attempts."
}