#!/usr/bin/env bash
set -euo pipefail

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Bun and Deno only ship as release archives.
curl -fsSL -o "$tmp/bun.zip" https://github.com/oven-sh/bun/releases/latest/download/bun-linux-x64.zip
unzip -q "$tmp/bun.zip" -d "$tmp/bun"
install -Dm755 "$tmp/bun/bun-linux-x64/bun" /usr/bin/bun

curl -fsSL -o "$tmp/deno.zip" https://github.com/denoland/deno/releases/latest/download/deno-x86_64-unknown-linux-gnu.zip
unzip -q "$tmp/deno.zip" -d "$tmp/deno"
install -Dm755 "$tmp/deno/deno" /usr/bin/deno

# SCSKiller ships a Linux AppImage; the desktop file lives in files/system.
curl -fsSL -o /usr/bin/scskiller https://github.com/BlueHeisenberg/SCSKiller/releases/latest/download/SCSKiller-x86_64.AppImage
chmod 0755 /usr/bin/scskiller
curl -fsSL -o "$tmp/scskiller.png" https://raw.githubusercontent.com/BlueHeisenberg/SCSKiller/main/.github/assets/logo.png
install -Dm644 "$tmp/scskiller.png" /usr/share/icons/hicolor/256x256/apps/scskiller.png

bun --version
deno --version
