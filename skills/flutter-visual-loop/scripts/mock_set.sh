#!/usr/bin/env bash
# mock_set.sh — inject a mock value via /mock action=set.
# Usage: mock_set.sh <key> <json_value>
#   mock_set.sh order.amount 42
#   mock_set.sh user '{"name":"Alice","vip":true}'

set -euo pipefail

PORT="${VL_PORT:-9123}"
KEY="${1:?key required}"
VAL="${2:?value (JSON literal) required}"

PAYLOAD=$(printf '{"action":"set","key":"%s","value":%s}' "$KEY" "$VAL")
curl -sf -X POST "http://127.0.0.1:$PORT/mock" \
  -H 'content-type: application/json' \
  -d "$PAYLOAD"
echo
