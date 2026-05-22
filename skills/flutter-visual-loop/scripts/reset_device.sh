#!/usr/bin/env bash
# reset_device.sh — restore wm size/density saved by setup.sh.
# Always exits 0 (idempotent / best-effort) so it can be safely run from a trap.

set -uo pipefail

JOB_DIR="${CLAUDE_JOB_DIR:-/tmp/vl-job}"
ORIG_FILE="$JOB_DIR/vl_original.env"

if [ ! -f "$ORIG_FILE" ]; then
  echo "no originals recorded; running 'wm size reset' + 'wm density reset' as fallback"
  adb shell wm size reset 2>/dev/null || true
  adb shell wm density reset 2>/dev/null || true
  exit 0
fi

# shellcheck disable=SC1090
source "$ORIG_FILE"

if [ -n "${ORIG_SIZE:-}" ]; then
  adb shell wm size "$ORIG_SIZE" 2>/dev/null || adb shell wm size reset 2>/dev/null || true
fi
if [ -n "${ORIG_DENSITY:-}" ]; then
  adb shell wm density "$ORIG_DENSITY" 2>/dev/null || adb shell wm density reset 2>/dev/null || true
fi
rm -f "$ORIG_FILE"
echo "restored: size=${ORIG_SIZE:-?} density=${ORIG_DENSITY:-?}"
