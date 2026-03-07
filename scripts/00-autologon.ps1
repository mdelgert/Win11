#Requires -Version 5.1
Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: 00-autologon.ps1"
Write-Host "Description: Enable automatic logon for a specified user account."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

function Get-IsoRoot {
    $drives = Get-PSDrive -PSProvider FileSystem

    foreach ($drive in $drives) {
        # Check for unattend.version.txt as unique marker (Windows ISO may also have autounattend.xml)
        $versionMarker = Join-Path $drive.Root "unattend.version.txt"
        $autounattendMarker = Join-Path $drive.Root "autounattend.xml"
        
        if ((Test-Path -Path $versionMarker) -and (Test-Path -Path $autounattendMarker)) {
            return $drive.Root
        }
    }

    return $null
}

# Configuration
$isoRoot = Get-IsoRoot
$autoLogonDir = Join-Path -Path $isoRoot -ChildPath "tools"
$autoLogonExe = Join-Path -Path $autoLogonDir -ChildPath "AutoLogon.exe"
$username = "mdelgert"
$password = "p@ssw0rd2026!0"
$domain   = "."

# Ensure AutoLogon executable exists
if (-not (Test-Path -Path $autoLogonExe)) {
    Write-Host "ERROR: AutoLogon executable not found at $autoLogonExe"
    exit 1
}

Write-Host "Enabling autologon for user $username..."

$process = Start-Process -FilePath $autoLogonExe `
    -ArgumentList "/accepteula $username $domain $password" `
    -Wait -NoNewWindow -PassThru

if ($process.ExitCode -ne 0) {
    throw "AutoLogon.exe exited with code $($process.ExitCode)"
}