# Eli

[![bluebuild build badge](https://github.com/mheci/Eli/actions/workflows/build.yml/badge.svg)](https://github.com/mheci/Eli/actions/workflows/build.yml)

Personal Fedora Kinoite image built with [BlueBuild](https://blue-build.org/) on top of
`ghcr.io/blue-build/base-images/fedora-kinoite-nvidia-open` (Fedora with the NVIDIA open
kernel modules).

Preinstalled:

- Terminals: [Ghostty](https://ghostty.org) (Terra), [Kitty](https://sw.kovidgoyal.net/kitty/)
- Editor: [Zed](https://zed.dev) (Terra)
- Dev: [OpenCode Desktop](https://opencode.ai/desktop), [Claude Code](https://claude.com/claude-code),
  [Codex](https://github.com/openai/codex), [T3 Code](https://github.com/pingdotgg/t3code) (Terra),
  [Bun](https://bun.sh), [Deno](https://deno.com), [uv](https://docs.astral.sh/uv/),
  [mise](https://mise.jdx.dev)
- Gaming: [Steam](https://store.steampowered.com) (Terra),
  [Faugus Launcher](https://github.com/Faugus/faugus-launcher) (Terra),
  [SCSKiller](https://github.com/BlueHeisenberg/SCSKiller), [Unity Hub](https://unity.com/unity-hub) (Flathub)
- Media: mpv, ffmpeg, yt-dlp, qBittorrent
- Audio: RNNoise microphone noise suppression via a PipeWire filter chain
- Tools: btop, gdu, nvtop, KDE Connect, Wireshark

The [Terra](https://terrapkg.com) and [RPM Fusion](https://rpmfusion.org) repositories are enabled.
Steam is installed natively from Terra, with the 32-bit `libfdk-aac` from negativo17 that Bazzite
also uses. Unity Hub stays a Flatpak because Unity's own RPM repository is stuck on 3.15.2 while
Flathub ships 3.22.6.

## Runtime setup

After the first boot, run:

```
ujust setup
```

This adds your user to the `wireshark` group (and `libvirt`/`docker` if they exist), opens the KDE
Connect firewall ports, and applies the configured Flatpaks immediately. Group changes need a log out
and back in. The steps are also available separately as `ujust setup-groups`,
`ujust setup-kdeconnect`, and `ujust setup-flatpaks`.

Android development:

```
ujust setup-android-studio
```

Installs the latest stable Android Studio to `~/.local/opt/android-studio`, creates the `studio`
launcher and desktop entry, and adds you to the `adbusers` and `kvm` groups. The image already ships
`android-tools`, the Android udev rules, and KVM support, so no layering or reboot is needed; log out
and back in for the groups to apply. The SDK wizard installs the SDK to `~/Android/Sdk`.

AI agents:

```
ujust setup-hermes
```

Installs the [Hermes Agent](https://github.com/NousResearch/hermes-agent) CLI for the current user,
then prints the command to run its setup wizard.

Microphone noise suppression is provided by
[noise-suppression-for-voice](https://github.com/werman/noise-suppression-for-voice). Pick
**Noise Canceling source** as the input in your app or desktop settings. After an image update,
`ujust setup-noise-suppression` restarts PipeWire so the source is reloaded.

To capture packets in Wireshark without root, `ujust setup-groups` handles the group membership.

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
