# Secure Teams installer for Windows (PowerShell).
#
# Usage:
#   iwr -useb https://raw.githubusercontent.com/whyaskingme/rick-releases/main/install.ps1 | iex
#
# Downloads latest .zip from rick-releases manifest, extracts to
# %LOCALAPPDATA%\SecureTeams, adds a Start Menu shortcut.

$ErrorActionPreference = 'Stop'

$ManifestUrl = if ($env:MANIFEST_URL) { $env:MANIFEST_URL } else {
  'https://raw.githubusercontent.com/whyaskingme/rick-releases/main/manifest.json'
}

Write-Host "→ Cek versi terbaru di $ManifestUrl"
$manifest = Invoke-RestMethod -Uri $ManifestUrl -Headers @{ 'Cache-Control' = 'no-cache' }
$version = $manifest.latestVersion
$url = $manifest.downloads.windows

if (-not $version) { throw 'manifest.latestVersion kosong' }
if (-not $url) { throw 'manifest.downloads.windows kosong — release belum di-build untuk Windows' }

Write-Host "→ Versi terbaru: $version"
Write-Host "→ Download: $url"

$target = Join-Path $env:LOCALAPPDATA 'SecureTeams'
if (-not (Test-Path $target)) { New-Item -Type Directory -Path $target | Out-Null }

$tmp = Join-Path $env:TEMP "secureteams-$([guid]::NewGuid()).zip"
Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing

Write-Host "→ Extract ke $target"
Expand-Archive -Path $tmp -DestinationPath $target -Force
Remove-Item $tmp

# Start Menu shortcut
$exePath = Join-Path $target 'secure_teams_client.exe'
if (-not (Test-Path $exePath)) {
  # Fallback: cari .exe di dalam $target
  $exePath = (Get-ChildItem -Path $target -Recurse -Filter '*.exe' | Select-Object -First 1).FullName
}
$shortcutPath = Join-Path $env:APPDATA 'Microsoft\Windows\Start Menu\Programs\Secure Teams.lnk'
$WshShell = New-Object -ComObject WScript.Shell
$lnk = $WshShell.CreateShortcut($shortcutPath)
$lnk.TargetPath = $exePath
$lnk.WorkingDirectory = $target
$lnk.Description = 'Mullvad-gated Teams client'
$lnk.Save()

Write-Host "→ Terinstall di $target"
Write-Host "→ Shortcut: $shortcutPath"
Write-Host "Selesai. Versi $version aktif. Butuh Mullvad VPN aktif untuk konek."
