# Manual OpenSSH Server Setup (Windows 11)

This document explains how to perform manually what `scripts/ssh-server.ps1` automates.

## Goal

- Install and enable Windows OpenSSH Server.
- Open inbound firewall port `22`.
- Configure `sshd` to use per-user keys (`.ssh/authorized_keys`) for admin users.
- Download keys from GitHub user `mdelgert`.
- Set secure ACLs on `.ssh` and `authorized_keys`.

## Prerequisites

- Run PowerShell **as Administrator**.
- Use Windows PowerShell 5.1.
- Know the target Windows login account (example: `mdelgert`).
- Internet access is required to fetch keys from GitHub.

## Variables (set these first)

```powershell
$GitHubUsername = "mdelgert"
$TargetUsername = "mdelgert"
$SSHPort = 22
$TargetIdentity = "$env:COMPUTERNAME\$TargetUsername"
$TargetProfile = Join-Path -Path $env:SystemDrive -ChildPath ("Users\" + $TargetUsername)
$SshDir = Join-Path -Path $TargetProfile -ChildPath ".ssh"
$AuthorizedKeysPath = Join-Path -Path $SshDir -ChildPath "authorized_keys"
$SshdConfigPath = "$env:ProgramData\ssh\sshd_config"
```

## 1. Install OpenSSH Server (if needed)

```powershell
$sshServerFeature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
if ($null -eq $sshServerFeature) { throw "OpenSSH Server capability not found" }
if ($sshServerFeature.State -ne "Installed") {
    Add-WindowsCapability -Online -Name $sshServerFeature.Name -ErrorAction Stop
}
```

## 2. Enable and start services

```powershell
Set-Service -Name sshd -StartupType Automatic -ErrorAction Stop
Start-Service -Name sshd -ErrorAction SilentlyContinue

Set-Service -Name ssh-agent -StartupType Automatic -ErrorAction Stop
Start-Service -Name ssh-agent -ErrorAction SilentlyContinue
```

## 3. Open firewall port 22

```powershell
$firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
if ($null -eq $firewallRule) {
    New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort $SSHPort -ErrorAction Stop
} else {
    Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Enabled True -ErrorAction Stop
}
```

## 4. Back up and edit `sshd_config`

Make a backup first:

```powershell
Copy-Item -Path $SshdConfigPath -Destination ("$SshdConfigPath.backup_" + (Get-Date -Format 'yyyyMMdd_HHmmss')) -Force
```

Edit `C:\ProgramData\ssh\sshd_config` and ensure these effective settings:

```text
PubkeyAuthentication yes
PasswordAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
```

Important for admin users:

- Disable the default admin key override block if present:

```text
Match Group administrators
    AuthorizedKeysFile __PROGRAMDATA__/ssh/administrators_authorized_keys
```

Comment out those lines so admin users use their own profile keys.

Restart service after edits:

```powershell
Restart-Service -Name sshd -ErrorAction Stop
```

## 5. Validate effective sshd settings

```powershell
$sshdExePath = Join-Path -Path $env:WINDIR -ChildPath "System32\OpenSSH\sshd.exe"
$effective = & $sshdExePath -T 2>$null
$effective | Select-String -Pattern '^authorizedkeysfile\s+\.ssh/authorized_keys$','^pubkeyauthentication\s+yes$'
```

If `authorizedkeysfile` does not show `.ssh/authorized_keys`, admin logins may still depend on `administrators_authorized_keys`.

## 6. Create target user `.ssh` directory

```powershell
if (-not (Test-Path -Path $SshDir)) {
    New-Item -Path $SshDir -ItemType Directory -Force | Out-Null
}
```

## 7. Set ACL on `.ssh` folder

```powershell
$acl = Get-Acl -Path $SshDir
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }

$userRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $TargetIdentity,
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "NT AUTHORITY\SYSTEM",
    "FullControl",
    "ContainerInherit,ObjectInherit",
    "None",
    "Allow"
)
$acl.AddAccessRule($userRule)
$acl.AddAccessRule($systemRule)
Set-Acl -Path $SshDir -AclObject $acl
```

## 8. Download GitHub SSH keys into `authorized_keys`

```powershell
$githubKeysUrl = "https://github.com/$GitHubUsername.keys"
$webClient = New-Object System.Net.WebClient
$publicKeys = $webClient.DownloadString($githubKeysUrl)
if ([string]::IsNullOrWhiteSpace($publicKeys)) { throw "No keys found for GitHub user" }

$keyContent = "# SSH keys from GitHub user: $GitHubUsername`n"
$keyContent += "# Downloaded on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
$keyContent += $publicKeys

Set-Content -Path $AuthorizedKeysPath -Value $keyContent -Force
```

## 9. Set ACL on `authorized_keys`

```powershell
$akAcl = Get-Acl -Path $AuthorizedKeysPath
$akAcl.SetAccessRuleProtection($true, $false)
$akAcl.Access | ForEach-Object { $akAcl.RemoveAccessRule($_) | Out-Null }

$akUserRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $TargetIdentity,
    "FullControl",
    "Allow"
)
$akSystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "NT AUTHORITY\SYSTEM",
    "FullControl",
    "Allow"
)
$akAcl.AddAccessRule($akUserRule)
$akAcl.AddAccessRule($akSystemRule)
Set-Acl -Path $AuthorizedKeysPath -AclObject $akAcl
```

## 10. Confirm target user is local admin (expected by this setup)

```powershell
Get-LocalGroupMember -Group "Administrators" | Where-Object { $_.Name -eq $TargetIdentity -or $_.Name -eq $TargetUsername }
```

## 11. Test SSH login

From another machine:

```bash
ssh mdelgert@<windows-hostname-or-ip>
```

From the same machine (loopback test):

```powershell
ssh $TargetUsername@localhost
```

## Troubleshooting

- If login only works with `C:\ProgramData\ssh\administrators_authorized_keys`:
  - Recheck `sshd_config` for active `Match Group administrators` block.
  - Run `sshd.exe -T` and verify `authorizedkeysfile .ssh/authorized_keys`.
  - Restart `sshd` after config changes.
- If key auth fails:
  - Recheck ACLs on `.ssh` and `authorized_keys`.
  - Verify keys exist at `https://github.com/mdelgert.keys`.
- Check service and events:

```powershell
Get-Service sshd,ssh-agent
Get-WinEvent -LogName "Microsoft-Windows-OpenSSH/Operational" -MaxEvents 50
```

## Rollback

- Restore latest backup of `C:\ProgramData\ssh\sshd_config`.
- Restart SSH service:

```powershell
Restart-Service sshd
```
