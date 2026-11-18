# DoomOS compression and responsiveness plan (4 GB RAM)

## Distinguish two goals

1. **Smaller distribution ISO**: export an already-serviced, validated Pro image to `install.esd` with DISM `/Compress:recovery`. This reduces download/USB footprint, **not** installed RAM use; compression/decompression can increase ISO build/install time.
2. **Faster runtime**: safely remove unneeded provisioned consumer apps, control startup software, reduce optional background work, and measure hard-drive activity. Avoid stripping servicing, drivers, Microsoft Store, security, networking, and recovery.

## Safe staged build commands (on Windows build host, elevated)

Inspect exact Pro image index first:

```powershell
dism /English /Get-WimInfo /WimFile:C:\DoomOS\ISO\Working\sources\install.wim
```

Some ISOs use `install.esd`; if so inspect that file instead. After selecting the verified Pro index, export it to an editable WIM, mount and service **only that copy**, then commit/unmount. Do not remove Windows components indiscriminately.

For a **validated committed WIM** with Pro selected as image index 1 in the prepared output:

```powershell
dism /Export-Image /SourceImageFile:C:\DoomOS\Output\DoomOS-Pro-Serviced.wim /SourceIndex:1 /DestinationImageFile:C:\DoomOS\Output\install.esd /Compress:recovery /CheckIntegrity
dism /Get-WimInfo /WimFile:C:\DoomOS\Output\install.esd
```

The above presumes the selected source index has been verified as Pro and the output target file does not already exist. Repack a **separate copy** of the Windows setup folder with this `install.esd` replacing `install.wim`, without keeping both. Windows ADK `oscdimg` can generate BIOS/UEFI bootable ISO after validating the boot sector files and input paths. The replacement file may exceed FAT32's 4 GiB limit; use a suitable USB writing method or split WIM as appropriate.

## CompactOS

Do **not** enable `compact.exe /CompactOS:always` by default on an HDD or low-power Celeron; the compressed filesystem trades CPU decompression for storage savings, and it may be slower. Benchmark before adopting, and roll back using `compact.exe /CompactOS:never` from elevated PowerShell.

## Performance verification

Repeat cold boot-to-idle (3 runs), RAM available/committed, CPU idle %, hard-disk active time, Defender/Windows Update functionality, and game 1% lows with same hardware, drivers and games. Compare to stock Windows 10 Pro under identical conditions. Record failures and restore baseline before production.
