#Requires -Version 5.1
[CmdletBinding()]
param([Parameter(Mandatory)][string]$IsoPath,[string]$Root='C:\DoomOS')
$ErrorActionPreference='Stop'
$mounted=$false;$log=$null
try {
 $id=[Security.Principal.WindowsIdentity]::GetCurrent()
 if(-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run as administrator'}
 $source=(Resolve-Path -LiteralPath $IsoPath -ErrorAction Stop).Path
 if(-not (Test-Path -LiteralPath $source -PathType Leaf)){throw 'ISO not found'}
 foreach($d in @('ISO','Logs')){New-Item -ItemType Directory -Force -Path (Join-Path $Root $d)|Out-Null}
 $log=Join-Path $Root 'Logs\ISO-Preparation.log'
 $hash=Get-FileHash -LiteralPath $source -Algorithm SHA256
 "Source $source SHA256 $($hash.Hash)"|Out-File $log -Append -Encoding UTF8
 $dest=Join-Path $Root 'ISO\Working'
 if(Test-Path $dest){throw "Destination already exists: $dest (will not overwrite)"}
 $disk=Mount-DiskImage -ImagePath $source -PassThru; $mounted=$true
 $volume=$disk|Get-Volume
 if(-not $volume.DriveLetter){throw 'Mounted ISO has no drive letter'}
 $drive="$($volume.DriveLetter):\"
 New-Item -ItemType Directory -Path $dest|Out-Null
 & robocopy.exe $drive $dest /E /R:2 /W:2 /NFL /NDL /NP | Out-Null
 if($LASTEXITCODE -ge 8){throw "robocopy error $LASTEXITCODE"}
 $wim=Join-Path $dest 'sources\install.wim';$esd=Join-Path $dest 'sources\install.esd'
 if(Test-Path $wim){$image=$wim}elseif(Test-Path $esd){$image=$esd}else{throw 'No install.wim or install.esd'}
 & dism.exe /English /Get-WimInfo "/WimFile:$image" | Tee-Object -FilePath $log -Append
 if($LASTEXITCODE -ne 0){throw 'DISM enumeration failed'}
 Write-Host "Original untouched. Review edition indexes in $log."
} catch {if($log){"ERROR: $($_.Exception.Message)"|Out-File $log -Append};Write-Error $_;exit 1}
finally {if($mounted){Dismount-DiskImage -ImagePath $source -ErrorAction SilentlyContinue}}
# Rollback: remove ISO\Working after checking for edits. The original ISO stays unchanged.
