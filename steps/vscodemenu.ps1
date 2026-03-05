#Requires -Version 5.1
# vscodemenu.ps1
# Compatible with Windows PowerShell 5.1

# Add "Open with Code" context menu for folders and background
$codeExe = Join-Path $env:ProgramFiles 'Microsoft VS Code\Code.exe'
if (-not (Test-Path $codeExe)) {
    $codeExe = Join-Path $env:LOCALAPPDATA 'Programs\Microsoft VS Code\Code.exe'
}
if (-not (Test-Path $codeExe)) {
    throw "Could not find Code.exe. Install VS Code first."
}

# Folder context menu
New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode" -Name "(Default)" -Value "Open with Code" -Force
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode" -Name "Icon" -Value "`"$codeExe`"" -Force
New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\shell\VSCode\command" -Name "(Default)" -Value "`"$codeExe`" `"%V`"" -Force

# Background (right-click inside folder)
New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode" -Name "(Default)" -Value "Open with Code" -Force
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode" -Name "Icon" -Value "`"$codeExe`"" -Force
New-Item -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode\command" -Force | Out-Null
Set-ItemProperty -Path "Registry::HKEY_CLASSES_ROOT\Directory\Background\shell\VSCode\command" -Name "(Default)" -Value "`"$codeExe`" `"%V`"" -Force

# Restart Explorer to refresh context menus
Stop-Process -Name explorer -Force
Start-Process explorer