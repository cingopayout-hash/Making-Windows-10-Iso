#Requires -Version 5.1
<#
.SYNOPSIS
  Reversible DoomOS low-end desktop settings for the CURRENT logged-in user.
.DESCRIPTION
  Safe default: preview only. -Apply writes four HKCU values after backing up
  existing values; -Rollback restores exactly the prior state using JSON snapshot.
  Run interactively as the user whose desktop will be optimized, elevated as required.
  No security/service/driver/pagefile/partition modifications.
.EXAMPLE
  .\Scripts\Set-DoomOSBalanced.ps1 -Root C:\DoomOS -Apply
.EXAMPLE
  .\Scripts\Set-DoomOSBalanced.ps1 -Root C:\DoomOS -Rollback -BackupFile C:\DoomOS\Backups\DoomOS-Settings-20261118-120000.json
#>
[CmdletBinding(DefaultParameterSetName='Preview')]
param(
 [string]$Root='C:\DoomOS',
 [Parameter(ParameterSetName='Apply')][switch]$Apply,
 [Parameter(Mandatory,ParameterSetName='Rollback')][switch]$Rollback,
 [Parameter(Mandatory,ParameterSetName='Rollback')][string]$BackupFile
)
$ErrorActionPreference='Stop'
$rootPath=[IO.Path]::GetFullPath($Root)
$logs=Join-Path $rootPath 'Logs';$backups=Join-Path $rootPath 'Backups'
New-Item -ItemType Directory -Path $logs,$backups -Force | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss-fff'
$log=Join-Path $logs "DoomOS-Settings-$stamp.log"
function Log([string]$Message){"$(Get-Date -Format o) $Message" | Tee-Object -FilePath $log -Append}
function AdminCheck {
 $principal=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run PowerShell as administrator while signed in to the target user account.'}
}
$settings=@(
 @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';Name='TaskbarAnimations';Type='DWord';Value=0},
 @{Path='HKCU:\Control Panel\Desktop\WindowMetrics';Name='MinAnimate';Type='String';Value='0'},
 @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';Name='EnableTransparency';Type='DWord';Value=0},
 @{Path='HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications';Name='GlobalUserDisabled';Type='DWord';Value=1}
)
function Capture($Setting){
 $found=$false;$oldValue=$null;$oldKind=$null
 if(Test-Path -LiteralPath $Setting.Path){
  $key=Get-Item -LiteralPath $Setting.Path
  if($key.GetValueNames() -contains $Setting.Name){
   $found=$true
   $oldValue=$key.GetValue($Setting.Name)
   $oldKind=[string]$key.GetValueKind($Setting.Name)
  }
 }
 return [pscustomobject]@{Path=$Setting.Path;Name=$Setting.Name;Existed=$found;Value=$oldValue;Kind=$oldKind}
}
try {
 AdminCheck
 Log "Action: $($PSCmdlet.ParameterSetName); user=$env:USERNAME"
 if($Rollback){
  $file=(Resolve-Path -LiteralPath $BackupFile -ErrorAction Stop).Path
  $state=Get-Content -LiteralPath $file -Raw | ConvertFrom-Json
  if($state.Schema -ne 'DoomOS-HKCU-v1'){throw 'Unsupported backup schema'}
  foreach($entry in $state.Entries){
   # Reject arbitrary registry locations from a modified backup.
   $approved=@($settings | Where-Object { $_.Path -eq $entry.Path -and $_.Name -eq $entry.Name })
   if($approved.Count -ne 1){throw "Unexpected registry setting in backup: $($entry.Path) $($entry.Name)"}
   if($entry.Existed){
    New-Item -Path $entry.Path -Force | Out-Null
    New-ItemProperty -Path $entry.Path -Name $entry.Name -Value $entry.Value -PropertyType $entry.Kind -Force | Out-Null
   } elseif(Test-Path $entry.Path) {
    Remove-ItemProperty -Path $entry.Path -Name $entry.Name -ErrorAction SilentlyContinue
   }
   Log "Restored $($entry.Path) :: $($entry.Name)"
  }
  Log 'Rollback complete. Sign out and sign back in for all visual effects.'
 }elseif($Apply){
  $state=[pscustomobject]@{Schema='DoomOS-HKCU-v1';Created=(Get-Date -Format o);User=$env:USERNAME;Entries=@($settings|ForEach-Object{Capture $_})}
  $snapshot=Join-Path $backups "DoomOS-Settings-$stamp.json"
  $state | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $snapshot -Encoding UTF8
  Log "Backup created: $snapshot"
  foreach($setting in $settings){
   New-Item -Path $setting.Path -Force | Out-Null
   New-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -PropertyType $setting.Type -Force | Out-Null
   $now=(Get-ItemProperty -Path $setting.Path -Name $setting.Name).($setting.Name)
   if("$now" -ne "$($setting.Value)"){throw "Verification failed: $($setting.Name)"}
   Log "Set $($setting.Name) => $($setting.Value)"
  }
  Log 'Applied. Sign out and sign back in. To undo, run -Rollback -BackupFile <backup JSON path>.'
 }else{
  foreach($setting in $settings){
   $prior=Capture $setting
   Log ("PREVIEW {0}\{1}: existing={2}, requested={3}" -f $setting.Path,$setting.Name,($prior.Value),$setting.Value)
  }
  Log 'Preview only; no changes applied.'
 }
 Log 'No pagefile, power plan, Windows Update, Defender, SysMain, Search or service changes made.'
}catch{
 Log "ERROR: $($_.Exception.Message)"
 Write-Error $_
 exit 1
}
