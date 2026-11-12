# Add the current user to the groups used by the installed tools.
setup-groups:
    #!/usr/bin/env bash
    set -euo pipefail
    for group in wireshark libvirt docker; do
        if getent group "$group" >/dev/null; then
            sudo usermod -aG "$group" "$USER"
            echo "Added $USER to $group"
        fi
    done
    echo "Log out and back in for group changes to take effect."

# Open the firewall ports KDE Connect uses.
setup-kdeconnect:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v firewall-cmd >/dev/null; then
        echo "firewalld is not installed; nothing to do."
        exit 0
    fi
    if ! systemctl is-active --quiet firewalld; then
        echo "firewalld is not running; nothing to do."
        exit 0
    fi
    sudo firewall-cmd --permanent --add-port=1714-1764/tcp
    sudo firewall-cmd --permanent --add-port=1714-1764/udp
    sudo firewall-cmd --reload
    echo "Opened KDE Connect ports 1714-1764."

# Install the configured system Flatpaks now instead of at first boot.
setup-flatpaks:
    #!/usr/bin/env bash
    set -euo pipefail
    sudo bluebuild-flatpak-manager apply system

# Restart PipeWire so the RNNoise Noise Canceling source appears.
setup-noise-suppression:
    #!/usr/bin/env bash
    set -euo pipefail
    if [ ! -f /usr/lib64/ladspa/librnnoise_ladspa.so ]; then
        echo "The RNNoise LADSPA plugin is missing from this image."
        exit 1
    fi
    systemctl --user restart pipewire.service wireplumber.service
    echo "Restarted PipeWire. Select 'Noise Canceling source' as your microphone."

# Set up profile-sync-daemon for the current user.
setup-psd:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v psd >/dev/null; then
        echo "profile-sync-daemon is not installed."
        exit 1
    fi
    # The first start writes ~/.config/psd/psd.conf and exits; restart applies it.
    systemctl --user enable --now psd.service
    systemctl --user restart psd.service
    echo "profile-sync-daemon is enabled. Edit ~/.config/psd/psd.conf to choose browsers, then run: systemctl --user restart psd.service"

# Enable the Blocky DNS proxy if ports 53 and 4000 are free.
setup-blocky:
    #!/usr/bin/env bash
    set -euo pipefail
    if ! command -v blocky >/dev/null; then
        echo "Blocky is not installed."
        exit 1
    fi
    for port in 53 4000; do
        if ss -ltnH "sport = :$port" | grep -q . || ss -lunH "sport = :$port" | grep -q .; then
            echo "Port $port is already in use:"
            ss -ltnp "sport = :$port"
            ss -lunp "sport = :$port"
            echo "Free it (for example, disable the systemd-resolved stub listener) before enabling Blocky."
            exit 1
        fi
    done
    sudo systemctl enable --now blocky.service
    echo "Blocky is running on port 53. Point your DNS at 127.0.0.1."

# Run every runtime setup step once.
setup: setup-groups setup-kdeconnect setup-flatpaks

# Install the latest stable Android Studio and set up adb, udev rules and KVM access.
setup-android-studio:
    #!/usr/bin/env bash
    set -euo pipefail

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT

    release="$(curl -fsSL https://jb.gg/android-studio-releases-list.json | jq -r '
        [ .content.item[]
          | select(.channel == "Release" or .channel == "Patch")
          | . as $r
          | ($r.download[] | select(.link | endswith("-linux.tar.gz")))
          | {version: $r.version, url: .link, sha: .checksum}
        ][0]
        | "\(.version)\t\(.url)\t\(.sha)"
    ')"
    IFS=$'\t' read -r version url sha <<<"$release"

    installed=""
    if [ -f "$HOME/.local/opt/android-studio/product-info.json" ]; then
        installed="$(jq -r '.version' "$HOME/.local/opt/android-studio/product-info.json" 2>/dev/null || true)"
    fi

    if [ "$installed" = "$version" ]; then
        echo "Android Studio $version is already installed."
    else
        echo "Downloading Android Studio $version..."
        curl -fL --progress-bar "$url" -o "$tmp/studio.tar.gz"
        echo "$sha  $tmp/studio.tar.gz" | sha256sum -c -
        mkdir -p "$HOME/.local/opt"
        rm -rf "$tmp/extract"
        mkdir -p "$tmp/extract"
        tar -xzf "$tmp/studio.tar.gz" -C "$tmp/extract"
        rm -rf "$HOME/.local/opt/android-studio"
        mv "$tmp/extract/android-studio" "$HOME/.local/opt/android-studio"
        echo "Installed Android Studio $version."
    fi

    launcher="$HOME/.local/opt/android-studio/bin/studio.sh"
    [ -x "$launcher" ] || launcher="$HOME/.local/opt/android-studio/bin/studio"
    icon="$HOME/.local/opt/android-studio/bin/studio.png"
    [ -f "$icon" ] || icon="android-studio"

    mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
    ln -sf "$launcher" "$HOME/.local/bin/studio"
    cat > "$HOME/.local/share/applications/android-studio.desktop" <<EOF
    [Desktop Entry]
    Type=Application
    Name=Android Studio
    Comment=Android development environment
    Exec=$launcher %f
    Icon=$icon
    Terminal=false
    Categories=Development;IDE;
    StartupWMClass=jetbrains-studio
    EOF

    sudo groupadd -f adbusers
    sudo groupadd -f kvm
    for group in adbusers kvm; do
        sudo usermod -aG "$group" "$USER"
    done
    sudo udevadm control --reload-rules

    echo
    echo "Android Studio $version is ready."
    echo "Log out and back in for the adbusers and kvm groups to apply."
    echo "The SDK wizard will install the SDK to ~/Android/Sdk."
    if [ ! -e /dev/kvm ]; then
        echo "Warning: /dev/kvm is missing. Enable VT-x/AMD-V in firmware for the emulator."
    fi

# Install the Hermes Agent CLI for the current user.
setup-hermes:
    #!/usr/bin/env bash
    set -euo pipefail
    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive
    echo
    echo "Hermes Agent installed. Reload your shell, then run: hermes setup --portal"

alias setup-hermes-agent := setup-hermes
