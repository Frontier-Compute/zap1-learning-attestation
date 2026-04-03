#!/bin/bash
# PostToolUse hook dispatcher for Claude Code.
# Reads the hook event JSON from stdin, extracts the file path from tool_input,
# then delegates to attest-learning.sh.
#
# Claude Code PostToolUse hooks receive a JSON blob on stdin with this shape:
#   { "tool_name": "Write", "tool_input": { "file_path": "...", ... }, ... }

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Parse file path from stdin JSON
FILE=$(python3 -c "
import sys, json
d = json.load(sys.stdin)
ti = d.get('tool_input', {})
print(ti.get('file_path', '') or ti.get('path', ''))
" 2>/dev/null || true)

if [[ -z "$FILE" ]]; then
  exit 0
fi

exec bash "$SCRIPT_DIR/attest-learning.sh" "$FILE"
