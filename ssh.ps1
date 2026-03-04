# Run in PowerShell as Administrator
$GitHubUser = "mdelgert"

$ErrorActionPreference = "Stop"

Write-Host "Installing Windows Optional Feature: OpenSSH Server..."
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null

Write-Host "Enabling and starting sshd..."
Set-Service -Name sshd -StartupType Automatic
Start-Service sshd

# Optional but recommended: start the agent too (useful for outbound SSH)
if (Get-Service ssh-agent -ErrorAction SilentlyContinue) {
    Set-Service -Name ssh-agent -StartupType Automatic
    Start-Service ssh-agent
}

Write-Host "Ensuring firewall rule for port 22..."
# Built-in rule name varies; create our own if missing
if (-not (Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue)) {
    New-NetFirewallRule `
        -Name "OpenSSH-Server-In-TCP" `
        -DisplayName "OpenSSH Server (sshd) Inbound" `
        -Enabled True `
        -Direction Inbound `
        -Protocol TCP `
        -Action Allow `
        -LocalPort 22 | Out-Null
}

Write-Host "Fetching GitHub public keys for $GitHubUser..."
$keys = (Invoke-RestMethod "https://github.com/$GitHubUser.keys") -join "`n"
if ([string]::IsNullOrWhiteSpace($keys)) {
    throw "No public SSH keys found for GitHub user '$GitHubUser'. Add a key in GitHub Settings > SSH and GPG keys."
}

# Ensure user's .ssh exists
$sshDir = Join-Path $env:USERPROFILE ".ssh"
$authKeys = Join-Path $sshDir "authorized_keys"
New-Item -ItemType Directory -Path $sshDir -Force | Out-Null

# Write keys (overwrite). Change to Add-Content if you prefer append.
Set-Content -Path $authKeys -Value ($keys + "`n") -Encoding ascii

Write-Host "Locking down permissions on .ssh and authorized_keys..."
# Windows OpenSSH is picky about permissions.
icacls $sshDir /inheritance:r | Out-Null
icacls $sshDir /grant:r "$env:USERNAME:(F)" "SYSTEM:(F)" "Administrators:(F)" | Out-Null

icacls $authKeys /inheritance:r | Out-Null
icacls $authKeys /grant:r "$env:USERNAME:(F)" "SYSTEM:(F)" "Administrators:(F)" | Out-Null

Write-Host "Hardening sshd_config (keys-only + restrict users)..."
$sshdConfig = "C:\ProgramData\ssh\sshd_config"
if (Test-Path $sshdConfig) {
    $cfg = Get-Content $sshdConfig -Raw

    function Upsert-SshdSetting([string]$text, [string]$key, [string]$value) {
        $pattern = "(?im)^\s*#?\s*$([regex]::Escape($key))\s+.*$"
        if ($text -match $pattern) {
            return [regex]::Replace($text, $pattern, "$key $value")
        }
        return ($text.TrimEnd() + "`r`n$key $value`r`n")
    }

    $cfg = Upsert-SshdSetting $cfg "PubkeyAuthentication" "yes"
    $cfg = Upsert-SshdSetting $cfg "PasswordAuthentication" "no"
    $cfg = Upsert-SshdSetting $cfg "PermitRootLogin" "no"
    $cfg = Upsert-SshdSetting $cfg "MaxAuthTries" "3"
    $cfg = Upsert-SshdSetting $cfg "AllowUsers" $env:USERNAME

    Set-Content -Path $sshdConfig -Value $cfg -Encoding ascii
} else {
    Write-Warning "sshd_config not found at $sshdConfig (unexpected). Skipping config hardening."
}

Restart-Service sshd

Write-Host ""
Write-Host "Done."
Write-Host "Test from another machine: ssh $env:USERNAME@<windows-ip>"
Write-Host "Installed OpenSSH version:"
& "$env:WINDIR\System32\OpenSSH\ssh.exe" -V
