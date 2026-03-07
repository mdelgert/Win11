#Requires -Version 5.1
#.ssh-server.ps1 -GitHubUsername mdelgert -TargetUsername mdelgert

[CmdletBinding()]
param(
    [string]$GitHubUsername = "mdelgert",
    [string]$TargetUsername = ""
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "=============================================================="
Write-Host "Script: ssh-server.ps1"
Write-Host "Description: Setup SSH server script."
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "OS Version: $([Environment]::OSVersion.Version)"
Write-Host "Working directory: $(Get-Location)"
Write-Host "=============================================================="
Write-Host ""

# Configuration
$SSHPort = 22

# Function to write log messages with timestamp
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARNING" { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Function to test internet connectivity
function Test-InternetConnection {
    try {
        $result = Test-NetConnection -ComputerName "api.github.com" -Port 443 -InformationLevel Quiet -ErrorAction Stop -WarningAction SilentlyContinue
        return $result
    }
    catch {
        return $false
    }
}

# Function to backup file before modification
function Backup-FileIfExists {
    param([string]$FilePath)
    if (Test-Path -Path $FilePath) {
        $backupPath = "$FilePath.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        try {
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Log "Backed up $FilePath to $backupPath" "SUCCESS"
            return $backupPath
        }
        catch {
            Write-Log "Failed to backup $FilePath : $_" "ERROR"
            return $null
        }
    }
    return $null
}

# Resolve a local profile path for a target account.
function Resolve-UserProfilePath {
    param([string]$Username)

    if ([string]::IsNullOrWhiteSpace($Username)) {
        return $null
    }

    $defaultProfilePath = Join-Path -Path $env:SystemDrive -ChildPath ("Users\" + $Username)
    if (Test-Path -Path $defaultProfilePath) {
        return $defaultProfilePath
    }

    try {
        $profileListPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"
        $profileItems = Get-ChildItem -Path $profileListPath -ErrorAction Stop
        foreach ($profileItem in $profileItems) {
            $profileImagePath = (Get-ItemProperty -Path $profileItem.PSPath -Name ProfileImagePath -ErrorAction SilentlyContinue).ProfileImagePath
            if (-not [string]::IsNullOrWhiteSpace($profileImagePath)) {
                $expandedPath = [System.Environment]::ExpandEnvironmentVariables($profileImagePath)
                if ($expandedPath -match ([regex]::Escape("\\" + $Username) + "$")) {
                    return $expandedPath
                }
            }
        }
    }
    catch {
        Write-Log "Could not resolve profile via registry for user ${Username}: $_" "WARNING"
    }

    return $defaultProfilePath
}

# Function to set active network profiles to Private
function Set-NetworkProfilePrivate {
    Write-Log "Checking active network profile(s)..."

    try {
        $profiles = Get-NetConnectionProfile -ErrorAction Stop

        if (-not $profiles) {
            Write-Log "No network profiles were found." "WARNING"
            return
        }

        foreach ($profile in $profiles) {
            Write-Log "Network '$($profile.Name)' current category: $($profile.NetworkCategory)"

            if ($profile.NetworkCategory -ne 'Private') {
                Set-NetConnectionProfile -InterfaceIndex $profile.InterfaceIndex -NetworkCategory Private -ErrorAction Stop
                Write-Log "Changed network '$($profile.Name)' to Private" "SUCCESS"
            }
            else {
                Write-Log "Network '$($profile.Name)' is already Private" "SUCCESS"
            }
        }
    }
    catch {
        Write-Log "Failed to set network profile to Private: $($_.Exception.Message)" "WARNING"
    }
}

try {
    # Step 1: Check if running as Administrator
    Write-Log "Checking administrator privileges..."
    $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    $isAdmin = $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    
    if (-not $isAdmin) {
        Write-Log "This script must be run as Administrator!" "ERROR"
        exit 1
    }
    Write-Log "Administrator privileges confirmed" "SUCCESS"

    # Resolve target account for SSH key placement.
    $resolvedTargetUsername = $TargetUsername
    if ([string]::IsNullOrWhiteSpace($resolvedTargetUsername)) {
        if ($env:USERNAME -and $env:USERNAME -ne "SYSTEM") {
            $resolvedTargetUsername = $env:USERNAME
        }
        else {
            $resolvedTargetUsername = $GitHubUsername
        }
    }

    $targetIdentity = "$env:COMPUTERNAME\$resolvedTargetUsername"
    Write-Log "Target Windows account for SSH login: $targetIdentity"

    $targetUserProfilePath = Resolve-UserProfilePath -Username $resolvedTargetUsername
    if ([string]::IsNullOrWhiteSpace($targetUserProfilePath)) {
        Write-Log "Could not resolve profile path for user $resolvedTargetUsername" "ERROR"
        exit 1
    }
    Write-Log "Resolved target profile path: $targetUserProfilePath"

    # Step 2: Check OpenSSH Server capability
    Write-Log "Checking OpenSSH Server installation status..."
    $sshServerFeature = Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Server*'
    
    if ($null -eq $sshServerFeature) {
        Write-Log "OpenSSH Server capability not found on this system" "ERROR"
        exit 1
    }

    # Step 3: Install OpenSSH Server if not installed
    if ($sshServerFeature.State -ne "Installed") {
        Write-Log "Installing OpenSSH Server..."
        try {
            Add-WindowsCapability -Online -Name $sshServerFeature.Name -ErrorAction Stop
            Write-Log "OpenSSH Server installed successfully" "SUCCESS"
        }
        catch {
            Write-Log "Failed to install OpenSSH Server: $_" "ERROR"
            exit 1
        }
    }
    else {
        Write-Log "OpenSSH Server is already installed" "SUCCESS"
    }

    # Step 4: Configure and start SSH service
    Write-Log "Configuring SSH service..."
    try {
        Set-Service -Name sshd -StartupType 'Automatic' -ErrorAction Stop
        Write-Log "SSH service set to automatic startup" "SUCCESS"
        
        $sshdService = Get-Service -Name sshd
        if ($sshdService.Status -ne "Running") {
            Start-Service -Name sshd -ErrorAction Stop
            Write-Log "SSH service started" "SUCCESS"
        }
        else {
            Write-Log "SSH service is already running" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to configure or start SSH service: $_" "ERROR"
        exit 1
    }

    # Step 5: Configure SSH Agent service
    Write-Log "Configuring SSH Agent service..."
    try {
        Set-Service -Name ssh-agent -StartupType 'Automatic' -ErrorAction Stop
        Start-Service -Name ssh-agent -ErrorAction Stop
        Write-Log "SSH Agent service configured and started" "SUCCESS"
    }
    catch {
        Write-Log "Warning: Failed to configure SSH Agent service: $_" "WARNING"
    }

    # Step 6: Set trusted homelab network profile to Private
    Write-Log "Setting trusted homelab network profile to Private..."
    Set-NetworkProfilePrivate

    # Step 7: Configure firewall rule for SSH
    Write-Log "Configuring firewall rule for port $SSHPort..."
    try {
        $firewallRule = Get-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -ErrorAction SilentlyContinue
        if ($null -eq $firewallRule) {
            New-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -DisplayName "OpenSSH Server (sshd)" -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort $SSHPort -Profile Any -ErrorAction Stop
            Write-Log "Firewall rule created for port $SSHPort" "SUCCESS"
        }
        else {
            Set-NetFirewallRule -Name "OpenSSH-Server-In-TCP" -Enabled True -Profile Any -ErrorAction Stop
            Write-Log "Firewall rule already exists and is enabled" "SUCCESS"
        }
    }
    catch {
        Write-Log "Failed to configure firewall rule: $_" "ERROR"
        exit 1
    }

    # Step 8: Configure sshd_config to allow admin users with individual authorized_keys
    Write-Log "Configuring SSH server settings..."
    $sshdConfigPath = "$env:ProgramData\ssh\sshd_config"
    
    if (Test-Path -Path $sshdConfigPath) {
        # Backup the config file
        $backupPath = Backup-FileIfExists -FilePath $sshdConfigPath
        
        try {
            $configContent = Get-Content -Path $sshdConfigPath -Raw
            $modified = $false

            # Comment out or remove the administrators_authorized_keys override
            if ($configContent -match '(?m)^\s*Match Group administrators\s*$') {
                Write-Log "Found 'Match Group administrators' block, commenting it out..."
                $configContent = $configContent -replace '(?m)^(\s*Match Group administrators.*)$', '# $1 # Disabled: use per-user authorized_keys'
                $configContent = $configContent -replace '(?m)^(\s*AuthorizedKeysFile\s+__PROGRAMDATA__/ssh/administrators_authorized_keys\s*)$', '# $1 # Disabled: use per-user authorized_keys'
                $modified = $true
            }

            # Ensure PubkeyAuthentication is enabled
            if ($configContent -match '(?m)^\s*#?\s*PubkeyAuthentication\s+no\s*$') {
                $configContent = $configContent -replace '(?m)^\s*#?\s*PubkeyAuthentication\s+no.*$', 'PubkeyAuthentication yes'
                $modified = $true
            }
            elseif ($configContent -notmatch '(?m)^\s*PubkeyAuthentication\s+yes\s*$') {
                $configContent += "`nPubkeyAuthentication yes`n"
                $modified = $true
            }

            # Explicitly set PasswordAuthentication yes unless managed elsewhere.
            if ($configContent -match '(?m)^\s*#?\s*PasswordAuthentication\s+') {
                $configContent = $configContent -replace '(?m)^\s*#?\s*PasswordAuthentication\s+.*$', 'PasswordAuthentication yes'
                $modified = $true
            }
            else {
                $configContent += "PasswordAuthentication yes`n"
                $modified = $true
            }

            # Set AuthorizedKeysFile to use user profile
            if ($configContent -notmatch '(?m)^\s*AuthorizedKeysFile\s+\.ssh/authorized_keys\s*$') {
                if ($configContent -match '(?m)^\s*#?\s*AuthorizedKeysFile\s+') {
                    $configContent = $configContent -replace '(?m)^\s*#?\s*AuthorizedKeysFile.*$', 'AuthorizedKeysFile .ssh/authorized_keys'
                }
                else {
                    $configContent += "AuthorizedKeysFile .ssh/authorized_keys`n"
                }
                $modified = $true
            }

            if ($modified) {
                Set-Content -Path $sshdConfigPath -Value $configContent -Force
                Write-Log "SSH server configuration updated" "SUCCESS"
                
                # Restart SSH service to apply changes
                Restart-Service -Name sshd -ErrorAction Stop
                Write-Log "SSH service restarted to apply configuration changes" "SUCCESS"
            }
            else {
                Write-Log "SSH configuration already correct" "SUCCESS"
            }

            # Validate effective sshd settings after restart/update.
            $sshdExePath = Join-Path -Path $env:WINDIR -ChildPath "System32\OpenSSH\sshd.exe"
            if (Test-Path -Path $sshdExePath) {
                $effectiveConfigOutput = & $sshdExePath -T 2>$null
                $effectiveConfigText = $effectiveConfigOutput -join "`n"
                if ($effectiveConfigText -notmatch '(?m)^authorizedkeysfile\s+\.ssh/authorized_keys\s*$') {
                    Write-Log "Effective sshd config is not using per-user authorized_keys. Check $sshdConfigPath." "ERROR"
                    exit 1
                }
                if ($effectiveConfigText -notmatch '(?m)^pubkeyauthentication\s+yes\s*$') {
                    Write-Log "Effective sshd config does not have pubkeyauthentication enabled." "ERROR"
                    exit 1
                }
                Write-Log "Effective sshd settings validated" "SUCCESS"
            }
            else {
                Write-Log "Could not validate effective sshd config because sshd.exe was not found at $sshdExePath" "WARNING"
            }
        }
        catch {
            Write-Log "Failed to configure sshd_config: $_" "ERROR"
            if ($backupPath) {
                Write-Log "Restoring backup from $backupPath..." "WARNING"
                Copy-Item -Path $backupPath -Destination $sshdConfigPath -Force
            }
            exit 1
        }
    }
    else {
        Write-Log "SSH config file not found at $sshdConfigPath" "ERROR"
        exit 1
    }

    # Step 9: Create .ssh directory for target user
    Write-Log "Setting up .ssh directory for user $targetIdentity..."
    $sshDir = Join-Path -Path $targetUserProfilePath -ChildPath ".ssh"
    
    if (-not (Test-Path -Path $sshDir)) {
        try {
            New-Item -Path $sshDir -ItemType Directory -Force -ErrorAction Stop | Out-Null
            Write-Log "Created .ssh directory at $sshDir" "SUCCESS"
        }
        catch {
            Write-Log "Failed to create .ssh directory: $_" "ERROR"
            exit 1
        }
    }
    else {
        Write-Log ".ssh directory already exists" "SUCCESS"
    }

    # Step 10: Set correct permissions on .ssh directory
    Write-Log "Setting permissions on .ssh directory..."
    try {
        $acl = Get-Acl -Path $sshDir
        $acl.SetAccessRuleProtection($true, $false)  # Disable inheritance
        
        # Remove all existing access rules
        $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
        
        # Add full control for target user account
        $currentUser = $targetIdentity
        $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $currentUser,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($accessRule)
        
        # Add full control for SYSTEM
        $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            "NT AUTHORITY\SYSTEM",
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )
        $acl.AddAccessRule($systemRule)
        
        Set-Acl -Path $sshDir -AclObject $acl
        Write-Log "Permissions set correctly on .ssh directory" "SUCCESS"
    }
    catch {
        Write-Log "Failed to set permissions on .ssh directory: $_" "WARNING"
    }

    # Step 11: Fetch SSH public keys from GitHub
    Write-Log "Fetching SSH public keys from GitHub for user: $GitHubUsername..."
    
    # Check internet connectivity
    if (-not (Test-InternetConnection)) {
        Write-Log "No internet connection available. Cannot fetch keys from GitHub." "WARNING"
        Write-Log "You can manually add your public key to: $sshDir\authorized_keys" "WARNING"
    }
    else {
        try {
            $authorizedKeysPath = Join-Path -Path $sshDir -ChildPath "authorized_keys"
            $githubKeysUrl = "https://github.com/$GitHubUsername.keys"
            
            Write-Log "Downloading keys from $githubKeysUrl..."
            $webClient = New-Object System.Net.WebClient
            $publicKeys = $webClient.DownloadString($githubKeysUrl)
            
            if ([string]::IsNullOrWhiteSpace($publicKeys)) {
                Write-Log "No public keys found for GitHub user: $GitHubUsername" "WARNING"
            }
            else {
                # Backup existing authorized_keys if it exists
                Backup-FileIfExists -FilePath $authorizedKeysPath | Out-Null
                
                # Add comment with timestamp
                $keyContent = "# SSH keys from GitHub user: $GitHubUsername`n"
                $keyContent += "# Downloaded on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n"
                $keyContent += $publicKeys
                
                Set-Content -Path $authorizedKeysPath -Value $keyContent -Force
                Write-Log "SSH public keys saved to $authorizedKeysPath" "SUCCESS"
                
                # Set correct permissions on authorized_keys file
                $acl = Get-Acl -Path $authorizedKeysPath
                $acl.SetAccessRuleProtection($true, $false)
                $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) | Out-Null }
                
                $currentUser = $targetIdentity
                $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    $currentUser,
                    "FullControl",
                    "Allow"
                )
                $acl.AddAccessRule($accessRule)
                
                $systemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
                    "NT AUTHORITY\SYSTEM",
                    "FullControl",
                    "Allow"
                )
                $acl.AddAccessRule($systemRule)
                
                Set-Acl -Path $authorizedKeysPath -AclObject $acl
                Write-Log "Permissions set correctly on authorized_keys file" "SUCCESS"
                
                # Display key count
                $keyCount = ($publicKeys -split "`n" | Where-Object { $_ -match '^ssh-' }).Count
                Write-Log "Successfully imported $keyCount SSH key(s)" "SUCCESS"
            }
        }
        catch {
            Write-Log "Failed to fetch SSH keys from GitHub: $_" "ERROR"
            Write-Log "You can manually add your public key to: $sshDir\authorized_keys" "WARNING"
        }
    }

    # Step 12: Verify administrator group membership
    Write-Log "Verifying administrator privileges for user $targetIdentity..."
    try {
        $isInAdminGroup = $false
        $administratorsGroupMembers = Get-LocalGroupMember -Group "Administrators" -ErrorAction Stop
        foreach ($groupMember in $administratorsGroupMembers) {
            if ($groupMember.Name -eq $targetIdentity -or $groupMember.Name -eq $resolvedTargetUsername) {
                $isInAdminGroup = $true
                break
            }
        }
        if ($isInAdminGroup) {
            Write-Log "User $targetIdentity has administrator privileges" "SUCCESS"
        }
        else {
            Write-Log "Note: User $targetIdentity may not have administrator privileges" "WARNING"
        }
    }
    catch {
        Write-Log "Could not verify administrator group membership: $_" "WARNING"
    }

    # Final summary
    Write-Host ""
    Write-Host "=============================================================="
    Write-Log "SSH Server Setup Complete!" "SUCCESS"
    Write-Host "=============================================================="
    Write-Log "SSH Server is running on port $SSHPort"
    Write-Log "Firewall rule is configured"
    Write-Log "Admin users can use individual authorized_keys files"
    Write-Log "Your authorized_keys location: $sshDir\authorized_keys"
    Write-Host ""
    Write-Log "To connect to this server, use:"
    Write-Host "  ssh $resolvedTargetUsername@$(hostname)" -ForegroundColor Cyan
    Write-Host ""
    Write-Log "For troubleshooting, check logs at:"
    Write-Host "  C:\ProgramData\ssh\logs\" -ForegroundColor Cyan
    Write-Host "=============================================================="
    Write-Host ""
}
catch {
    Write-Log "Unexpected error occurred: $_" "ERROR"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "ERROR"
    exit 1
}
