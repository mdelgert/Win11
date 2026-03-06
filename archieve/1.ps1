$timeout = [datetime]::Now.AddMinutes( 5 );
$exe = "$env:LOCALAPPDATA\Microsoft\WindowsApps\winget.exe";

while( $true ) {
    if( $exe | Test-Path ) {
        & $exe install --exact --id Git.Git --source winget --silent --accept-package-agreements --accept-source-agreements --source winget --scope machine;
        return;
    }
    if( [datetime]::Now -gt $timeout ) {
        "File '${exe}' does not exist." | Write-Warning;
        return;
    }
    "Waiting for '${exe}' to become available..." | Write-Host;
    Start-Sleep -Seconds 1;
}