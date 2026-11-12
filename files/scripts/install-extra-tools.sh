#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# SCSKiller ships a Linux AppImage; the desktop file lives in files/system.
curl -fsSL -o /usr/bin/scskiller https://github.com/BlueHeisenberg/SCSKiller/releases/latest/download/SCSKiller-x86_64.AppImage
chmod 0755 /usr/bin/scskiller
curl -fsSL -o "$tmp/scskiller.png" https://raw.githubusercontent.com/BlueHeisenberg/SCSKiller/main/.github/assets/logo.png
install -Dm644 "$tmp/scskiller.png" /usr/share/icons/hicolor/256x256/apps/scskiller.png

# RNNoise LADSPA plugin used by the PipeWire denoising source.
curl -fsSL -o "$tmp/rnnoise.zip" https://github.com/werman/noise-suppression-for-voice/releases/latest/download/linux-rnnoise.zip
unzip -q "$tmp/rnnoise.zip" -d "$tmp/rnnoise"
install -Dm755 "$tmp/rnnoise/linux-rnnoise/ladspa/librnnoise_ladspa.so" /usr/lib64/ladspa/librnnoise_ladspa.so

# Spotifast ships a native RPM; resolve the latest tag from the release redirect.
spotifast_tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/crmne/spotifast/releases/latest | sed 's|.*/tag/||')"
dnf install -y "https://github.com/crmne/spotifast/releases/download/${spotifast_tag}/spotifast-${spotifast_tag#v}-1.x86_64.rpm"
rpm -q spotifast

# Blocky DNS proxy.
blocky_tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/0xERR0R/blocky/releases/latest | sed 's|.*/tag/||')"
mkdir -p "$tmp/blocky"
curl -fsSL -o "$tmp/blocky.tgz" "https://github.com/0xERR0R/blocky/releases/download/${blocky_tag}/blocky_${blocky_tag}_Linux_x86_64.tar.gz"
tar -xzf "$tmp/blocky.tgz" -C "$tmp/blocky"
install -Dm755 "$tmp/blocky/blocky" /usr/bin/blocky

# profile-sync-daemon (not packaged for Fedora 45).
curl -fsSL -o "$tmp/psd.tar.gz" "https://github.com/graysky2/profile-sync-daemon/archive/refs/tags/v8.0.tar.gz"
tar -xzf "$tmp/psd.tar.gz" -C "$tmp"
psd_dir="$(find "$tmp" -maxdepth 1 -type d -name 'profile-sync-daemon-*' -print -quit)"
make -C "$psd_dir" install

# The base image ships blujust, not ujust; expose the same recipes under both names.
if [[ ! -x /usr/bin/ujust && -x /usr/bin/blujust ]]; then
    printf '#!/usr/bin/env bash\nexec /usr/bin/blujust "$@"\n' > /usr/bin/ujust
    chmod 0755 /usr/bin/ujust
fi
