# flutter_visual_loop

Debug-only HTTP control plane for Flutter apps. Powers the
[`flutter-visual-loop`](../../skills/flutter-visual-loop/SKILL.md) Claude
Code skill — but any client (curl, Postman, your own script) can talk to it.

> **In release builds, this package is a no-op.** `start()` returns without
> binding any socket. Safe to leave in production code.

## Install

```yaml
dependencies:
  flutter_visual_loop:
    git:
      url: https://github.com/MySwallow/flutter-visual-loop
      path: packages/flutter_visual_loop
```

## Integrate (3 lines)

```dart
import 'package:flutter_visual_loop/flutter_visual_loop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterVisualLoop.start();                  // 1. start control server (debug only)
  runApp(VisualLoopRoot(child: const MyApp()));     // 2. enables /screenshot
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FlutterVisualLoop.navigatorKey, // 3. hand over navigator
      onGenerateRoute: appRouter,
    );
  }
}

// Somewhere during startup, register discoverable routes:
FlutterVisualLoop.routes.register('/home');
FlutterVisualLoop.routes.register('/order/detail');
```

Or pass them up-front:

```dart
await FlutterVisualLoop.start(
  testRoutes: const ['/home', '/login', '/order/detail'],
);
```

## With mock data

```dart
final mock = InMemoryMockDataProvider();
mock.set('user', {'name': 'Alice'});

await FlutterVisualLoop.start(mockProvider: mock);

// In your repository:
class UserRepo {
  UserRepo(this._mock);
  final MockDataProvider _mock;

  Future<User> fetch() async {
    if (_mock.enabled) {
      return User.fromJson(_mock.get('user') as Map<String, dynamic>);
    }
    return realApiCall();
  }
}
```

## HTTP API

| Method | Path        | Body                                                          | Response                          |
|--------|-------------|---------------------------------------------------------------|-----------------------------------|
| GET    | /health     | —                                                             | `{"ok":true,"version":"..."}`     |
| GET    | /routes     | —                                                             | `{"ok":true,"routes":[...]}`      |
| POST   | /navigate   | `{"route":"/x","args":{...},"popUntilRoot":true}`             | `{"ok":true,"route":"/x"}`        |
| POST   | /reset      | `{"clearMock":true}`                                          | `{"ok":true,"clearedMock":true}`  |
| POST   | /mock       | `{"action":"set"\|"get"\|"reset"\|"enable"\|"list","key":"k","value":...,"enabled":true}` | depends on action |
| GET    | /screenshot | —                                                             | `image/png` bytes (if mode=flutter) |

All error responses follow `{"ok":false,"error":"..."}`.

## Connect from your laptop (Android device)

```bash
adb forward tcp:9123 tcp:9123
curl http://localhost:9123/health
curl -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail","args":{"id":"ORD-001"}}'
```

## Configuration

```dart
await FlutterVisualLoop.start(
  config: const VisualLoopConfig(
    host: '127.0.0.1',                    // never use 0.0.0.0 in real apps
    port: 9123,
    enableInDebugOnly: true,              // false to also run in profile
    autoStart: true,
    screenshotMode: ScreenshotMode.flutter, // or .external (defer to adb)
    maxBodyBytes: 1024 * 1024,
  ),
);
```
