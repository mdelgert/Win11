# Requires -RunAsAdministrator

$timeout = [datetime]::Now.AddMinutes( 5 )
$exe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe"

# Put Winget package IDs here
$apps = @(
    # 'Microsoft.Sysinternals.Autologon',
    # 'Mozilla.Firefox',
    'Synology.ActiveBackupForBusinessAgent'
)

while( $true ) {
    if( $exe | Test-Path ) {

        foreach( $id in $apps ) {
            "Installing $id ..." | Write-Host

            & $exe install `
                --exact --id $id `
                --silent `
                --accept-package-agreements --accept-source-agreements `
                --source winget `
                --scope machine

            if( $LASTEXITCODE -ne 0 ) {
                "winget returned exit code $LASTEXITCODE for $id" | Write-Warning
            } else {
                "Installed $id" | Write-Host
            }
        }

        return
    }

    if( [datetime]::Now -gt $timeout ) {
        "File '${exe}' does not exist." | Write-Warning
        return
    }

    "Waiting for '${exe}' to become available..." | Write-Host
    Start-Sleep -Seconds 1
}