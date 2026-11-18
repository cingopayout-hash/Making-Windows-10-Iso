#Requires -Version 5.1
<#
.SYNOPSIS
  Prepare a BIOS/UEFI DoomOS ISO from a verified Windows 10 Pro x64 WIM.
.EXAMPLE
  .\Scripts\Build-DoomOSISO.ps1 -Root C:\DoomOS
  .\Scripts\Build-DoomOSISO.ps1 -Root C:\DoomOS -Apply
#>
[CmdletBinding()]
param([string]$Root='C:\DoomOS',[switch]$Apply)
$ErrorActionPreference='Stop'
$stage=Join-Path $Root 'Output\Stage-Pro'
$wim=Join-Path $stage 'sources\install.wim'
$esd=Join-Path $stage 'sources\install.esd'
$iso=Join-Path $Root 'Output\DoomOS-Balanced-Gaming-Edition-x64.iso'
$logDir=Join-Path $Root 'Logs'
New-Item -ItemType Directory -Path $logDir -Force|Out-Null
$log=Join-Path $logDir ('Build-ISO-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
function Log([string]$message){"$(Get-Date -Format o) $message"|Tee-Object -FilePath $log -Append}
function Run([string]$exe,[string[]]$arguments){
 & $exe @arguments 2>&1 | ForEach-Object {"$_"|Tee-Object -FilePath $log -Append}
 if($LASTEXITCODE -ne 0){throw "$exe exit code $LASTEXITCODE"}
}
try {
 $identity=[Security.Principal.WindowsIdentity]::GetCurrent()
 $principal=New-Object Security.Principal.WindowsPrincipal($identity)
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run as Administrator'}
 foreach($file in @($wim,(Join-Path $stage 'setup.exe'),(Join-Path $stage 'boot\etfsboot.com'),(Join-Path $stage 'efi\microsoft\boot\efisys.bin'))){
  if(-not(Test-Path -LiteralPath $file -PathType Leaf)){throw "Missing required file: $file"}
 }
 if(Test-Path -LiteralPath $iso){throw "ISO already exists: $iso"}
 if(Test-Path -LiteralPath $esd){throw "ESD already exists: $esd"}
 $images=@(Get-WindowsImage -ImagePath $wim -ErrorAction Stop)
 if($images.Count -ne 1 -or $images[0].ImageName -ne 'Windows 10 Pro'){throw 'Expected single Windows 10 Pro WIM'}
 $details=Get-WindowsImage -ImagePath $wim -Index 1 -ErrorAction Stop
 if($details.Architecture -notin @('x64','amd64','9')){throw 'Not verified as x64'}
 $mounted=@(Get-WindowsImage -Mounted -ErrorAction Stop)
 if(@($mounted|Where-Object {$_.ImagePath -eq $wim}).Count -gt 0){throw 'WIM still mounted'}
 $adk=Join-Path ([Environment]::GetFolderPath('ProgramFilesX86')) 'Windows Kits\10\Assessment and Deployment Kit\Deployment Tools\amd64\Oscdimg\oscdimg.exe'
 if(-not(Test-Path -LiteralPath $adk)){throw "ADK oscdimg missing: $adk"}
 Log "Verified source WIM SHA256: $((Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash)"
 if(-not $Apply){Log 'PREVIEW ONLY. Re-run with -Apply to create ESD and ISO.';return}
 $backup=Join-Path $Root 'Backups\WIM-Before-ISO.wim'
 New-Item -ItemType Directory -Path (Split-Path $backup -Parent) -Force|Out-Null
 if(Test-Path -LiteralPath $backup){throw "Backup already exists: $backup"}
 Run 'dism.exe' @('/English','/Export-Image',"/SourceImageFile:$wim",'/SourceIndex:1',"/DestinationImageFile:$esd",'/Compress:recovery','/CheckIntegrity')
 $esdImages=@(Get-WindowsImage -ImagePath $esd -ErrorAction Stop)
 if($esdImages.Count -ne 1 -or $esdImages[0].ImageName -ne 'Windows 10 Pro'){throw 'ESD verification failed'}
 $esdDetails=Get-WindowsImage -ImagePath $esd -Index 1
 if($esdDetails.Architecture -notin @('x64','amd64','9')){throw 'ESD architecture verification failed'}
 Log "Exported ESD SHA256: $((Get-FileHash -LiteralPath $esd -Algorithm SHA256).Hash)"
 Move-Item -LiteralPath $wim -Destination $backup -ErrorAction Stop
 try {
  $boot="-bootdata:2#p0,e,b$stage\boot\etfsboot.com#pEF,e,b$stage\efi\microsoft\boot\efisys.bin"
  Run $adk @('-m','-o','-u2','-udfver102','-lDOOMOS_BALANCED',$boot,$stage,$iso)
 } catch {
  if(Test-Path -LiteralPath $backup){Move-Item -LiteralPath $backup -Destination $wim -ErrorAction SilentlyContinue}
  throw
 }
 if(-not(Test-Path -LiteralPath $iso -PathType Leaf)){throw 'oscdimg produced no ISO'}
 Log "ISO SHA256: $((Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash)"
 Log 'ISO produced, but boot, installation and security testing are still required.'
 Write-Host "Created: $iso"
} catch {
 Log "ERROR: $($_.Exception.Message)"
 Write-Error $_
 exit 1
}
# Rollback: delete generated ISO/ESD and manually restore Backups\WIM-Before-ISO.wim
# after checking that Stage-Pro\sources\install.wim is absent and no image is mounted.
