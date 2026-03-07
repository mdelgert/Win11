$timeout = [datetime]::Now.AddMinutes(5)
$gitExe = "C:\Program Files\Git\cmd\git.exe"
$repoUrl = "https://github.com/mdelgert/win11.git"
$repoDir = "C:\source\win11"
$setupScript = "$repoDir\setup.ps1"

# Install Git if not already installed
winget install --id Git.Git -e --source winget --silent --accept-package-agreements --accept-source-agreements --source winget --scope machine

# Wait for Git to become available
while ($true) {
    if ($gitExe | Test-Path) {
        break
    }
    if ([datetime]::Now -gt $timeout) {
        Write-Warning "File '${gitExe}' does not exist."
        return
    }
    Write-Host "Waiting for '${gitExe}' to become available..."
    Start-Sleep -Seconds 1
}

# Clone the repository
& $gitExe clone $repoUrl $repoDir

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