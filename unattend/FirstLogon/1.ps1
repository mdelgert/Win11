$timeout = [datetime]::Now.AddMinutes(5)
$exe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$repoUrl = "https://github.com/mdelgert/win11.git"
$repoDir = "C:\source\win11"
$setupScript = "$repoDir\setup.ps1"

# Install git using winget
while ($true) {
    if ($exe | Test-Path) {
        & $exe install --exact --id Git.Git --silent --accept-package-agreements --accept-source-agreements --source winget --scope machine
        break
    }
    if ([datetime]::Now -gt $timeout) {
        Write-Warning "File '${exe}' does not exist."
        return
    }
    Write-Host "Waiting for '${exe}' to become available..."
    Start-Sleep -Seconds 1
}

# Clone the repository
git clone $repoUrl $repoDir

# Wait for the setup script to become available and execute it
while ($true) {
    if ($setupScript | Test-Path) {
        & $setupScript
        return
    }
    if ([datetime]::Now -gt $timeout) {
        Write-Warning "File '${setupScript}' does not exist."
        return
    }
    Write-Host "Waiting for '${setupScript}' to become available..."
    Start-Sleep -Seconds 1
}