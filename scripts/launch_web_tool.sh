#!/usr/bin/env bash
set -euo pipefail

TOOL_NAME="${1:?tool name required}"
TOOL_DIR="${2:?tool dir required}"
PORT="${3:?port required}"
CHROMIUM_BIN="${CHROMIUM_BIN:-/usr/bin/chromium-browser}"

if [[ ! -d "$TOOL_DIR" ]]; then
  echo "$TOOL_NAME tool directory not found: $TOOL_DIR"
  exit 1
fi

if [[ ! -f "$TOOL_DIR/index.html" ]]; then
  echo "$TOOL_NAME offline files missing index.html in $TOOL_DIR"
  echo "Add official release web build contents to this directory."
  exit 1
fi

python3 -m http.server "$PORT" --directory "$TOOL_DIR" --bind 127.0.0.1 >/tmp/${TOOL_NAME,,}-server.log 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" >/dev/null 2>&1 || true' EXIT
sleep 1

URL="http://127.0.0.1:${PORT}"
"$CHROMIUM_BIN" \
  --app="$URL" \
  --kiosk \
  --no-first-run \
  --no-default-browser-check \
  --enable-experimental-web-platform-features \
  --enable-features=WebSerial,WebUSB \
  --disable-pinch \
  --overscroll-history-navigation=0
