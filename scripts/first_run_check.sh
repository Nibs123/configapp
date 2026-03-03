#!/usr/bin/env bash
set -euo pipefail

echo "== Field Configurator first-run checks =="

echo "[1/4] Display session"
if [[ -n "${DISPLAY:-}" ]] || pgrep -x Xorg >/dev/null; then
  echo "  OK: Display server appears available"
else
  echo "  WARN: No DISPLAY detected. Run from kiosk session for full validation."
fi

echo "[2/4] Chromium"
if command -v chromium-browser >/dev/null; then
  echo "  OK: chromium-browser found"
else
  echo "  FAIL: chromium-browser missing"
fi

echo "[3/4] USB serial permissions"
for dev in /dev/ttyACM* /dev/ttyUSB*; do
  [[ -e "$dev" ]] || continue
  stat -c "  %n owner=%U group=%G mode=%a" "$dev"
done
if id -nG | tr ' ' '\n' | grep -q '^dialout$'; then
  echo "  OK: user in dialout group"
else
  echo "  WARN: user not in dialout group"
fi

echo "[4/4] dfu-util"
if command -v dfu-util >/dev/null; then
  dfu-util --version | head -n1
else
  echo "  FAIL: dfu-util not installed"
fi
