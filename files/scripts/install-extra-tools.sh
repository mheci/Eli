#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# SCSKiller ships a Linux AppImage; the desktop file lives in files/system.
curl -fsSL -o /usr/bin/scskiller https://github.com/BlueHeisenberg/SCSKiller/releases/latest/download/SCSKiller-x86_64.AppImage
chmod 0755 /usr/bin/scskiller
curl -fsSL -o "$tmp/scskiller.png" https://raw.githubusercontent.com/BlueHeisenberg/SCSKiller/main/.github/assets/logo.png
install -Dm644 "$tmp/scskiller.png" /usr/share/icons/hicolor/256x256/apps/scskiller.png

# The base image ships blujust, not ujust; expose the same recipes under both names.
if [[ ! -x /usr/bin/ujust && -x /usr/bin/blujust ]]; then
    printf '#!/usr/bin/env bash\nexec /usr/bin/blujust "$@"\n' > /usr/bin/ujust
    chmod 0755 /usr/bin/ujust
fi
