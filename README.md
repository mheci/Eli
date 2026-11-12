# Eli

[![bluebuild build badge](https://github.com/mheci/Eli/actions/workflows/build.yml/badge.svg)](https://github.com/mheci/Eli/actions/workflows/build.yml)

Personal Fedora Kinoite image built with [BlueBuild](https://blue-build.org/) on top of
`ghcr.io/blue-build/base-images/fedora-kinoite-nvidia-open` (Fedora with the NVIDIA open
kernel modules).

Preinstalled:

- Terminals: [Ghostty](https://ghostty.org) (Terra), [Kitty](https://sw.kovidgoyal.net/kitty/)
- Editor: [Zed](https://zed.dev) (Terra)
- Dev: [OpenCode Desktop](https://opencode.ai/desktop), [Claude Code](https://claude.com/claude-code),
  [Codex](https://github.com/openai/codex), [Bun](https://bun.sh), [Deno](https://deno.com),
  [uv](https://docs.astral.sh/uv/), [mise](https://mise.jdx.dev)
- Gaming: [Steam](https://store.steampowered.com) (Terra),
  [Faugus Launcher](https://github.com/Faugus/faugus-launcher) (Terra),
  [SCSKiller](https://github.com/BlueHeisenberg/SCSKiller), [Unity Hub](https://unity.com/unity-hub) (Flathub)
- Media: mpv, ffmpeg, yt-dlp, qBittorrent
- Tools: btop, gdu, nvtop, KDE Connect, Wireshark

The [Terra](https://terrapkg.com) and [RPM Fusion](https://rpmfusion.org) repositories are enabled, so
their packages can be layered on later. Unity Hub stays a Flatpak because Unity's own RPM repository is
stuck on 3.15.2 while Flathub ships 3.22.6.

To capture packets in Wireshark without root, join the `wireshark` group once:
`sudo usermod -aG wireshark $USER` (log out and back in).

## Installation

> [!WARNING]
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```
  rpm-ostree rebase ostree-unverified-registry:ghcr.io/mheci/eli:latest
  ```
- Reboot to complete the rebase:
  ```
  systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```
  rpm-ostree rebase ostree-image-signed:docker://ghcr.io/mheci/eli:latest
  ```
- Reboot again to complete the installation
  ```
  systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the
Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

> [!NOTE]
> The BlueBuild base images sign the kernel and akmods with their own key. If Secure Boot is enabled
> on a machine coming from a Universal Blue image, enroll the BlueBuild key once with `mokutil`:
> https://github.com/blue-build/base-images#migration-from-ublue-base-images

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign).
You can verify the signature by downloading the `cosign.pub` file from this repo and running:

```
cosign verify --key cosign.pub ghcr.io/mheci/eli:latest
```
