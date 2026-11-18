# DoomOS — Balanced Gaming Edition

Independent, user-built Windows 10 22H2 x64 customization project for ASUS X441 series. **Phase 1 scaffold only: no customized ISO has been built or tested.**

Windows 10 standard support ended October 14, 2025. Eligible users should enroll in Extended Security Updates (https://www.microsoft.com/windows/extended-security-updates).

## Phase 1 (Windows PowerShell as Administrator)

1. Obtain an official Windows 10 22H2 x64 ISO: https://www.microsoft.com/software-download/windows10ISO (or Media Creation Tool).
2. Install Windows ADK Deployment Tools and optionally NTLite, and reserve 30–40 GB of free working space.
3. Download scripts in `Scripts/`; run:

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
.\Scripts\Initialize-DoomOS.ps1 -Root C:\DoomOS
.\Scripts\Get-DoomOSHardware.ps1 -Root C:\DoomOS
.\Scripts\Prepare-OfficialISO.ps1 -Root C:\DoomOS -IsoPath 'C:\Path\To\Official-Win10.iso'
```

The scripts create a workspace, collect a read-only hardware audit, verify SHA-256 of local source media, extract it and enumerate installed Windows editions. They do not format disks or modify Windows installations.

The full project and converted wallpaper/icon-sheet reference are available in the companion starter ZIP delivered in chat. To add branding files to this repository, upload only the assets you own and are permitted to distribute.

## Layout

`ISO/` official source/extracted working media; `Mount/` DISM mountpoint; `Drivers/` verified INF packages; `Branding/` theme and icon assets; `Scripts/` build automation; `Registry/` reversible settings; `Unattend/` validated setup answer files; `Logs/` local reports; `Output/` local build; `Backups/` backups; `Docs/` instructions.

## Important

Microsoft ISO/WIM/ESD binaries, proprietary drivers, device-serial reports and license keys must **not** be committed to GitHub. These are ignored by Git. The actual licensed ISO is generated locally, using official Microsoft media, and validated before use. Preserve Defender, Firewall, Windows Update, Microsoft Store, servicing and Windows Recovery Environment.

Hardware model and PnP IDs must be verified before driver integration. Image index must be verified before customization. No hard-drive erasure is automated.
