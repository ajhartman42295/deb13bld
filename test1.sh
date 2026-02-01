#!/usr/bin/env bash
set -euo pipefail

# Minimal KDE Plasma + LightDM on Debian (low bloat, max control)
# Run as root (recommended): sudo bash kde-lightdm-min.sh

export DEBIAN_FRONTEND=noninteractive

need_root() {
  if [ "${EUID:-$(id -u)}" -ne 0 ]; then
    echo "Run as root: sudo bash $0"
    exit 1
  fi
}

apt_base() {
  apt-get update
  apt-get install -y --no-install-recommends ca-certificates apt-transport-https
}

set_default_dm_lightdm() {
  # Preseed default display manager to avoid prompts
  echo "lightdm shared/default-x-display-manager select lightdm" | debconf-set-selections
}

install_display_stack_x11() {
  apt-get install -y --no-install-recommends \
    xorg xserver-xorg-core xinit
}

install_plasma_minimal() {
  apt-get install -y --no-install-recommends \
    plasma-desktop \
    plasma-workspace \
    plasma-workspace-bin \
    kde-cli-tools \
    kwayland-integration \
    systemsettings \
    kscreen
}

install_lightdm() {
  apt-get install -y --no-install-recommends \
    lightdm lightdm-gtk-greeter
}

install_audio_minimal() {
  apt-get install -y --no-install-recommends \
    pipewire pipewire-audio wireplumber
}

install_fonts_minimal() {
  apt-get install -y --no-install-recommends \
    fonts-dejavu fonts-noto-core
}

optional_practicals() {
  # Uncomment what you actually want.
  apt-get install -y --no-install-recommends \
    dolphin \
    network-manager plasma-nm
  # For a simple audio control GUI, add:
  # apt-get install -y --no-install-recommends pavucontrol
}

configure_lightdm_defaults() {
  install -d /etc/lightdm/lightdm.conf.d
  cat >/etc/lightdm/lightdm.conf.d/10-minimal-kde.conf <<'EOF'
[Seat:*]
greeter-session=lightdm-gtk-greeter
user-session=plasma
EOF
}

enable_services() {
  # Disable SDDM if it exists, enable LightDM
  systemctl disable --now sddm >/dev/null 2>&1 || true
  systemctl enable --now lightdm
}

cleanup() {
  apt-get autoremove -y
  apt-get clean
}

main() {
  need_root
  apt_base
  set_default_dm_lightdm
  install_display_stack_x11
  install_plasma_minimal
  install_audio_minimal
  install_fonts_minimal
  install_lightdm
  optional_practicals
  configure_lightdm_defaults
  enable_services
  cleanup
  echo "Done. Reboot."
}

main "$@"