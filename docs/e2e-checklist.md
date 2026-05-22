# End-to-end verification checklist

This is the manual smoke test that proves SDK + Skill work together.
The plan author cannot run it on the dev machine because that machine
has no Flutter toolchain (no `flutter`, no `dart`, no `adb`). Run these
steps once on your laptop after cloning.

## Prerequisites

- macOS / Linux with **Flutter SDK** installed (`flutter doctor` passes)
- **Android device** with USB debugging on, OR Android emulator running
- `adb devices` shows the device as `device` (not `unauthorized`)

## Step 1 — Generate platform scaffolding for example app

```bash
cd flutter-visual-loop/example
flutter create . --platforms=android,ios --org com.example.visualloop
flutter pub get
```

`flutter create .` skips files that already exist, so it only adds
`android/`, `ios/`, and minor bits.

## Step 2 — Run the SDK unit tests (no device needed)

```bash
cd flutter-visual-loop/packages/flutter_visual_loop
flutter pub get
flutter test
```

Expected:

```
00:01 +X: All tests passed!
```

## Step 3 — Start the example app with a hot-reload fifo

```bash
cd flutter-visual-loop/example
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d $(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}') \
  < /tmp/flutter-vl-stdin &
```

Wait for:

```
[flutter_visual_loop] registered route: /
[flutter_visual_loop] registered route: /login
[flutter_visual_loop] registered route: /product/detail
[flutter_visual_loop] registered route: /order/detail
[flutter_visual_loop] listening on http://127.0.0.1:9123
```

## Step 4 — Forward port + smoke-test HTTP API

```bash
adb forward tcp:9123 tcp:9123

curl -sf http://localhost:9123/health
# → {"ok":true,"version":"0.1.0","service":"flutter_visual_loop"}

curl -sf http://localhost:9123/routes
# → {"ok":true,"routes":["/","/login","/product/detail","/order/detail"]}

curl -sf -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail","args":{"id":"ORD-001"}}'
# → {"ok":true,"route":"/order/detail"}
# Device should show the order page.

# Capture screen
adb exec-out screencap -p > /tmp/order.png
file /tmp/order.png
# → /tmp/order.png: PNG image data, ...

# Toggle mock
curl -sf -X POST http://localhost:9123/mock \
  -H 'content-type: application/json' \
  -d '{"action":"set","key":"order","value":{"id":"X","amount":1.0,"status":"hi","items":[]}}'

# Re-navigate to see new data
curl -sf -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail"}'

# Reset
curl -sf -X POST http://localhost:9123/reset \
  -H 'content-type: application/json' \
  -d '{"clearMock":true}'
```

## Step 5 — Run the skill against the demo design

In your Claude Code session, with this repo as cwd:

```
/flutter-visual-loop example/design/order_detail.md /order/detail
```

(Or substitute a real PNG.) The skill should:

- Pass `env_check.sh`.
- Prompt you to confirm spec values (when input is `.md`/PNG without
  embedded spec).
- Run up to 5 rounds. Screenshots saved to `$CLAUDE_JOB_DIR/round-N.png`.
- End with `reset_device.sh` and a `report.md` in `$CLAUDE_JOB_DIR`.

## Step 6 — Confirm device cleanup

```bash
adb shell wm size
# Expected: just "Physical size: ..." (no "Override size:" line)

adb shell wm density
# Expected: just "Physical density: ..." (no "Override density:" line)
```

If overrides are still set, run:

```bash
bash skills/flutter-visual-loop/scripts/reset_device.sh
```

## What proves it works

- `/health` returns 200 with the right version.
- `/navigate` actually navigates on screen.
- Screenshot file is non-empty PNG and visually matches the device.
- `/mock` set + navigate causes the visible data to change.
- `wm size` / `wm density` restored after run.
- SDK unit tests pass.

## Things to check that proved tricky in the past

- **PNG screenshot magic bytes**: `head -c 4 file.png | xxd -p` should be
  `89504e47`. If not, the device might be locked or the shell ate the
  binary stream.
- **`wm size` rejected**: Some vendor ROMs (MIUI, HarmonyOS) reject
  `wm size` overrides silently. After `setup.sh 1080 2400 480`, re-run
  `adb shell wm size` to confirm "Override size: 1080x2400" shows up.
- **Two-device confusion**: With both an emulator and a phone connected,
  `adb` may target the wrong one. Set `ANDROID_SERIAL=<id>` env var.
- **Port already in use**: If something else holds 9123 on your laptop,
  start the SDK with `VisualLoopConfig(port: 9124)` and re-do
  `adb forward tcp:9124 tcp:9124`.
