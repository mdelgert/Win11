# Requires -RunAsAdministrator
# Compatible with Windows PowerShell 5.1

$timeout = [datetime]::Now.AddMinutes(5)
$winget = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"
$gitExe = "C:\Program Files\Git\cmd\git.exe"
$repoUrl = "https://github.com/mdelgert/win11.git"
$repoDir = "C:\source\win11"
$setupScript = "$repoDir\setup.ps1"

# Wait for winget
while ($true) {

    if (Test-Path $winget) {

        Write-Host "Installing Git..."

        & $winget install `
            --exact --id Git.Git `
            --silent `
            --accept-package-agreements --accept-source-agreements `
            --source winget `
            --scope machine

        break
    }

    if ([datetime]::Now -gt $timeout) {
        Write-Warning "Winget not found."
        return
    }

    Write-Host "Waiting for winget..."
    Start-Sleep 2
}

# Wait for git.exe to exist
while ($true) {

    if (Test-Path $gitExe) {
        Write-Host "Git detected."
        break
    }

    if ([datetime]::Now -gt $timeout) {
        Write-Warning "Git installation timeout."
        return
    }

    Write-Host "Waiting for Git install..."
    Start-Sleep 2
}

# Clone repository using full path
& $gitExe clone $repoUrl $repoDir

# Wait for setup script
while ($true) {

    if (Test-Path $setupScript) {
        Write-Host "Running setup script..."
        & $setupScript
        return
    }

    if ([datetime]::Now -gt $timeout) {
        Write-Warning "Setup script not found."
        return
    }

    Write-Host "Waiting for setup script..."
    Start-Sleep 2
}