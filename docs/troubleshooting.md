# Troubleshooting

Real-world failure modes and how to recover. Symptoms grouped by where
they surface.

## `env_check.sh` fails

### `ERR: adb not installed`

Install Android platform-tools:

```bash
# macOS
brew install --cask android-platform-tools

# Ubuntu
sudo apt install adb

# Then verify
adb --version
```

### `ERR: no adb device connected`

```bash
adb devices
# If empty: enable USB debugging in Developer Options on phone,
# accept the RSA fingerprint prompt on first connect.
```

For emulators, start one first:

```bash
emulator -list-avds
emulator -avd <name> -no-snapshot-load &
```

### `ERR: SDK not reachable on 127.0.0.1:9123`

The Flutter app is not running, or it's running but didn't call
`FlutterVisualLoop.start()`, or port forward is missing.

Checklist:

```bash
# 1. Is flutter run alive?
jobs | grep flutter
# Or look for the process
pgrep -f 'flutter run'

# 2. Is port forward set up?
adb forward --list | grep 9123
# If not:
adb forward tcp:9123 tcp:9123

# 3. Did the SDK actually bind?
# In flutter run output you should see:
#   [flutter_visual_loop] listening on http://127.0.0.1:9123
# If missing, the app never called FlutterVisualLoop.start() — check main.dart

# 4. Is something else holding 9123 on host?
lsof -i :9123
# If yes, kill that or change port via VisualLoopConfig(port: 9124).
```

## `/navigate` issues

### Returns `503 navigator not ready`

The app is still booting. Either:

- Wait ~500ms and retry once.
- Defer `FlutterVisualLoop.start(autoStart: false)` and call
  `FlutterVisualLoop.bind()` after first frame.

### Returns `500 ...` with route name in error

The route name didn't match anything in `onGenerateRoute` (or static
`routes:` map). Check:

```bash
curl http://localhost:9123/routes
# What's registered. If your route isn't there, register it:
FlutterVisualLoop.routes.register('/your/route');
```

Note that `/routes` only shows **registered** routes — `/navigate` will
still try to push **any** name through `onGenerateRoute`, so the error
likely means your router really doesn't handle that path.

### Page changes but UI doesn't update

Probably your page reads from state that hasn't been refreshed. Quick
fixes:

- Add `popUntilRoot: true` (it's the default) to force a fresh mount.
- Reset mock data between navigations: `POST /reset {"clearMock":true}`.

## Screenshot issues

### `/screenshot` returns 500

The host didn't wrap its root with `VisualLoopRoot`. Either:

- Fix: `runApp(VisualLoopRoot(child: MyApp()))`.
- Workaround: use `adb exec-out screencap -p > cur.png` in your loop.

### Screenshot is all-black

Device screen turned off. Wake it:

```bash
adb shell input keyevent 26      # power button
adb shell input keyevent 82      # menu, dismiss lock screen prompt
```

If lock screen requires PIN, set up the test device with no lock for
the duration of the loop.

### Screenshot looks zoomed/wrong scale

You probably forgot to `adb forward` or the `wm size`/`wm density`
overrides are mismatched. Check:

```bash
adb shell wm size       # current logical
adb shell wm density    # current dpi
```

If you set `wm size 1080x2400` but `wm density` is still your phone's
default (say 422dpi for Pixel 7), the result is a different effective
DP. The skill records originals and restores on `reset_device.sh`, but
if you killed the session uncleanly, run it manually:

```bash
bash skills/flutter-visual-loop/scripts/reset_device.sh
# or
adb shell wm size reset
adb shell wm density reset
```

## Mock issues

### `/mock` returns `501 no MockDataProvider configured`

You called `FlutterVisualLoop.start()` without `mockProvider:`. Add one:

```dart
final mock = InMemoryMockDataProvider();
await FlutterVisualLoop.start(mockProvider: mock);
```

### Mock value updates but UI doesn't reflect

Your repository/service is caching the result. Common fixes:

- Disable caching in debug:
  ```dart
  if (kDebugMode) cache.clear();
  ```
- Or `POST /reset` after `POST /mock`, then re-navigate — the new
  mount reads fresh.

## Hot reload issues

### `hot_reload.sh` says `nobody is reading FIFO`

Either `flutter run` exited, or you started it without the fifo. Re-start:

```bash
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d <device> < /tmp/flutter-vl-stdin &
```

### Code changes not picked up

- Hot reload doesn't pick up changes to `main()` or global initializers.
  Use hot restart instead: `echo R > /tmp/flutter-vl-stdin`.
- Changes to const constructors only refresh after restart.

## Device left in weird state after a run

```bash
adb shell wm size reset
adb shell wm density reset

# If overscan was set:
adb shell wm overscan reset

# If screen left off:
adb shell input keyevent 26

# If the app is stuck in a weird route:
curl -X POST http://localhost:9123/reset -d '{"clearMock":true}'
# or just relaunch:
adb shell am force-stop com.example.visualloop
```

## "It works on Android but not iOS"

The skill is Android-only because:

- iOS Simulator screenshots: `xcrun simctl io booted screenshot` (works)
- iOS deep-link / port forward: doesn't exist (no analog to `adb forward`)

For iOS Simulator support, you'd need to:

- Bind SDK to a UNIX socket instead of TCP, OR
- Use `simctl spawn` + a port that's accessible from host (not a
  separate network namespace)

Patches welcome.

## Specific to Chinese OEM ROMs (MIUI, HarmonyOS, ColorOS, …)

These ROMs sometimes silently reject `wm size`/`wm density`. After
running `setup.sh`, verify:

```bash
adb shell wm size
# Expect: "Physical size: ..." AND "Override size: 1080x2400"
# If no Override line, the change was rejected.
```

Workarounds:

- Run with `--no-lock` (skip resolution change) and live with whatever
  the device default is.
- Use a different device for design-conformance work.
- Try with ADB owner / device owner permissions (advanced; voids
  warranty on some devices).
