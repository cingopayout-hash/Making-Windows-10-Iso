# Phase 2 — official media to Windows 10 Pro image

**Status:** Automation source delivered; NOT executed on Windows; ISO NOT built.

## Requirements
- Windows build machine with administrator privileges, 30–40 GB or more free disk space, Windows 10/11 x64 and DISM PowerShell module.
- Official Microsoft Windows 10 22H2 x64 ISO: https://www.microsoft.com/software-download/windows10ISO
- Windows ADK Deployment Tools for the later `oscdimg` compilation stage: https://learn.microsoft.com/windows-hardware/get-started/adk-install
- ISO preparation completed with `Scripts/Prepare-OfficialISO.ps1` (records source SHA256 and extracts ISO\Working).
- Use a matching legitimate Windows 10 Pro license to activate Windows later.

## Exact commands (PowerShell as administrator, from project root)
```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy RemoteSigned
.\Scripts\Initialize-DoomOS.ps1 -Root 'C:\DoomOS'
.\Scripts\Prepare-OfficialISO.ps1 -Root 'C:\DoomOS' -IsoPath 'D:\Downloads\Win10_22H2_x64.iso'
.\Scripts\Stage-Windows10Pro.ps1 -Root 'C:\DoomOS'
```
Change the ISO path to the actual downloaded official image. Scripts do not download Windows, overwrite existing stages or format any drive.

## Expected outputs
- `C:\DoomOS\ISO\Working\` — copy of original Windows setup files.
- `C:\DoomOS\Output\Stage-Pro\sources\install.wim` — a **single Windows 10 Pro x64 image** exported from the actual source image (after edition and architecture checks).
- `C:\DoomOS\Logs\ISO-Preparation.log` — original ISO source image details.
- `C:\DoomOS\Logs\Stage-Windows10Pro.log` — source image hash and exported image hash.

## What comes next
Phase 3 offline customization must mount and service this staged WIM (not the original copy), then commit and run `dism /Get-WimInfo` again. After validation, later stages can export the customized WIM to `install.esd` with `/Compress:recovery` and create a bootable BIOS/UEFI ISO using ADK `oscdimg`.

## Failure and rollback
- **Edition missing:** stop; verify ISO is a multi-edition retail image and that Pro non-N is present; never guess a WIM index.
- **Not x64:** stop and obtain proper x64 media.
- **Insufficient disk space:** free space on *the build disk*, not the target HDD.
- **Stage exists:** intentionally refuses to overwrite; preserve it or move it aside.
- **DISM error:** inspect `Stage-Windows10Pro.log`; don't proceed to ISO compilation.
- **Rollback:** delete only `Output\Stage-Pro` after inspecting it; the source ISO is unchanged.

Windows 10 standard support ended October 14, 2025; evaluate Microsoft ESU eligibility and maintain security protections.
