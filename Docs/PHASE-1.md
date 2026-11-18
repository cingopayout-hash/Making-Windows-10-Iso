# Phase 1 checks

Run on elevated Windows PowerShell with AC power and 30–40 GB working disk space.

1. Obtain official Windows 10 22H2 x64 ISO from Microsoft, using the edition corresponding to an existing legal license.
2. Install Windows ADK Deployment Tools (DISM / oscdimg), NTLite, and a VM tool.
3. Run the three scripts documented in README.
4. Inspect model, BIOS, GPU, Wi-Fi and touchpad PnP IDs in Hardware JSON and Devices CSV. ASUS X441 variants have different drivers; match INF drivers by actual IDs.
5. Review Get-FileHash SHA-256 and DISM Get-WimInfo in ISO-Preparation.log. Do not assume an edition image index.
6. Back up user data and drivers before installing: from the ASUS computer run as administrator `Export-WindowsDriver -Online -Destination C:\DoomOS\Backups\CurrentDrivers` after creating that destination.
7. Verify Windows Update, Defender, Firewall, Recovery Environment and Microsoft Store remain intact in subsequent phases.

Troubleshooting: Access denied means run elevated; if ISO\Working exists the script intentionally stops; Microsoft media may contain either install.esd or install.wim; a DISM error may indicate broken ISO, insufficient space or unexpected image format. Stop rather than modifying the installed OS.

**Never post hardware reports before redacting serial numbers. Never run destructive partition commands without explicit consent.**
