#Requires -Version 5.1
<#
.SYNOPSIS
  Stage an official Windows 10 Pro x64 image for subsequent offline customization.
.DESCRIPTION
  Requires Phase 1 Prepare-OfficialISO.ps1 to have extracted official media to ISO\Working.
  Safely copies installer media, exports only the explicitly identified Pro edition as
  one-image WIM and records hashes. Does not mount, debloat, install, partition or modify host OS.
.EXAMPLE
  .\Scripts\Stage-Windows10Pro.ps1 -Root C:\DoomOS
#>
[CmdletBinding()]
param([string]$Root = 'C:\DoomOS')
$ErrorActionPreference = 'Stop'
$stage = Join-Path $Root 'Output\Stage-Pro'
$logDir = Join-Path $Root 'Logs'
$log = Join-Path $logDir 'Stage-Windows10Pro.log'
function Assert-Admin {
 $p = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
 if (-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { throw 'Run PowerShell as Administrator.' }
}
function Run-External([string]$Executable,[string[]]$Arguments) {
 & $Executable @Arguments 2>&1 | ForEach-Object { "$_" | Tee-Object -FilePath $log -Append }
 $code = $LASTEXITCODE
 if ($code -ne 0) { throw "$Executable exited $code" }
}
try {
 Assert-Admin
 New-Item -ItemType Directory -Force -Path $logDir | Out-Null
 "Started $(Get-Date -Format o)" | Out-File $log -Encoding UTF8
 $source = Join-Path $Root 'ISO\Working'
 if (-not (Test-Path (Join-Path $source 'setup.exe'))) { throw 'Official extracted setup files missing. Run Prepare-OfficialISO.ps1 first.' }
 if (Test-Path $stage) { throw "Refusing to overwrite existing stage: $stage. Inspect/rename it manually." }
 $wim = Join-Path $source 'sources\install.wim'
 $esd = Join-Path $source 'sources\install.esd'
 if (Test-Path $wim) { $imageFile = $wim }
 elseif (Test-Path $esd) { $imageFile = $esd }
 else { throw 'Missing install.wim/install.esd in official media.' }
 if (-not (Get-Command Get-WindowsImage -ErrorAction SilentlyContinue)) { throw 'Windows DISM PowerShell module missing. Use Windows host with deployment tools.' }
 $images = @(Get-WindowsImage -ImagePath $imageFile)
 $matches = @($images | Where-Object {
    $_.ImageName -eq 'Windows 10 Pro' -or $_.ImageName -eq 'Windows 10 Pro N'
 })
 # Never silently use an N edition or select a possibly wrong index.
 $pro = @($matches | Where-Object { $_.ImageName -eq 'Windows 10 Pro' })
 if ($pro.Count -ne 1) {
   ($images | Select-Object ImageIndex,ImageName | Format-Table | Out-String) | Add-Content $log
   throw "Expected exactly one non-N Windows 10 Pro edition. Found $($pro.Count). Check ISO source."
 }
 $detail = Get-WindowsImage -ImagePath $imageFile -Index $pro[0].ImageIndex
 if ($detail.Architecture -notin @('x64','amd64','9')) {
   throw "Pro edition architecture not verified as x64: $($detail.Architecture)"
 }
 $srcHash = Get-FileHash -LiteralPath $imageFile -Algorithm SHA256
 $srcHash | Format-List | Out-String | Add-Content $log
 New-Item -ItemType Directory -Path $stage | Out-Null
 & robocopy.exe $source $stage /E /R:2 /W:2 /NFL /NDL /NP 2>&1 |
   ForEach-Object { "$_" | Tee-Object -FilePath $log -Append }
 $rc = $LASTEXITCODE
 if ($rc -ge 8) { throw "Failed to copy installer media, robocopy exit $rc" }
 Remove-Item -LiteralPath (Join-Path $stage 'sources\install.wim') -ErrorAction SilentlyContinue
 Remove-Item -LiteralPath (Join-Path $stage 'sources\install.esd') -ErrorAction SilentlyContinue
 $outputWim = Join-Path $stage 'sources\install.wim'
 Run-External 'dism.exe' @('/English','/Export-Image',"/SourceImageFile:$imageFile","/SourceIndex:$($pro[0].ImageIndex)","/DestinationImageFile:$outputWim",'/Compress:max','/CheckIntegrity')
 $outImages = @(Get-WindowsImage -ImagePath $outputWim)
 if ($outImages.Count -ne 1 -or $outImages[0].ImageName -ne 'Windows 10 Pro') { throw 'Output single-edition Pro verification FAILED.' }
 $outDetail = Get-WindowsImage -ImagePath $outputWim -Index 1
 if ($outDetail.Architecture -notin @('x64','amd64','9')) { throw 'Output x64 architecture verification FAILED.' }
 Get-FileHash -LiteralPath $outputWim -Algorithm SHA256 | Format-List | Out-String | Add-Content $log
 "SUCCESS: verified Pro x64 stage at $stage" | Tee-Object -FilePath $log -Append
 Write-Host "Next: offline customize Stage-Pro\sources\install.wim. Do NOT compress it until servicing is complete."
}
catch {
 "ERROR: $($_.Exception.Message)" | Out-File $log -Append -Encoding UTF8
 Write-Error $_
 exit 1
}
# Rollback: remove ONLY Output\Stage-Pro once it is verified not needed; official ISO and ISO\Working are left intact.
