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

# Run every runtime setup step once.
setup: setup-groups setup-kdeconnect setup-flatpaks
