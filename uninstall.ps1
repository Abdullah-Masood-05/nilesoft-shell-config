#Requires -Version 5.1
<#
.SYNOPSIS
    Restores the most recent config backup created by install.ps1 and reloads
    the menu. Use this to revert to whatever config you had before installing.

.PARAMETER ShellDir
    Override the Nilesoft Shell directory (where shell.exe lives).
#>
[CmdletBinding()]
param(
    [string]$ShellDir = ''
)

$ErrorActionPreference = 'Stop'

function Get-ShellDir {
    param([string]$Override)
    if ($Override) {
        if (Test-Path (Join-Path $Override 'shell.exe')) { return $Override }
        throw "shell.exe not found in '$Override'."
    }
    foreach ($c in @((Join-Path $env:ProgramFiles 'Nilesoft Shell'),
                     (Join-Path ${env:ProgramFiles(x86)} 'Nilesoft Shell'))) {
        if ($c -and (Test-Path (Join-Path $c 'shell.exe'))) { return $c }
    }
    return $null
}

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
           ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host 'Requesting administrator privileges (UAC)...' -ForegroundColor Yellow
    $argList = @('-NoProfile','-ExecutionPolicy','Bypass','-File',('"{0}"' -f $PSCommandPath))
    if ($ShellDir) { $argList += @('-ShellDir',('"{0}"' -f $ShellDir)) }
    Start-Process -FilePath 'powershell.exe' -Verb RunAs -ArgumentList $argList
    return
}

$dir = Get-ShellDir -Override $ShellDir
if (-not $dir) { Write-Warning 'Nilesoft Shell not found.'; Read-Host 'Press Enter to close'; exit 1 }

$backup = Get-ChildItem -Path $dir -Directory -Filter 'config-backup-*' -ErrorAction SilentlyContinue |
          Sort-Object Name -Descending | Select-Object -First 1
if (-not $backup) {
    Write-Warning "No backup folder (config-backup-*) found in $dir. Nothing to restore."
    Read-Host 'Press Enter to close'; exit 1
}

Write-Host "Restoring from: $($backup.FullName)" -ForegroundColor Cyan
if (Test-Path (Join-Path $backup.FullName 'shell.nss')) {
    Copy-Item (Join-Path $backup.FullName 'shell.nss') (Join-Path $dir 'shell.nss') -Force
}
Copy-Item (Join-Path $backup.FullName 'imports\*.nss') (Join-Path $dir 'imports') -Force -ErrorAction SilentlyContinue

$exe = Join-Path $dir 'shell.exe'
Start-Process -FilePath $exe -ArgumentList '-restart' -Wait -WindowStyle Hidden
Write-Host 'Restored and reloaded.' -ForegroundColor Green
Read-Host 'Press Enter to close'
