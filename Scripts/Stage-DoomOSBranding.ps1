#Requires -Version 5.1
<#
.SYNOPSIS
 Stage the user's owned DoomOS wallpaper into Windows Setup's $OEM$ file-copy structure.
.EXAMPLE
 .\Scripts\Stage-DoomOSBranding.ps1 -Root C:\DoomOS -WallpaperPath 'C:\MyAssets\DoomOS-Wallpaper.jpg'
#>
[CmdletBinding()]
param(
 [string]$Root='C:\DoomOS',
 [Parameter(Mandatory)][string]$WallpaperPath
)
$ErrorActionPreference='Stop'
$logDir=Join-Path $Root 'Logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$log=Join-Path $logDir ('Branding-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.log')
try {
 $p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run as administrator'}
 $imageSource=(Resolve-Path -LiteralPath $WallpaperPath -ErrorAction Stop).Path
 $ext=[IO.Path]::GetExtension($imageSource).ToLowerInvariant()
 if($ext -notin @('.jpg','.jpeg','.png')){throw 'Wallpaper must be JPEG or PNG'}
 $stage=Join-Path $Root 'Output\Stage-Pro'
 if(-not (Test-Path (Join-Path $stage 'sources\install.wim'))){throw 'Phase 2 stage missing'}
 $oem=Join-Path $stage 'sources\$OEM$\$$\Web\Wallpaper\DoomOS'
 New-Item -ItemType Directory -Path $oem -Force|Out-Null
 $dest=Join-Path $oem ('DoomOS-Wallpaper'+$ext)
 if(Test-Path $dest){throw "Refusing to overwrite existing branding file: $dest"}
 Copy-Item -LiteralPath $imageSource -Destination $dest
 if((Get-FileHash -LiteralPath $imageSource -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash){throw 'Branding hash mismatch'}
 "Branding asset staged to $dest $(Get-Date -Format o)"|Out-File -FilePath $log -Encoding UTF8
 Write-Host "Wallpaper staged; on a standard Windows Setup, this will be copied to %WINDIR%\Web\Wallpaper\DoomOS."
 Write-Host "It does NOT select the image as default wallpaper. Theme configuration is a separate validated step."
} catch {
 "ERROR: $($_.Exception.Message)"|Out-File $log -Append
 Write-Error $_
 exit 1
}
# Rollback: remove only the specifically staged asset, not the user's original.
