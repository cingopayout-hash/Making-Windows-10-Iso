# DoomOS — Balanced Gaming Edition

Windows 10 Pro 22H2 x64 customization source project for low-end PCs with ~4 GB RAM and HDD/SSD. **Current status: build scripts committed; no installable ISO has been built, boot-tested or benchmarked.**

This project is hardware-neutral: driver packages must match each device's actual PnP IDs. The goal is balanced responsiveness, not an arbitrarily stripped Windows image. Defender, Firewall, Windows Update, Microsoft Store, WinRE, servicing, DirectX and the system-managed page file are retained.

## Quick-start on a Windows build machine

**Prerequisites:** official Microsoft Windows 10 22H2 x64 ISO containing the Pro edition, administrator PowerShell 5.1, Windows ADK Deployment Tools (oscdimg), DISM PowerShell module, and ~30–40 GB or more of free working space.

Download source media from [Microsoft](https://www.microsoft.com/software-download/windows10ISO), install [Windows ADK Deployment Tools](https://learn.microsoft.com/windows-hardware/get-started/adk-install), and clone/download this GitHub repository. Do not upload Microsoft's installation ISO to public GitHub.

Run from the repository folder in **PowerShell as administrator** (edit the ISO path):

```powershell
Set-ExecutionPolicy -Scope Process RemoteSigned
.\Scripts\Invoke-DoomOSBuild.ps1 -Root C:\DoomOS -IsoPath 'D:\Downloads\Win10_22H2_x64.iso'
```

The command above is preview only. To explicitly run the local build after reviewing the steps:

```powershell
.\Scripts\Invoke-DoomOSBuild.ps1 -Root C:\DoomOS -IsoPath 'D:\Downloads\Win10_22H2_x64.iso' -Apply -Debloat
```

The workflow initializes C:\DoomOS, extracts the ISO, selects only the **verified Windows 10 Pro x64** edition, optionally removes seven unneeded provisioned apps, exports a compressed ESD and creates a BIOS/UEFI ISO with ADK oscdimg. It **never partitions, formats or installs Windows**. The default is preview, and the steps refuse to overwrite existing project stages/output.

After a successful build, check its static contents and hash with:

```powershell
.\Scripts\Test-DoomOSISO.ps1 -Root C:\DoomOS -RequireISO
```

**Expected output only after actual execution:** C:\DoomOS\Output\DoomOS-Balanced-Gaming-Edition-x64.iso. Static checks are not proof of successful installation. Test boot and installation in a disposable VM before creating USB installation media. See [Phase 6–7 automation](Docs/PHASE-6-7-AUTOMATION.md) and [Phase 8](Docs/PHASE-8.md).

## Build status and scope

| Area | Status |
| --- | --- |
| Hardware-neutral Windows 10 Pro + 4 GB settings | Config source committed |
| Offline app removal | Optional script committed, not executed |
| User-level animation/transparent-background preference | Optional reversible script committed, not applied |
| Wallpaper file staging | Script committed, not executed |
| Theme-only unattended answer-file template | Written, **not** validated by Windows SIM, **not** embedded into ISO |
| ESD export and dual BIOS/UEFI ISO assembly | Script committed, not executed |
| ISO static inspection | Script committed, not executed |
| Virtual machine installation and boot testing | Not done |
| Real-hardware benchmark | Not done |

Windows 10 standard support ended October 14, 2025. Eligible users should check [Windows Extended Security Updates](https://www.microsoft.com/windows/extended-security-updates). Do not disable security services or bypass activation.

## Working layout

- `ISO/`: official source and extracted media (local only)
- `Mount/`: temporary offline DISM mount
- `Drivers/`: verified driver packages (local only)
- `Branding/`: user's artwork and theme assets
- `Scripts/`: PowerShell preparation, offline servicing, build and audits
- `Registry/`: future reversible registry data
- `Unattend/`: minimal optional theme template
- `Logs/`: build hashes and private device reports (local only)
- `Output/`: staged WIM/ESD and locally generated ISO
- `Backups/`: local WIM backups
- `Docs/`: per-phase workflow and rollback instructions

Keep Microsoft installation media, private serials/keys and proprietary drivers out of public GitHub. Never select or erase the original laptop's HDD without a separate explicit user decision.
