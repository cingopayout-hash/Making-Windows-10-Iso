#Requires -Version 5.1
<#
.SYNOPSIS
  Validate DoomOS ISO artifacts; read-only, no disk changes.
.EXAMPLE
  .\Scripts\Test-DoomOSISO.ps1 -Root C:\DoomOS
#>
[CmdletBinding()]
param([string]$Root='C:\DoomOS',[switch]$RequireISO)
$ErrorActionPreference='Stop'
$iso=Join-Path $Root 'Output\DoomOS-Balanced-Gaming-Edition-x64.iso'
$stage=Join-Path $Root 'Output\Stage-Pro'
$esd=Join-Path $stage 'sources\install.esd'
$logs=Join-Path $Root 'Logs'
New-Item -ItemType Directory -Path $logs -Force | Out-Null
$path=Join-Path $logs ('ISO-Validation-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.json')
$checks=New-Object System.Collections.Generic.List[object]
function Check([string]$Name,[bool]$Passed,[string]$Detail){
 $checks.Add([pscustomobject]@{Name=$Name;Passed=$Passed;Detail=$Detail})
}
try {
 Check 'ISO exists' (Test-Path -LiteralPath $iso -PathType Leaf) $iso
 if(-not(Test-Path -LiteralPath $iso -PathType Leaf)){
   if($RequireISO){throw 'No ISO found: build phase was not run'}
   $report=[pscustomobject]@{Status='NOT_BUILT';Timestamp=(Get-Date -Format o);Checks=@($checks)}
   $report|ConvertTo-Json -Depth 5|Set-Content -LiteralPath $path -Encoding UTF8
   Write-Host 'ISO is not built yet. See report:' $path
   return
 }
 $size=(Get-Item -LiteralPath $iso).Length
 Check 'ISO nonempty' ($size -gt 100MB) "$size bytes"
 $hash=(Get-FileHash -LiteralPath $iso -Algorithm SHA256).Hash
 Check 'ISO SHA256 calculated' ($hash.Length -eq 64) $hash
 # Optional mounted-image inspection, supported on the Windows build host.
 $mountSuccess=$false;$mountedISO=$false
 try {
   $disk=Mount-DiskImage -ImagePath $iso -PassThru -ErrorAction Stop
   $mountedISO=$true
   $vol=$disk|Get-Volume
   if(-not $vol.DriveLetter){throw 'ISO mount has no drive letter'}
   $letter=('{0}:\' -f $vol.DriveLetter)
   foreach($rel in @('setup.exe','boot\etfsboot.com','efi\microsoft\boot\efisys.bin','sources\boot.wim','sources\install.esd')){
     Check "ISO member $rel" (Test-Path -LiteralPath (Join-Path $letter $rel) -PathType Leaf) $rel
   }
   $info=@(Get-WindowsImage -ImagePath (Join-Path $letter 'sources\install.esd') -ErrorAction Stop)
   Check 'One Windows 10 Pro image' ($info.Count -eq 1 -and $info[0].ImageName -eq 'Windows 10 Pro') ($info|Out-String)
   $mountSuccess=$true
 } catch {
   Check 'ISO mounting and contents' $false $_.Exception.Message
 } finally {
   if($mountedISO){Dismount-DiskImage -ImagePath $iso -ErrorAction SilentlyContinue|Out-Null}
 }
 $failures=@($checks|Where-Object {-not $_.Passed}).Count
 $report=[pscustomobject]@{
   Timestamp=Get-Date -Format o;IsoPath=$iso;SizeBytes=$size;SHA256=$hash
   Status=$(if($failures -eq 0 -and $mountSuccess){'STATIC_CHECKS_PASSED_VM_REQUIRED'}else{'FAILED'})
   Checks=@($checks)
   Caveat='ISO bootability and Windows installation are NOT established by these checks. Test in a VM before USB use.'
 }
 $report|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $path -Encoding UTF8
 Write-Host "Validation report: $path | status $($report.Status)"
 if($failures -gt 0){exit 1}
} catch {
 $errorReport=[pscustomobject]@{Timestamp=Get-Date -Format o;Status='FAILED';Error=$_.Exception.Message;Checks=@($checks)}
 $errorReport|ConvertTo-Json -Depth 7|Set-Content -LiteralPath $path -Encoding UTF8
 Write-Error $_
 exit 1
}
# Read-only; no rollback required other than deleting the report.
