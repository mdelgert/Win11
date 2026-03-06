Write-Host ""
Write-Host "==============================="
Write-Host "Running 01-winget-configure.ps1"
Write-Host "Machine: $env:COMPUTERNAME"
Write-Host "User: $env:USERNAME"
Write-Host "Time: $(Get-Date)"
Write-Host "==============================="
Write-Host ""
Start-Sleep -Seconds 2

$timeout = [datetime]::Now.AddMinutes(5)
$exe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

# Enable winget configuration
while ($true) {
    if ($exe | Test-Path) {
        & $exe configure --enable
        break
    }
    if ([datetime]::Now -gt $timeout) {
        Write-Warning "File '${exe}' does not exist."
        return
    }
    Write-Host "Waiting for '${exe}' to become available..."
    Start-Sleep -Seconds 1
}