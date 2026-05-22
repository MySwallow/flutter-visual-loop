#!/usr/bin/env bash
# hot_reload.sh — send 'r' to a running `flutter run` process via its stdin fifo.
# Requires the user to have started flutter run with stdin piped from a fifo:
#   mkfifo /tmp/flutter-vl-stdin
#   flutter run -d <id> < /tmp/flutter-vl-stdin &
# Override fifo path with FIFO env var if you use a different one.

set -euo pipefail

FIFO="${FIFO:-/tmp/flutter-vl-stdin}"

if [ ! -p "$FIFO" ]; then
  echo "ERR: $FIFO is not a fifo. Create with: mkfifo $FIFO" >&2
  echo "Then start flutter with: flutter run -d <device> < $FIFO &" >&2
  exit 30
fi

# Non-blocking write — if no reader, give up after 2s
( echo "r" > "$FIFO" ) &
WRITER_PID=$!
sleep 2
if kill -0 "$WRITER_PID" 2>/dev/null; then
  kill "$WRITER_PID" 2>/dev/null || true
  echo "ERR: nobody is reading $FIFO (is flutter run still attached?)" >&2
  exit 31
fi

echo "sent: hot reload"
sleep 1  # give Flutter a beat to apply
