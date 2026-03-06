$timeout = [datetime]::Now.AddMinutes( 5 );
$exe = "C:\source\win11\setup.ps1";

while( $true ) {
    if( $exe | Test-Path ) {
        & $exe configure --enable;
        return;
    }
    if( [datetime]::Now -gt $timeout ) {
        "File '${exe}' does not exist." | Write-Warning;
        return;
    }
    "Waiting for '${exe}' to become available..." | Write-Host;
    Start-Sleep -Seconds 1;
}