# Secure Teams releases

Static-file release host. Konsumsi:

- **App update menu** baca `manifest.json` (latestVersion + per-OS download URL) dan compare dengan versi terinstal.
- **Installer one-liner** (`install.sh` / `install.ps1`) baca manifest, ambil binary OS pengunjung, install otomatis.
- **Manual download** lewat folder `v<version>/`.

## Layout

```
rick-releases/
├── manifest.json        ← single source of truth, baca app + installer
├── install.sh           ← one-liner installer (Linux/macOS)
├── install.ps1          ← one-liner installer (Windows)
└── v<version>/
    ├── secure-teams-windows.zip
    ├── secure-teams-macos.zip
    ├── secure-teams-linux.tar.gz
    └── secure-teams-android.apk
```

## Bagaimana di-update

### Otomatis via CI (recommended)

1. Di repo `rick`: bump `apps/client/pubspec.yaml` versi
2. Tag commit: `git tag v0.2.0 && git push origin v0.2.0`
3. GitHub Actions (`.github/workflows/release.yml`) build Win/Mac/Linux/Android, push hasil + manifest update ke sini.

Butuh `RELEASES_TOKEN` (PAT dengan write akses ke repo ini) di-set sebagai secret di repo `rick`.

### Manual (host OS yang sama dengan target)

```bash
cd /path/to/rick
bash scripts/release.sh 0.2.0
```

Script build untuk current OS lalu push ke sini. Hanya OS host yang ke-build (Windows build perlu Windows machine, dst).

## One-liner install

**Linux/macOS:**
```bash
curl -sSfL https://raw.githubusercontent.com/whyaskingme/rick-releases/main/install.sh | bash
```

**Windows:**
```powershell
iwr -useb https://raw.githubusercontent.com/whyaskingme/rick-releases/main/install.ps1 | iex
```

## Manifest format

```json
{
  "latestVersion": "0.2.0",
  "releaseNotes": "Plain text release notes",
  "downloads": {
    "windows": "https://github.com/whyaskingme/rick-releases/raw/main/v0.2.0/secure-teams-windows.zip",
    "macos":   "https://github.com/whyaskingme/rick-releases/raw/main/v0.2.0/secure-teams-macos.zip",
    "linux":   "https://github.com/whyaskingme/rick-releases/raw/main/v0.2.0/secure-teams-linux.tar.gz",
    "android": "https://github.com/whyaskingme/rick-releases/raw/main/v0.2.0/secure-teams-android.apk",
    "ios":     "https://testflight.apple.com/join/PLACEHOLDER"
  }
}
```

Field tidak wajib semua — kalau `downloads.macos` kosong, app + installer skip platform tersebut dengan pesan "tidak tersedia untuk OS ini".
