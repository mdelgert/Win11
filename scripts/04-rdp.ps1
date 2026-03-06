# Requires -RunAsAdministrator
# Compatible with Windows PowerShell 5.1
# enable-rdp.ps1

$UserName = "mdelgert"

Write-Host "Enabling Remote Desktop..."

# Enable RDP
Set-ItemProperty `
    -Path "HKLM:\System\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" `
    -Value 0

# Enable firewall rule
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

Write-Host "Adding user '$UserName' to Remote Desktop Users group..."

try {
    Add-LocalGroupMember -Group "Remote Desktop Users" -Member $UserName -ErrorAction Stop
    Write-Host "User added successfully."
}
catch {
    Write-Warning "User may already be in the group or does not exist."
}

Write-Host "Remote Desktop is now enabled."