#Requires -Version 5.1
<#
.SYNOPSIS
  Read-only DoomOS post-install audit of security, RAM, disk and image health.
.EXAMPLE
  .\Scripts\Test-DoomOSInstallation.ps1 -Root C:\DoomOS
#>
[CmdletBinding()]
param([string]$Root='C:\DoomOS')
$ErrorActionPreference='Stop'
$logDir=Join-Path $Root 'Logs'
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
$stamp=Get-Date -Format 'yyyyMMdd-HHmmss'
$file=Join-Path $logDir "Validation-$stamp.json"
function Safe([scriptblock]$code) {
 try { & $code } catch { "Unavailable: $($_.Exception.Message)" }
}
try {
 $p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
 if(-not $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run PowerShell as administrator'}
 $os=Get-CimInstance Win32_OperatingSystem
 $memory=Get-CimInstance Win32_OperatingSystem
 $report=[ordered]@{
  Timestamp=Get-Date -Format o
  OsCaption=$os.Caption
  OsVersion=$os.Version
  Architecture=$os.OSArchitecture
  TotalRamGB=[Math]::Round($os.TotalVisibleMemorySize/1MB,2)
  FreeRamGB=[Math]::Round($memory.FreePhysicalMemory/1MB,2)
  Defender=(Safe { Get-MpComputerStatus | Select-Object AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated })
  Firewall=(Safe { Get-NetFirewallProfile | Select-Object Name,Enabled })
  WindowsUpdateService=(Safe { Get-Service wuauserv | Select-Object Name,Status,StartType })
  SysMain=(Safe { Get-Service SysMain | Select-Object Name,Status,StartType })
  Search=(Safe { Get-Service WSearch | Select-Object Name,Status,StartType })
  SystemManagedPagefile=(Safe { Get-CimInstance Win32_ComputerSystem | Select-Object AutomaticManagedPagefile })
  Disk=(Safe { Get-CimInstance Win32_DiskDrive | Select-Object Model,MediaType,Size })
  WinRE=(Safe { (& reagentc.exe /info 2>&1 | Out-String) })
  SFCNote='Run sfc /scannow separately; this script does not change system state.'
  DISMNote='Run DISM /Online /Cleanup-Image /ScanHealth separately; verify updates and Store manually.'
 }
 $report | ConvertTo-Json -Depth 7 | Out-File -LiteralPath $file -Encoding UTF8
 Write-Host "Wrote read-only validation report: $file"
 Write-Host 'Review private hardware identifiers before sharing results.'
} catch {
 Write-Error $_
 exit 1
}
# Rollback: delete only the generated validation JSON. This script does not alter Windows settings.
