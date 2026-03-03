#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
"$REPO_ROOT/scripts/launch_web_tool.sh" "Betaflight" "$REPO_ROOT/tools/betaflight/webapp" 8810
