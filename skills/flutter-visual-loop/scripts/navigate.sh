#!/usr/bin/env bash
# navigate.sh — push a named route on the device.
# Usage: navigate.sh <route> [args_json]
#   navigate.sh /order/detail '{"id":"ORD-001"}'

set -euo pipefail

PORT="${VL_PORT:-9123}"
ROUTE="${1:?route required}"
ARGS="${2:-{\}}"

# Build JSON payload via printf to avoid eating quotes in heredoc
PAYLOAD=$(printf '{"route":%s,"args":%s,"popUntilRoot":true}' \
  "$(printf '%s' "$ROUTE" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))' 2>/dev/null || printf '"%s"' "$ROUTE")" \
  "$ARGS")

curl -sf -X POST "http://127.0.0.1:$PORT/navigate" \
  -H 'content-type: application/json' \
  -d "$PAYLOAD"
echo
