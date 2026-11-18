#Requires -Version 5.1
[CmdletBinding()]
param([string]$Root='C:\DoomOS')
$ErrorActionPreference='Stop'
try {
 $id=[Security.Principal.WindowsIdentity]::GetCurrent()
 if(-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run as administrator'}
 foreach($folder in @('ISO','Mount','Drivers','Branding','Scripts','Registry','Unattend','Logs','Output','Backups','Docs')){
  New-Item -ItemType Directory -Force -Path (Join-Path $Root $folder) | Out-Null
 }
 "$(Get-Date -Format o) Workspace ready: $Root" | Out-File (Join-Path $Root 'Logs\Initialize.log') -Append -Encoding UTF8
 Write-Host "Created $Root"
} catch {Write-Error $_;exit 1}
# Rollback: delete only a newly-created EMPTY workspace after inspecting its contents.
