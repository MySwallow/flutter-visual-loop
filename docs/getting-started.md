# Getting Started (5 minutes)

This guide walks you from zero to a working visual-loop iteration on a
demo app. Once you've done it once, integrating the SDK into your own
app is the same 3 steps.

## Prerequisites

- Flutter SDK 3.10+ — `flutter doctor` should be green
- Android device with USB debugging on, OR Android emulator running
- `adb` on PATH (comes with Android platform-tools)
- `curl`

## Step 1 — Clone and bootstrap the demo

```bash
git clone https://github.com/MySwallow/flutter-visual-loop.git
cd flutter-visual-loop/example
flutter create . --platforms=android,ios --org com.example.visualloop
flutter pub get
```

`flutter create .` only adds `android/` and `ios/` scaffolding; existing
files are left alone.

## Step 2 — Start the app with a hot-reload fifo

The fifo is what lets the skill send `r` to trigger hot reload between
loop iterations.

```bash
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d $(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}') \
  < /tmp/flutter-vl-stdin &
```

Wait until you see:

```
[flutter_visual_loop] listening on http://127.0.0.1:9123
```

## Step 3 — Forward the port

```bash
adb forward tcp:9123 tcp:9123
curl http://localhost:9123/health
# → {"ok":true,"version":"0.1.0","service":"flutter_visual_loop"}
```

That's the entire setup. The skill drives everything after this.

## Step 4 — Run the skill from Claude Code

In a Claude Code session opened in the repo root:

```
/flutter-visual-loop example/design/order_detail.md /order/detail
```

The skill will:

1. Check device + SDK reachability.
2. Ask you to confirm the design spec (PNG mode without a `.md` spec
   file).
3. Loop up to 5 rounds: navigate → screenshot → diff → edit → hot reload.
4. Reset device `wm size`/`wm density` overrides.
5. Write a report to `$CLAUDE_JOB_DIR/report.md`.

## Step 5 — Adapt to your own app

Copy the integration pattern from `example/lib/main.dart`:

```dart
import 'package:flutter_visual_loop/flutter_visual_loop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterVisualLoop.start(
    testRoutes: const ['/home', '/order/detail', '/login'],
  );
  runApp(VisualLoopRoot(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FlutterVisualLoop.navigatorKey,
      onGenerateRoute: yourRouter,
    );
  }
}
```

That's it. Next, read:

- [`integration-guide.md`](integration-guide.md) for mock-data wiring
  and real-API patterns.
- [`api-reference.md`](api-reference.md) for the full HTTP contract.
- [`troubleshooting.md`](troubleshooting.md) when things go wrong.
