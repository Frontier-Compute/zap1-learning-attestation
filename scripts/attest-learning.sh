#!/bin/bash
# Watches for new entries in .learnings/ and attests them to ZAP1.
# Requires: ZAP1_API_KEY env var, curl, sha256sum
#
# Usage (direct):
#   ZAP1_API_KEY=... ZAP1_AGENT_ID=my-agent ./attest-learning.sh path/to/.learnings/entry.md
#
# Usage (PostToolUse hook via Claude Code settings.json):
#   Pass the file path from the hook context. The script checks that
#   the path contains ".learnings/" before doing anything.

set -euo pipefail

ZAP1_URL="${ZAP1_API_URL:-https://pay.frontiercompute.io}"
AGENT_ID="${ZAP1_AGENT_ID:-self-improving-agent}"
FILE="${1:-}"

if [[ -z "$FILE" ]]; then
  echo "[ZAP1] No file path provided. Pass the .learnings/ file as argument 1." >&2
  exit 1
fi

# Only act on .learnings/ files
if [[ "$FILE" != *".learnings/"* ]]; then
  exit 0
fi

if [[ ! -f "$FILE" ]]; then
  echo "[ZAP1] File not found: $FILE" >&2
  exit 1
fi

if [[ -z "${ZAP1_API_KEY:-}" ]]; then
  echo "[ZAP1] ZAP1_API_KEY is not set." >&2
  exit 1
fi

# Hash the file content
CONTENT_HASH=$(sha256sum "$FILE" | awk '{print $1}')
BASENAME=$(basename "$FILE")

PAYLOAD=$(cat <<JSON
{
  "event_type": "AGENT_ACTION",
  "agent_id": "${AGENT_ID}",
  "action_type": "LEARNING",
  "input_hash": "${CONTENT_HASH}",
  "output_hash": "${CONTENT_HASH}"
}
JSON
)

RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "${ZAP1_URL}/attest" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${ZAP1_API_KEY}" \
  -d "$PAYLOAD")

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | head -n-1)

if [[ "$HTTP_CODE" != "201" ]]; then
  echo "[ZAP1] Attestation failed (HTTP $HTTP_CODE): $BODY" >&2
  exit 1
fi

LEAF_HASH=$(echo "$BODY" | grep -o '"leaf_hash":"[^"]*"' | cut -d'"' -f4)

if [[ -z "$LEAF_HASH" ]]; then
  # Try alternate field name used by some API versions
  LEAF_HASH=$(echo "$BODY" | grep -o '"hash":"[^"]*"' | cut -d'"' -f4)
fi

if [[ -z "$LEAF_HASH" ]]; then
  echo "[ZAP1] Attested but could not parse leaf_hash from response." >&2
  echo "[ZAP1] Raw response: $BODY" >&2
  exit 1
fi

echo "[ZAP1] Attested: $BASENAME"
echo "[ZAP1] content_hash: $CONTENT_HASH"
echo "[ZAP1] leaf_hash: $LEAF_HASH"
echo "[ZAP1] Verify: ${ZAP1_URL}/verify/${LEAF_HASH}"
