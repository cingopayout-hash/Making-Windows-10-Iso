#Requires -Version 5.1
<#
.SYNOPSIS
 Inspect or selectively remove optional provisioned consumer apps from an OFFLINE Windows 10 Pro WIM.
.EXAMPLE
 .\Scripts\Customize-DoomOSApps.ps1 -Root C:\DoomOS
 .\Scripts\Customize-DoomOSApps.ps1 -Root C:\DoomOS -Apply
.NOTES
 Preview is the default. -Apply makes a WIM backup before modifying the stage.
 Rollback: restore the original WIM from Backups\PreDebloat-<timestamp>.wim.
#>
[CmdletBinding()]
param(
 [string]$Root = 'C:\DoomOS',
 [switch]$Apply
)
$ErrorActionPreference = 'Stop'
$wim = Join-Path $Root 'Output\Stage-Pro\sources\install.wim'
$mount = Join-Path $Root 'Mount\Phase3'
$logDir = Join-Path $Root 'Logs'
$log = Join-Path $logDir ('Phase3-Apps-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.log')
$backupDir = Join-Path $Root 'Backups'
$mounted = $false
$save = $false
# Conservative allowlist, deliberately excludes Store, frameworks, Photos, Xbox, DesktopAppInstaller.
$optionalApps = @(
 'Microsoft.BingNews',
 'Microsoft.BingWeather',
 'Microsoft.GetHelp',
 'Microsoft.Getstarted',
 'Microsoft.MicrosoftSolitaireCollection',
 'Microsoft.WindowsFeedbackHub',
 'Microsoft.WindowsMaps'
)
function Write-Log([string]$Message) {
 $line = ('{0} {1}' -f (Get-Date -Format o),$Message)
 $line | Tee-Object -FilePath $log -Append
}
function Assert-Admin {
 $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
 $principal = New-Object Security.Principal.WindowsPrincipal($identity)
 if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
   throw 'Run Windows PowerShell as Administrator'
 }
}
try {
 Assert-Admin
 foreach($dir in @($logDir,$backupDir)){ New-Item -ItemType Directory -Path $dir -Force | Out-Null }
 if (-not (Test-Path -LiteralPath $wim -PathType Leaf)) { throw "Staged WIM absent: $wim. Complete Phase 2." }
 if (-not (Get-Command Mount-WindowsImage -ErrorAction SilentlyContinue)) { throw 'DISM PowerShell module unavailable' }
 $images = @(Get-WindowsImage -ImagePath $wim)
 if ($images.Count -ne 1 -or $images[0].ImageName -ne 'Windows 10 Pro') { throw 'Expected one staged Windows 10 Pro image; aborting' }
 $details = Get-WindowsImage -ImagePath $wim -Index 1
 if ($details.Architecture -notin @('x64','amd64','9')) { throw 'Architecture check failed; expected x64' }
 if (Test-Path -LiteralPath $mount) {
   if (@(Get-ChildItem -LiteralPath $mount -Force).Count -ne 0) { throw "Mount directory not empty: $mount. Inspect existing mounts manually." }
 } else { New-Item -ItemType Directory -Path $mount | Out-Null }
 $existingMounts = @(Get-WindowsImage -Mounted -ErrorAction Stop | Where-Object { $_.Path -eq $mount })
 if ($existingMounts.Count -gt 0) { throw "Already mounted: $mount" }
 Write-Log ('Mode: ' + $(if ($Apply) { 'APPLY' } else { 'PREVIEW ONLY' }))
 Write-Log ('Image: ' + $wim)
 if ($Apply) {
   $backup = Join-Path $backupDir ('PreDebloat-' + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.wim')
   Copy-Item -LiteralPath $wim -Destination $backup -ErrorAction Stop
   $originalHash = (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash
   $backupHash = (Get-FileHash -LiteralPath $backup -Algorithm SHA256).Hash
   if ($originalHash -ne $backupHash) { throw 'Backup SHA-256 mismatch; no changes applied' }
   Write-Log "Backup: $backup SHA256=$backupHash"
 }
 Mount-WindowsImage -ImagePath $wim -Index 1 -Path $mount -ReadOnly:(-not $Apply) -ErrorAction Stop | Out-Null
 $mounted = $true
 $all = @(Get-AppxProvisionedPackage -Path $mount -ErrorAction Stop)
 $targets = @($all | Where-Object { $optionalApps -contains $_.DisplayName })
 foreach ($entry in $targets) {
   Write-Log ("Candidate: " + $entry.DisplayName + " :: " + $entry.PackageName)
 }
 Write-Log ("Optional matches: " + $targets.Count)
 if ($Apply) {
   foreach ($entry in $targets) {
     Write-Log ("Removing: " + $entry.PackageName)
     Remove-AppxProvisionedPackage -Path $mount -PackageName $entry.PackageName -ErrorAction Stop | Out-Null
   }
   $remaining = @(Get-AppxProvisionedPackage -Path $mount | Where-Object { $optionalApps -contains $_.DisplayName })
   if ($remaining.Count -ne 0) { throw ('Verification failed, remaining matches: ' + $remaining.Count) }
   Write-Log 'Verified provisioned optional app removal'
   $save = $true
 }
} catch {
 if (Test-Path -LiteralPath $logDir) { Write-Log ('ERROR: ' + $_.Exception.Message) }
 Write-Error $_
 exit 1
} finally {
 if ($mounted) {
   try {
     if ($save) {
       Dismount-WindowsImage -Path $mount -Save -ErrorAction Stop | Out-Null
       Write-Log ('Saved updated WIM SHA256=' + (Get-FileHash -LiteralPath $wim -Algorithm SHA256).Hash)
     } else {
       Dismount-WindowsImage -Path $mount -Discard -ErrorAction Stop | Out-Null
       Write-Log 'Unmounted without saving modifications'
     }
   } catch { Write-Warning "Unmount failed. Inspect DISM mounts before retrying: $($_.Exception.Message)" }
 }
}
