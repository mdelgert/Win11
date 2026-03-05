$Username        = "mdelgert"
$Password        = "p@ssw0rd2026!"
$Domain          = "."
$WingetExe       = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$AutologonExe    = "$env:LOCALAPPDATA\Microsoft\WinGet\Packages\Microsoft.Sysinternals.Autologon_Microsoft.Winget.Source_8wekyb3d8bbwe\Autologon.exe"
$RepoUrl         = "https://github.com/mdelgert/win11.git"
$RepoDir         = "C:\source\win11"

& $WingetExe configure --enable `

& $WingetExe install Git.Git `
    --accept-package-agreements `
    --accept-source-agreements

& $WingetExe install Microsoft.Sysinternals.Autologon `
    --accept-package-agreements `
    --accept-source-agreements

git clone $RepoUrl $RepoDir

$Timeout = [datetime]::Now.AddSeconds(10)
while (-not (Test-Path $AutologonExe)) {
    if ([datetime]::Now -gt $Timeout) {
        throw "Autologon.exe alias not created"
    }
    Start-Sleep 1
}

Write-Host "Using $AutologonExe"

Start-Process $AutologonExe `
    -ArgumentList "/accepteula $Username $Domain $Password" `
    -Wait

Restart-Computer -Force