#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="${REPO_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"

if [[ -x "$REPO_ROOT/tools/am32/am32-tool" ]]; then
  "$REPO_ROOT/tools/am32/am32-tool"
  exit 0
fi

if [[ -f "$REPO_ROOT/tools/am32/webapp/index.html" ]]; then
  "$REPO_ROOT/scripts/launch_web_tool.sh" "AM32" "$REPO_ROOT/tools/am32/webapp" 8812
  exit 0
fi

echo "AM32 tool not installed. Place CLI/GUI binary at tools/am32/am32-tool or web files at tools/am32/webapp/."
exit 1
