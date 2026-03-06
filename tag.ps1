<#
.SYNOPSIS
Auto-increments the latest semantic version git tag, creates a new annotated tag, and pushes it.

.DESCRIPTION
This script finds the highest existing tag in the format:
    vMAJOR.MINOR.PATCH

It increments PATCH by 1, creates the new annotated tag, and pushes it to origin.

If no matching tags exist yet, it starts at:
    v1.0.0

The script also prints the exact git commands it runs so you can learn the workflow.

GIT COMMANDS USED
-----------------
1. Fetch tags from remote:
   git fetch --tags

2. List all tags:
   git tag --list

3. Create a new annotated tag:
   git tag -a v1.0.0 -m "Release v1.0.0"

4. Push the new tag to origin:
   git push origin v1.0.0

EXAMPLES
--------
Run from the root of your git repo:
    .\tag.ps1

Optional custom message:
    .\tag.ps1 -Message "Build unattend.iso release"
#>

[CmdletBinding()]
param(
    [string]$Message
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Command {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text
    )

    Write-Host ""
    Write-Host ">> $Text" -ForegroundColor Cyan
}

function Test-CommandExists {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    return $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Get-NextVersionTag {
    param(
        [string[]]$Tags = @()
    )

    $validTags = foreach ($tag in $Tags) {
        if ($tag -match '^v(\d+)\.(\d+)\.(\d+)$') {
            [pscustomobject]@{
                Original = $tag
                Major    = [int]$Matches[1]
                Minor    = [int]$Matches[2]
                Patch    = [int]$Matches[3]
            }
        }
    }

    if (-not $validTags -or $validTags.Count -eq 0) {
        return 'v1.0.0'
    }

    $latest = $validTags |
        Sort-Object Major, Minor, Patch |
        Select-Object -Last 1

    $newPatch = $latest.Patch + 1
    return ('v{0}.{1}.{2}' -f $latest.Major, $latest.Minor, $newPatch)
}

if (-not (Test-CommandExists -Name 'git')) {
    throw 'git is not installed or not in PATH.'
}

if (-not (Test-Path '.git')) {
    throw 'Current folder is not a git repository.'
}

Write-Command 'git fetch --tags'
git fetch --tags
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to fetch tags from remote.'
}

Write-Command 'git tag --list'
$allTags = @(git tag --list)
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to list git tags.'
}

$nextTag = Get-NextVersionTag -Tags $allTags

if ([string]::IsNullOrWhiteSpace($Message)) {
    $Message = "Release $nextTag"
}

Write-Host ""
Write-Host "Next tag: $nextTag" -ForegroundColor Green
Write-Host "Tag message: $Message" -ForegroundColor Green

Write-Command "git tag -a $nextTag -m `"$Message`""
git tag -a $nextTag -m $Message
if ($LASTEXITCODE -ne 0) {
    throw "Failed to create tag '$nextTag'."
}

Write-Command "git push origin $nextTag"
git push origin $nextTag
if ($LASTEXITCODE -ne 0) {
    throw "Failed to push tag '$nextTag' to origin."
}

Write-Host ""
Write-Host "Done. Created and pushed tag $nextTag" -ForegroundColor Yellow