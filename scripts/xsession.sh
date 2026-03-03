#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
export REPO_ROOT

openbox-session &
sleep 1
unclutter -idle 1 -root || true
python3 "$REPO_ROOT/launcher/main.py"
