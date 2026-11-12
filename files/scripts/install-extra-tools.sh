#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# shortcut: Spotifast, Blocky, SCSKiller and OpenCode follow upstream latest;
# a bad release can enter the next build. Pin versions + Renovate if full
# reproducibility matters.

# SCSKiller ships a Linux AppImage; the desktop file lives in files/system.
curl -fsSL -o "$tmp/SCSKiller-x86_64.AppImage" https://github.com/BlueHeisenberg/SCSKiller/releases/latest/download/SCSKiller-x86_64.AppImage
curl -fsSL -o "$tmp/scskiller.sha" https://github.com/BlueHeisenberg/SCSKiller/releases/latest/download/SHA256SUMS-linux.txt
(cd "$tmp" && grep ' SCSKiller-x86_64.AppImage$' scskiller.sha | sha256sum -c -)
install -Dm755 "$tmp/SCSKiller-x86_64.AppImage" /usr/bin/scskiller
curl -fsSL -o "$tmp/scskiller.png" https://raw.githubusercontent.com/BlueHeisenberg/SCSKiller/main/.github/assets/logo.png
install -Dm644 "$tmp/scskiller.png" /usr/share/icons/hicolor/256x256/apps/scskiller.png

# RNNoise LADSPA plugin used by the PipeWire denoising source.
rnnoise_sha="811390b6eb6e28dde023c70590c74d26e74ebb2e595bcf4b95af2341db160e99"
curl -fsSL -o "$tmp/rnnoise.zip" https://github.com/werman/noise-suppression-for-voice/releases/download/v1.10/linux-rnnoise.zip
echo "${rnnoise_sha}  $tmp/rnnoise.zip" | sha256sum -c -
unzip -q "$tmp/rnnoise.zip" -d "$tmp/rnnoise"
install -Dm755 "$tmp/rnnoise/linux-rnnoise/ladspa/librnnoise_ladspa.so" /usr/lib64/ladspa/librnnoise_ladspa.so

# Spotifast ships a native RPM; take the asset name from the release so a
# release-number bump does not break the URL.
spotifast_release="$(curl -fsSL https://api.github.com/repos/crmne/spotifast/releases/latest)"
spotifast_tag="$(jq -r '.tag_name' <<<"$spotifast_release")"
spotifast_url="$(jq -r 'first(.assets[] | select(.name | test("x86_64\\.rpm$")) | .browser_download_url)' <<<"$spotifast_release")"
spotifast_name="$(basename "$spotifast_url")"
curl -fsSL -o "$tmp/$spotifast_name" "$spotifast_url"
curl -fsSL -o "$tmp/spotifast.sha" "https://github.com/crmne/spotifast/releases/download/${spotifast_tag}/packaging-checksums.txt"
(cd "$tmp" && grep " $spotifast_name$" spotifast.sha | sha256sum -c -)
dnf install -y "$tmp/$spotifast_name"
rpm -q spotifast

# Unity Hub native RPM. Pin the version and hash so the signed image does not
# trust whatever the CDN serves.
unity_version="3.22.6"
unity_sha="ed711890f67bea71a99d37e2887f51c8ba41a5be894a3f5cadc7bbf518840b9d"
unity_rpm="UnityHubSetup-${unity_version}-x86_64.rpm"
curl -fsSL -o "$tmp/$unity_rpm" "https://public-cdn.cloud.unity3d.com/hub/prod/${unity_version}/${unity_rpm}"
echo "${unity_sha}  $tmp/$unity_rpm" | sha256sum -c -
# shortcut: the RPM %posttrans hangs in the build (it adds Unity's update repo
# and runs yum check-update), so it is skipped. The app is not launched in CI.
timeout 600 dnf install -y --setopt=tsflags=noscripts "$tmp/$unity_rpm"
rpm -q unityhub

# Blocky DNS proxy.
blocky_tag="$(curl -fsSLI -o /dev/null -w '%{url_effective}' https://github.com/0xERR0R/blocky/releases/latest | sed 's|.*/tag/||')"
blocky_name="blocky_${blocky_tag}_Linux_x86_64.tar.gz"
curl -fsSL -o "$tmp/$blocky_name" "https://github.com/0xERR0R/blocky/releases/download/${blocky_tag}/${blocky_name}"
curl -fsSL -o "$tmp/blocky.sha" "https://github.com/0xERR0R/blocky/releases/download/${blocky_tag}/blocky_checksums.txt"
(cd "$tmp" && grep " $blocky_name$" blocky.sha | sha256sum -c -)
mkdir -p "$tmp/blocky"
tar -xzf "$tmp/$blocky_name" -C "$tmp/blocky"
install -Dm755 "$tmp/blocky/blocky" /usr/bin/blocky

# OpenCode Desktop: take the newest GitHub release that ships the desktop RPM,
# then verify the matching checksum before installing.
opencode_release="$(curl -fsSL 'https://api.github.com/repos/anomalyco/opencode/releases?per_page=100' | jq -r 'first(.[] | select(any(.assets[]; .name == "opencode-desktop-linux-x86_64.rpm")))')"
opencode_tag="$(jq -r '.tag_name' <<<"$opencode_release")"
opencode_url="$(jq -r 'first(.assets[] | select(.name == "opencode-desktop-linux-x86_64.rpm") | .browser_download_url)' <<<"$opencode_release")"
curl -fsSL -o "$tmp/opencode-desktop-linux-x86_64.rpm" "$opencode_url"
curl -fsSL -o "$tmp/opencode.sha" "https://github.com/anomalyco/opencode/releases/download/${opencode_tag}/SHA256SUMS"
(cd "$tmp" && grep ' opencode-desktop-linux-x86_64.rpm$' opencode.sha | sha256sum -c -)
dnf install -y "$tmp/opencode-desktop-linux-x86_64.rpm"

# profile-sync-daemon (not packaged for Fedora 45).
psd_sha="620aaff56c0aa2a96de31f545b6fd8f51f60e1bbb1bcd6f4e039fb04e351630d"
curl -fsSL -o "$tmp/psd.tar.gz" "https://github.com/graysky2/profile-sync-daemon/archive/refs/tags/v8.0.tar.gz"
echo "${psd_sha}  $tmp/psd.tar.gz" | sha256sum -c -
tar -xzf "$tmp/psd.tar.gz" -C "$tmp"
psd_dir="$(find "$tmp" -maxdepth 1 -type d -name 'profile-sync-daemon-*' -print -quit)"
make -C "$psd_dir" install

# Catch shell syntax errors in the runtime recipes before they ship.
# shortcut: syntax only; the systemd and desktop steps need a live session.
for recipe in setup-groups setup-kdeconnect setup-noise-suppression setup-psd setup-blocky setup-android-studio setup-hermes; do
    just --justfile /usr/share/bluebuild/justfile --dry-run "$recipe" | bash -n
done

# The base image ships blujust, not ujust; expose the same recipes under both names.
if [[ ! -x /usr/bin/ujust && -x /usr/bin/blujust ]]; then
    printf '#!/usr/bin/env bash\nexec /usr/bin/blujust "$@"\n' > /usr/bin/ujust
    chmod 0755 /usr/bin/ujust
fi
