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

URL="http://127.0.0.1:${PORT}"
ready=false
for _ in {1..30}; do
  if ss -ltn 2>/dev/null | awk '{print $4}' | grep -q ":${PORT}$" || curl -fsS "$URL" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 0.1
done

if [[ "$ready" != true ]]; then
  echo "$TOOL_NAME server failed to start on $URL"
  tail -n 50 "/tmp/${TOOL_NAME,,}-server.log" || true
  exit 1
fi

nohup "$CHROMIUM_BIN" \
  --app="$URL" \
  --kiosk \
  --user-data-dir="/tmp/${TOOL_NAME,,}-chromium-profile" \
  --no-first-run \
  --no-default-browser-check \
  --enable-experimental-web-platform-features \
  --enable-features=WebSerial,WebUSB \
  --disable-pinch \
  --overscroll-history-navigation=0 \
  >/tmp/${TOOL_NAME,,}-chromium.log 2>&1 &

wait "$SERVER_PID"
