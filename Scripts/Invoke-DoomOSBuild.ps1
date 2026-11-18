#Requires -Version 5.1
<#
.SYNOPSIS
  DoomOS guided local build orchestration. Preview unless -Apply.
.EXAMPLE
  .\Scripts\Invoke-DoomOSBuild.ps1 -Root C:\DoomOS -IsoPath D:\Downloads\Win10_22H2_x64.iso
  .\Scripts\Invoke-DoomOSBuild.ps1 -Root C:\DoomOS -IsoPath D:\Downloads\Win10_22H2_x64.iso -Apply
.DESCRIPTION
  Must be run on Windows, with local official Microsoft ISO, ADK and admin privileges.
  Does not partition, install or erase any drive. Calls existing phase scripts serially.
#>
[CmdletBinding()]
param(
 [string]$Root='C:\DoomOS',
 [Parameter(Mandatory)][string]$IsoPath,
 [switch]$Apply,
 [switch]$Debloat
)
$ErrorActionPreference='Stop'
$project=Split-Path $PSScriptRoot -Parent
$required=@('Initialize-DoomOS.ps1','Prepare-OfficialISO.ps1','Stage-Windows10Pro.ps1','Customize-DoomOSApps.ps1','Build-DoomOSISO.ps1','Test-DoomOSISO.ps1')
foreach($f in $required){if(-not(Test-Path (Join-Path $PSScriptRoot $f))){throw "Missing script: $f"}}
$source=(Resolve-Path -LiteralPath $IsoPath -ErrorAction Stop).Path
$toRun=@(
 "Initialize-DoomOS.ps1 -Root '$Root'",
 "Prepare-OfficialISO.ps1 -Root '$Root' -IsoPath '$source'",
 "Stage-Windows10Pro.ps1 -Root '$Root'"
)
if($Debloat){$toRun+="Customize-DoomOSApps.ps1 -Root '$Root' -Apply"}
$toRun+="Build-DoomOSISO.ps1 -Root '$Root' -Apply"
$toRun+="Test-DoomOSISO.ps1 -Root '$Root' -RequireISO"
if(-not $Apply){
 Write-Host 'PREVIEW ONLY. Steps that would be run:'
 $toRun|ForEach-Object {Write-Host "  $_"}
 Write-Host 'This does not auto-install Windows, wipe disks, enable optional themes, or test in a VM.'
 return
}
$identity=[Security.Principal.WindowsIdentity]::GetCurrent()
$p=New-Object Security.Principal.WindowsPrincipal($identity)
if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run as administrator'}
$init=& (Join-Path $PSScriptRoot 'Initialize-DoomOS.ps1') -Root $Root
if($LASTEXITCODE -and $LASTEXITCODE -ne 0){throw 'Initialize failed'}
& (Join-Path $PSScriptRoot 'Prepare-OfficialISO.ps1') -Root $Root -IsoPath $source
if($LASTEXITCODE -ne 0){throw 'Official ISO preparation failed'}
& (Join-Path $PSScriptRoot 'Stage-Windows10Pro.ps1') -Root $Root
if($LASTEXITCODE -ne 0){throw 'Pro image staging failed'}
if($Debloat){
 & (Join-Path $PSScriptRoot 'Customize-DoomOSApps.ps1') -Root $Root -Apply
 if($LASTEXITCODE -ne 0){throw 'Debloat failed'}
}
& (Join-Path $PSScriptRoot 'Build-DoomOSISO.ps1') -Root $Root -Apply
if($LASTEXITCODE -ne 0){throw 'ISO generation failed'}
& (Join-Path $PSScriptRoot 'Test-DoomOSISO.ps1') -Root $Root -RequireISO
if($LASTEXITCODE -ne 0){throw 'ISO static validation failed'}
Write-Host 'Static build checks finished. VM boot/install validation and real-hardware tests still REQUIRED.'
# Rollback steps in individual phase scripts. This orchestrator does not delete anything.
