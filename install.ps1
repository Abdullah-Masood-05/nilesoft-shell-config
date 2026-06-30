#Requires -Version 5.1
<#
.SYNOPSIS
    Installs this Nilesoft Shell configuration into your Nilesoft Shell
    installation, backs up the existing config, and reloads the menu.

.DESCRIPTION
    - Locates your Nilesoft Shell install (Program Files or registry).
    - Backs up the current shell.nss + imports\ to a timestamped folder.
    - Copies this repo's shell.nss and imports\*.nss into place.
    - Runs  shell.exe -register  and  shell.exe -restart  to apply.

    The script self-elevates (UAC) because the install lives under
    C:\Program Files, which requires administrator rights to write to.

.PARAMETER ShellDir
    Override the Nilesoft Shell directory (where shell.exe lives).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\install.ps1
#>
[CmdletBinding()]
param(
    [string]$ShellDir = ''
)

$ErrorActionPreference = 'Stop'
$RepoRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

function Get-ShellDir {
    param([string]$Override)
    if ($Override) {
        if (Test-Path (Join-Path $Override 'shell.exe')) { return $Override }
        throw "shell.exe not found in '$Override'."
    }
    $candidates = @(
        (Join-Path $env:ProgramFiles 'Nilesoft Shell'),
        (Join-Path ${env:ProgramFiles(x86)} 'Nilesoft Shell')
    )
    foreach ($c in $candidates) { if ($c -and (Test-Path (Join-Path $c 'shell.exe'))) { return $c } }

    $uninstallKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    foreach ($k in $uninstallKeys) {
        $hit = Get-ItemProperty $k -ErrorAction SilentlyContinue |
               Where-Object { $_.DisplayName -like '*Nilesoft Shell*' -and $_.InstallLocation }
        if ($hit) {
            $loc = ($hit | Select-Object -First 1).InstallLocation
            if (Test-Path (Join-Path $loc 'shell.exe')) { return $loc }
        }
    }
    return $null
}

# ---- self-elevate if needed -------------------------------------------------
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Requesting administrator privileges (UAC)...' -ForegroundColor Yellow
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath))
    if ($ShellDir) { $argList += @('-ShellDir',('"{0}"' -f $ShellDir)) }
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList
    return
}

Write-Host ''
Write-Host '  Nilesoft Shell config installer' -ForegroundColor Cyan
Write-Host '  -------------------------------' -ForegroundColor Cyan

$dir = Get-ShellDir -Override $ShellDir
if (-not $dir) {
    Write-Warning 'Nilesoft Shell does not appear to be installed.'
    Write-Host   'Install it first, then re-run this script. For example:' -ForegroundColor Yellow
    Write-Host   '    winget install --id Nilesoft.Shell -e' -ForegroundColor Green
    Write-Host   'or download it from https://nilesoft.org' -ForegroundColor Yellow
    Read-Host "`nPress Enter to close"
    exit 1
}
Write-Host "  Found Nilesoft Shell at: $dir" -ForegroundColor Green

# ---- back up the existing config -------------------------------------------
$stamp  = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = Join-Path $dir "config-backup-$stamp"
New-Item -ItemType Directory -Force -Path (Join-Path $backup 'imports') | Out-Null
if (Test-Path (Join-Path $dir 'shell.nss')) {
    Copy-Item (Join-Path $dir 'shell.nss') (Join-Path $backup 'shell.nss') -Force
}
if (Test-Path (Join-Path $dir 'imports')) {
    Copy-Item (Join-Path $dir 'imports\*.nss') (Join-Path $backup 'imports') -Force -ErrorAction SilentlyContinue
}
Write-Host "  Backed up current config to: $backup" -ForegroundColor DarkGray

# ---- copy this repo's config into place ------------------------------------
New-Item -ItemType Directory -Force -Path (Join-Path $dir 'imports') | Out-Null
Copy-Item (Join-Path $RepoRoot 'shell.nss')      (Join-Path $dir 'shell.nss') -Force
Copy-Item (Join-Path $RepoRoot 'imports\*.nss')  (Join-Path $dir 'imports')   -Force
Write-Host '  Copied shell.nss and imports\*.nss' -ForegroundColor Green

# ---- register + reload ------------------------------------------------------
$exe = Join-Path $dir 'shell.exe'
Start-Process -FilePath $exe -ArgumentList '-register' -Wait -WindowStyle Hidden
Start-Process -FilePath $exe -ArgumentList '-restart'  -Wait -WindowStyle Hidden
Write-Host '  Registered and reloaded the menu.' -ForegroundColor Green

# ---- report log status ------------------------------------------------------
$log = Join-Path $dir 'shell.log'
if (Test-Path $log) {
    $errs = Select-String -Path $log -Pattern 'error|fail|invalid|unexpected' -ErrorAction SilentlyContinue
    if ($errs) { Write-Warning "shell.log reported issues:`n$($errs -join "`n")" }
    else       { Write-Host '  shell.log is clean - no errors.' -ForegroundColor Green }
}

Write-Host "`n  Done! Hold CTRL and right-click anywhere to see the menu." -ForegroundColor Cyan
Read-Host "`nPress Enter to close"
