#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET_USER="${SUDO_USER:-pi}"
TARGET_HOME="$(eval echo "~$TARGET_USER")"

if [[ $EUID -ne 0 ]]; then
  echo "Please run install.sh with sudo/root"
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y \
  python3 python3-pip python3-tk python3-yaml \
  xserver-xorg x11-xserver-utils xinit openbox unclutter \
  chromium-browser matchbox-keyboard dfu-util usbutils git rsync

install -d -m 0755 "$TARGET_HOME/configapp"
rsync -a --delete "$REPO_ROOT/" "$TARGET_HOME/configapp/"
chown -R "$TARGET_USER:$TARGET_USER" "$TARGET_HOME/configapp"

usermod -aG dialout,plugdev "$TARGET_USER"

cat >/etc/udev/rules.d/99-field-configurator.rules <<'RULES'
SUBSYSTEM=="tty", ATTRS{idVendor}=="0483", MODE="0660", GROUP="dialout"
SUBSYSTEM=="usb", ATTR{idVendor}=="0483", MODE="0660", GROUP="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2e8a", MODE="0660", GROUP="plugdev"
RULES
udevadm control --reload-rules
udevadm trigger || true

install -D -m 0644 "$TARGET_HOME/configapp/scripts/field-configurator.service" "/etc/systemd/system/field-configurator@.service"
systemctl daemon-reload
systemctl enable "field-configurator@${TARGET_USER}.service"
systemctl restart "field-configurator@${TARGET_USER}.service" || true

sudo -u "$TARGET_USER" python3 "$TARGET_HOME/configapp/tools/firmware_indexer.py"

"$TARGET_HOME/configapp/scripts/first_run_check.sh" || true

echo "Install complete. Reboot recommended."
