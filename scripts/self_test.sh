#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

echo "Running self-test in $REPO_ROOT"

python3 -m compileall "$REPO_ROOT/launcher" "$REPO_ROOT/tools"

if command -v systemd-analyze >/dev/null; then
  TMP_UNIT="$(mktemp --suffix=.service)"
  sed 's/User=%i/User=pi/; s/Group=%i/Group=pi/; s|%h|/home/pi|g' "$REPO_ROOT/scripts/field-configurator.service" >"$TMP_UNIT"
  systemd-analyze verify "$TMP_UNIT" || true
  rm -f "$TMP_UNIT"
else
  echo "systemd-analyze not found; skipping unit validation"
fi

for path in "$REPO_ROOT/tools/betaflight/webapp" "$REPO_ROOT/tools/inav/webapp"; do
  if [[ -f "$path/index.html" ]]; then
    echo "OK: found $path/index.html"
  else
    echo "WARN: missing $path/index.html (manual upstream download required)"
  fi
done

if [[ -x "$REPO_ROOT/tools/am32/am32-tool" || -f "$REPO_ROOT/tools/am32/webapp/index.html" ]]; then
  echo "OK: AM32 offline artifact present"
else
  echo "WARN: AM32 artifact missing (manual install required)"
fi

if command -v dfu-util >/dev/null; then
  echo "OK: $(dfu-util --version | head -n1)"
else
  echo "WARN: dfu-util missing"
fi

for dev in /dev/ttyACM* /dev/ttyUSB*; do
  [[ -e "$dev" ]] || continue
  stat -c "tty device: %n owner=%U group=%G mode=%a" "$dev"
done
