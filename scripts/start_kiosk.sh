#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export DISPLAY=:0
export XDG_RUNTIME_DIR="/run/user/$(id -u)"

if ! pgrep -x Xorg >/dev/null; then
  startx "$REPO_ROOT/scripts/xsession.sh" -- :0 vt7 -nocursor
else
  "$REPO_ROOT/scripts/xsession.sh"
fi
