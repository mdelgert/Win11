# Requires -Version 5.1
# Compatible with Windows PowerShell 5.1

<#
Best-practice Windows 11 OpenSSH setup (Optional Feature) + GitHub keys

- Installs built-in OpenSSH Server (Windows Optional Feature)
- Creates a normal local user (default: mdelgert) and adds to local Administrators
- Imports GitHub public SSH keys into that user's ~/.ssh/authorized_keys
- Fixes ACLs so OpenSSH accepts the key files
- Hardens sshd_config (keys-only + restrict users)
- Opens firewall port 22

Run as Administrator.

https://github.com/mdelgert.keys
#>

param(
    [string]$UserName = "mdelgert",
    [string]$GitHubUser = "mdelgert",
    [switch]$DisableBuiltInAdministrator,
    [switch]$SetDefaultShellPowerShell
)

$ErrorActionPreference = "Stop"

function Assert-Admin {
    $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if (-not $isAdmin) { throw "Run this script in an elevated PowerShell (Run as Administrator)." }
}

function Upsert-SshdSetting([string]$text, [string]$key, [string]$value) {
    $pattern = "(?im)^\s*#?\s*$([regex]::Escape($key))\s+.*$"
    if ($text -match $pattern) {
        return [regex]::Replace($text, $pattern, "$key $value")
    }
    return ($text.TrimEnd() + "`r`n$key $value`r`n")
}

function Ensure-FirewallRule {
    $ruleName = "OpenSSH-Server-In-TCP"
    if (-not (Get-NetFirewallRule -Name $ruleName -ErrorAction SilentlyContinue)) {
        New-NetFirewallRule `
            -Name $ruleName `
            -DisplayName "OpenSSH Server (sshd) Inbound" `
            -Enabled True `
            -Direction Inbound `
            -Protocol TCP `
            -Action Allow `
            -LocalPort 22 | Out-Null
    }
}

function Ensure-LocalUser {
    if (-not (Get-LocalUser -Name $UserName -ErrorAction SilentlyContinue)) {
        Write-Host "Creating local user '$UserName'..."
        $pw = Read-Host -AsSecureString "Enter a password for '$UserName' (only needed for console/UAC; SSH will use keys)"
        New-LocalUser -Name $UserName -Password $pw -PasswordNeverExpires:$true -UserMayNotChangePassword:$false | Out-Null
    } else {
        Write-Host "User '$UserName' already exists."
    }

    $target = "$env:COMPUTERNAME\$UserName"
    $admins = Get-LocalGroupMember -Group "Administrators" -ErrorAction SilentlyContinue | ForEach-Object { $_.Name }
    if ($admins -notcontains $target) {
        Write-Host "Adding '$UserName' to local Administrators..."
        Add-LocalGroupMember -Group "Administrators" -Member $UserName
    } else {
        Write-Host "'$UserName' is already in local Administrators."
    }
}

function Ensure-UserProfilePath {
    $profilePath = Join-Path $env:SystemDrive "Users\$UserName"
    if (-not (Test-Path $profilePath)) {
        Write-Host "Profile folder for '$UserName' not found yet. Creating it by starting a process as the user..."
        $pw = Read-Host -AsSecureString "Re-enter password for '$UserName' to initialize profile (one-time)"
        $cred = New-Object System.Management.Automation.PSCredential("$env:COMPUTERNAME\$UserName", $pw)

        $temp = Join-Path $env:TEMP "init-profile-$UserName.txt"
        Start-Process -FilePath "$env:SystemRoot\System32\cmd.exe" `
            -ArgumentList "/c", "echo init > `"$temp`"" `
            -Credential $cred `
            -WindowStyle Hidden `
            -Wait

        Remove-Item $temp -ErrorAction SilentlyContinue
    }
    return $profilePath
}

function Install-OpenSSHOptionalFeature {
    Write-Host "Installing OpenSSH Server optional feature..."
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null

    Write-Host "Enabling and starting sshd..."
    Set-Service -Name sshd -StartupType Automatic
    Start-Service sshd

    # Optional but useful
    if (Get-Service ssh-agent -ErrorAction SilentlyContinue) {
        Set-Service ssh-agent -StartupType Automatic
        Start-Service ssh-agent
    }

    Ensure-FirewallRule
}

function Import-GitHubKeysForUser([string]$profilePath) {
    Write-Host "Downloading GitHub public keys for '$GitHubUser'..."
    $keys = Invoke-RestMethod "https://github.com/$GitHubUser.keys"
    $keysText = ($keys -join "`n").Trim()

    if ([string]::IsNullOrWhiteSpace($keysText)) {
        throw "No public SSH keys found for GitHub user '$GitHubUser'. Add keys in GitHub Settings > SSH and GPG keys."
    }

    $sshDir = Join-Path $profilePath ".ssh"
    $authKeys = Join-Path $sshDir "authorized_keys"

    New-Item -ItemType Directory -Path $sshDir -Force | Out-Null

    # Overwrite with current GitHub keys for consistency
    ($keysText + "`n") | Set-Content -Path $authKeys -Encoding ascii

    Write-Host "Setting ACLs on $sshDir and authorized_keys..."
    icacls $sshDir /inheritance:r | Out-Null
    icacls $sshDir /grant:r "${UserName}:(F)" "SYSTEM:(F)" "Administrators:(F)" | Out-Null

    icacls $authKeys /inheritance:r | Out-Null
    icacls $authKeys /grant:r "${UserName}:(F)" "SYSTEM:(F)" "Administrators:(F)" | Out-Null
}

function Harden-SshdConfig {
    $cfgPath = "C:\ProgramData\ssh\sshd_config"
    if (-not (Test-Path $cfgPath)) { throw "sshd_config not found at $cfgPath" }

    Write-Host "Hardening sshd_config..."
    $cfg = Get-Content $cfgPath -Raw

    $cfg = Upsert-SshdSetting $cfg "PubkeyAuthentication" "yes"
    $cfg = Upsert-SshdSetting $cfg "PasswordAuthentication" "no"
    $cfg = Upsert-SshdSetting $cfg "KbdInteractiveAuthentication" "no"
    $cfg = Upsert-SshdSetting $cfg "PermitEmptyPasswords" "no"
    $cfg = Upsert-SshdSetting $cfg "MaxAuthTries" "3"
    $cfg = Upsert-SshdSetting $cfg "AllowUsers" $UserName

    Set-Content -Path $cfgPath -Value $cfg -Encoding ascii

    if ($SetDefaultShellPowerShell) {
        Write-Host "Setting default SSH shell to PowerShell..."
        $psPath = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"
        New-Item -Path "HKLM:\SOFTWARE\OpenSSH" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\OpenSSH" -Name "DefaultShell" -Value $psPath -PropertyType String -Force | Out-Null
    }

    Restart-Service sshd
}

function Optional-DisableBuiltInAdministrator {
    if ($DisableBuiltInAdministrator) {
        Write-Host "Disabling built-in 'Administrator' account..."
        & net user administrator /active:no | Out-Null
    }
}

# ------------------ MAIN ------------------
Assert-Admin

Install-OpenSSHOptionalFeature
Ensure-LocalUser

$profilePath = Ensure-UserProfilePath
Import-GitHubKeysForUser -profilePath $profilePath

Harden-SshdConfig
Optional-DisableBuiltInAdministrator

Write-Host ""
Write-Host "Done."
Write-Host "SSH in as the normal user (recommended):"
Write-Host "  ssh $UserName@<windows-ip>"
Write-Host ""
Write-Host "Verify on the box:"
Write-Host "  whoami"
Write-Host "  echo `$env:USERPROFILE"
Write-Host ""
Write-Host "OpenSSH version:"
& "$env:WINDIR\System32\OpenSSH\ssh.exe" -V