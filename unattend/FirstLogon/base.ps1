$Username = "mdelgert"
$Password = "p@ssw0rd2026!"
$Domain   = "."
$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$autologon = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Microsoft.Sysinternals.Autologon_Microsoft.Winget.Source_8wekyb3d8bbwe\Autologon.exe"
$repoSource = "https://github.com/mdelgert/Win11.git"
$repoDestination = "C:\source\win11"

# Wait for winget to become available
$timeout = [datetime]::Now.AddMinutes(5)
while (-not (Test-Path $winget)) {
    if ([datetime]::Now -gt $timeout) {
        throw "winget was not found within 5 minutes."
    }
    Write-Host "Waiting for winget to become available..."
    Start-Sleep 1
}

# Install Git
& $winget install Git.Git `
    --accept-package-agreements `
    --accept-source-agreements

# Install Autologon
& $winget install Microsoft.Sysinternals.Autologon `
    --accept-package-agreements `
    --accept-source-agreements

# Clone the repository
git clone $repoSource $repoDestination

# Wait briefly for the alias to appear
$timeout = [datetime]::Now.AddSeconds(10)
while (-not (Test-Path $autologon)) {
    if ([datetime]::Now -gt $timeout) {
        throw "Autologon.exe alias not created"
    }
    Start-Sleep 1
}

Write-Host "Using $autologon"

# Enable autologon
Start-Process $autologon `
    -ArgumentList "/accepteula $Username $Domain $Password" `
    -Wait

Restart-Computer -Force