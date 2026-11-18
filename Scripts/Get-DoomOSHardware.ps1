#Requires -Version 5.1
[CmdletBinding()]
param([string]$Root='C:\DoomOS')
$ErrorActionPreference='Stop'
$log=$null
try {
 $id=[Security.Principal.WindowsIdentity]::GetCurrent()
 if(-not ([Security.Principal.WindowsPrincipal]$id).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){throw 'Run as administrator'}
 $folder=Join-Path $Root 'Logs';New-Item -ItemType Directory -Force -Path $folder|Out-Null
 $stamp=Get-Date -Format 'yyyyMMdd-HHmmss'; $log=Join-Path $folder "Hardware-$stamp.log"
 $data=[ordered]@{}
 $data.System=Get-CimInstance Win32_ComputerSystem|Select-Object Manufacturer,Model,TotalPhysicalMemory
 $data.Product=Get-CimInstance Win32_ComputerSystemProduct|Select-Object Vendor,Name,Version,IdentifyingNumber
 $data.BIOS=Get-CimInstance Win32_BIOS|Select-Object SMBIOSBIOSVersion,ReleaseDate
 $data.CPU=Get-CimInstance Win32_Processor|Select-Object Name,NumberOfCores
 $data.GPU=Get-CimInstance Win32_VideoController|Select-Object Name,DriverVersion,PNPDeviceID
 $data.Disk=Get-CimInstance Win32_DiskDrive|Select-Object Model,Size,InterfaceType,MediaType
 $data.Network=Get-CimInstance Win32_NetworkAdapter|Where-Object PhysicalAdapter|Select-Object Name,PNPDeviceID
 $data.Audio=Get-CimInstance Win32_SoundDevice|Select-Object Name,PNPDeviceID
 $data.Pointing=Get-CimInstance Win32_PointingDevice|Select-Object Name,PNPDeviceID
 $data.OS=Get-CimInstance Win32_OperatingSystem|Select-Object Caption,Version,OSArchitecture
 $data|ConvertTo-Json -Depth 6|Out-File (Join-Path $folder "Hardware-$stamp.json") -Encoding UTF8
 Get-PnpDevice -PresentOnly|Select-Object Class,FriendlyName,InstanceId,Status|Export-Csv (Join-Path $folder "Devices-$stamp.csv") -NoTypeInformation
 "Hardware audit completed $(Get-Date -Format o)"|Out-File $log -Encoding UTF8
 Write-Host "Saved reports in $folder. Redact serials before sharing."
} catch { if($log){"ERROR: $($_.Exception.Message)"|Out-File $log -Append}; Write-Error $_;exit 1 }
# Read-only; rollback is removing only exported reports.
