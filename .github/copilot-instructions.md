# Copilot Instructions for Windows 11 Automation Project

## PowerShell Version
- **Use PowerShell 5.1** (Windows PowerShell), NOT PowerShell 7+ (pwsh)
- Target `$PSVersionTable.PSVersion.Major -eq 5`
- Scripts run during Windows Setup/OOBE where only Windows PowerShell is available

## PowerShell Best Practices

### Syntax & Style
- Use full cmdlet names, not aliases (`Get-ChildItem` not `gci`, `ForEach-Object` not `%`)
- Use approved verbs for function names (Get-, Set-, New-, Remove-, etc.)
- Use PascalCase for function names and camelCase for variables
- Always use explicit parameter names for clarity

### Error Handling
- Use `try/catch/finally` blocks for error handling
- Set `$ErrorActionPreference = 'Stop'` when errors should halt execution
- Use `-ErrorAction Stop` on critical cmdlets
- Log errors with timestamps using `Write-Host` or output to log files

### Compatibility
- Avoid PowerShell 7+ features:
  - No ternary operators (`$x ? $a : $b`)
  - No null-coalescing (`??`, `??=`)
  - No pipeline chain operators (`&&`, `||`)
  - No `ForEach-Object -Parallel`
- Use `[System.Environment]::OSVersion` for OS detection
- Use full .NET type names with brackets: `[System.IO.Path]::Combine()`

### File & Path Handling
- Use `Join-Path` for path construction
- Use `Test-Path` before file/folder operations
- Always use `-Force` consciously (document why if used)
- Prefer `$env:SystemRoot`, `$env:ProgramFiles`, `$env:USERPROFILE` over hardcoded paths

### Security
- Never store credentials in plain text
- Use `-Credential` parameter with `Get-Credential` when needed
- Scripts may run as SYSTEM during setup - account for this context

## Project Context
- This project automates Windows 11 installation and configuration
- Scripts in `steps/` are executed sequentially by Bootstrap.ps1
- `autounattend.xml` handles unattended Windows installation
- `$OEM$` folder structure is copied to the Windows installation

## Execution Environment
- Scripts may run without network connectivity initially
- Scripts may run before user profile exists
- Scripts may run in WinPE or during OOBE
- Always check prerequisites before depending on them

## Winget Usage
- Winget may not be available during early setup phases
- Use `Get-Command winget -ErrorAction SilentlyContinue` to check availability
- Consider `--accept-package-agreements --accept-source-agreements` flags
