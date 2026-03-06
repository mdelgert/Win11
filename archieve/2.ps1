$timeout = [datetime]::Now.AddMinutes( 5 );
$exe = "C:\Program Files\Git\cmd\git.exe";
$repoUrl = "https://github.com/mdelgert/win11.git"
$repoDir = "C:\source\win11"

while( $true ) {
    if( $exe | Test-Path ) {
        & $exe clone $repoUrl $repoDir;
        return;
    }
    if( [datetime]::Now -gt $timeout ) {
        "File '${exe}' does not exist." | Write-Warning;
        return;
    }
    "Waiting for '${exe}' to become available..." | Write-Host;
    Start-Sleep -Seconds 1;
}