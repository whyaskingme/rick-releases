#!/usr/bin/env bash
# Secure Teams installer.
#
# Usage (one-liner):
#   curl -sSfL https://raw.githubusercontent.com/whyaskingme/rick-releases/main/install.sh | bash
#
# Detects Linux/macOS, fetches manifest.json from rick-releases, downloads
# the right binary, extracts to $HOME/.local/share/secureteams (Linux) or
# /Applications (macOS), and adds a launcher / desktop entry.
#
# For Windows, see install.ps1 (or download the .exe from the manifest).

set -euo pipefail

MANIFEST_URL="${MANIFEST_URL:-https://raw.githubusercontent.com/whyaskingme/rick-releases/main/manifest.json}"

err() { echo "error: $*" >&2; exit 1; }
info() { echo "→ $*"; }

# ---------- Detect OS ----------
case "$(uname -s)" in
  Linux*)  PLATFORM=linux ;;
  Darwin*) PLATFORM=macos ;;
  MINGW*|MSYS*|CYGWIN*) err "Windows: gunakan install.ps1, atau download .exe dari rick-releases" ;;
  *) err "OS tidak didukung: $(uname -s)" ;;
esac
info "Platform: ${PLATFORM}"

# ---------- Required tools ----------
for cmd in curl jq tar; do
  command -v "${cmd}" >/dev/null || err "${cmd} tidak ada — pasang dulu (apt install ${cmd} / brew install ${cmd})"
done

# ---------- Fetch manifest ----------
info "Cek versi terbaru di ${MANIFEST_URL}"
manifest=$(curl -sSfL "${MANIFEST_URL}") || err "gagal ambil manifest"
version=$(echo "${manifest}" | jq -r '.latestVersion')
url=$(echo "${manifest}" | jq -r ".downloads.${PLATFORM} // empty")

[[ -n "${version}" && "${version}" != "null" ]] || err "manifest.latestVersion kosong"
[[ -n "${url}" ]] || err "manifest.downloads.${PLATFORM} kosong — release belum di-build untuk OS ini"

info "Versi terbaru: ${version}"
info "Download: ${url}"

# ---------- Download ----------
tmpdir=$(mktemp -d)
trap 'rm -rf "${tmpdir}"' EXIT
archive="${tmpdir}/secureteams-${PLATFORM}.archive"

curl -sSfL --progress-bar "${url}" -o "${archive}"

# ---------- Install ----------
case "${PLATFORM}" in
  linux)
    target="${HOME}/.local/share/secureteams"
    mkdir -p "${target}"
    case "${url}" in
      *.tar.gz|*.tgz) tar -xzf "${archive}" -C "${target}" --strip-components=1 ;;
      *.zip)          command -v unzip >/dev/null || err "unzip tidak ada"
                      unzip -qo "${archive}" -d "${target}" ;;
      *)              err "format archive tidak dikenali: ${url}" ;;
    esac

    # Desktop entry untuk app launchers (GNOME/KDE/dll)
    apps="${HOME}/.local/share/applications"
    mkdir -p "${apps}"
    cat > "${apps}/secureteams.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Secure Teams
Comment=Mullvad-gated Teams client
Exec=${target}/secure_teams_client
Icon=${target}/data/flutter_assets/assets/icons/icon.png
Terminal=false
Categories=Network;Chat;
EOF
    info "Terinstall di ${target}"
    info "Launcher: ${apps}/secureteams.desktop"
    ;;

  macos)
    # .dmg: mount, copy .app, unmount. .zip: extract directly to /Applications.
    case "${url}" in
      *.dmg)
        mountpoint="${tmpdir}/mnt"
        mkdir -p "${mountpoint}"
        hdiutil attach -quiet -nobrowse -mountpoint "${mountpoint}" "${archive}"
        cp -R "${mountpoint}/Secure Teams.app" /Applications/
        hdiutil detach -quiet "${mountpoint}"
        ;;
      *.zip)
        unzip -qo "${archive}" -d "${tmpdir}"
        cp -R "${tmpdir}/Secure Teams.app" /Applications/
        ;;
      *) err "format archive tidak dikenali: ${url}" ;;
    esac
    info "Terinstall di /Applications/Secure Teams.app"
    info "Buka via: open '/Applications/Secure Teams.app'"
    ;;
esac

info "Selesai. Versi ${version} aktif."
info "Catatan: app butuh Mullvad VPN aktif untuk konek ke server."
