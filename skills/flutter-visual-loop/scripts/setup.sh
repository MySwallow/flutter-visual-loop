#!/usr/bin/env bash
# setup.sh — optionally lock device resolution & density to match design.
# Usage:
#   setup.sh <width> <height> <density>   (e.g. 1080 2400 480)
#   setup.sh skip                         (no resolution change)
# Records originals to $CLAUDE_JOB_DIR/vl_original.env for reset_device.sh.

set -euo pipefail

JOB_DIR="${CLAUDE_JOB_DIR:-/tmp/vl-job}"
mkdir -p "$JOB_DIR"
ORIG_FILE="$JOB_DIR/vl_original.env"

if [ "${1:-}" = "skip" ]; then
  echo "resolution: not changed"
  exit 0
fi

W="${1:?width required}"
H="${2:?height required}"
D="${3:?density required}"

# Record originals once
if [ ! -f "$ORIG_FILE" ]; then
  ORIG_SIZE=$(adb shell wm size | tr -d '\r' | awk -F': ' '/Physical size|Override size/{print $2; exit}')
  ORIG_DENSITY=$(adb shell wm density | tr -d '\r' | awk -F': ' '/Physical density|Override density/{print $2; exit}')
  {
    echo "ORIG_SIZE=$ORIG_SIZE"
    echo "ORIG_DENSITY=$ORIG_DENSITY"
  } > "$ORIG_FILE"
  echo "recorded originals: size=$ORIG_SIZE density=$ORIG_DENSITY -> $ORIG_FILE"
fi

adb shell wm size "${W}x${H}"
adb shell wm density "$D"
echo "resolution: ${W}x${H} @ ${D}dpi"
