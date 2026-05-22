# Integration Guide

Detailed patterns for integrating `flutter_visual_loop` into a real
Flutter app — including mock data layering, GoRouter, BLoC/Riverpod,
and real-API toggling.

## 1. Add the dependency

Until the package is on pub.dev, depend via git:

```yaml
# your_app/pubspec.yaml
dependencies:
  flutter_visual_loop:
    git:
      url: https://github.com/MySwallow/flutter-visual-loop
      path: packages/flutter_visual_loop
```

Or as a local `path:` if you've vendored the package:

```yaml
dependencies:
  flutter_visual_loop:
    path: ../flutter-visual-loop/packages/flutter_visual_loop
```

## 2. Wire up `main()`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_visual_loop/flutter_visual_loop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // (a) start the SDK — production builds skip this automatically
  await FlutterVisualLoop.start(
    testRoutes: const ['/home', '/login', '/order/detail'],
  );

  // (b) wrap your root with VisualLoopRoot so /screenshot can capture
  runApp(VisualLoopRoot(child: const MyApp()));
}
```

If you can't use `VisualLoopRoot` (e.g. you have a custom binding setup),
ignore the `/screenshot` endpoint and let the skill use `adb screencap`
exclusively — it's the better choice on Android anyway because it
captures the full device frame.

## 3. Hand the navigator over

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FlutterVisualLoop.navigatorKey,
      onGenerateRoute: appRouter,
    );
  }
}
```

> Why a shared `navigatorKey`? `Navigator.of(context)` needs a context.
> The SDK's HTTP handler doesn't have one. A `GlobalKey<NavigatorState>`
> sidesteps that.

## 4. Register routes (optional but recommended)

```dart
// Either up-front in start():
await FlutterVisualLoop.start(
  testRoutes: const ['/home', '/order/detail', '/login'],
);

// Or any time after:
FlutterVisualLoop.routes.register('/cart');
```

Registered routes appear in `GET /routes` so the skill can discover
them. Unregistered routes still work via `/navigate` — registration is
about discoverability, not gating.

## 5. Mock-data layering

The SDK doesn't dictate where mock data lives. Pattern:

```dart
// services/user_repo.dart
class UserRepo {
  UserRepo({MockDataProvider? mock}) : _mock = mock;
  final MockDataProvider? _mock;

  Future<User> fetch(String id) async {
    if (_mock?.enabled == true) {
      final raw = _mock!.get('user.$id') as Map<String, Object?>?;
      if (raw != null) return User.fromJson(raw);
    }
    return _httpFetch(id);
  }

  Future<User> _httpFetch(String id) async {
    // real network call
  }
}
```

Plug it into the SDK:

```dart
final mock = InMemoryMockDataProvider()
  ..set('user.U1', {'id': 'U1', 'name': 'Alice'});

await FlutterVisualLoop.start(mockProvider: mock);

final userRepo = UserRepo(mock: mock);
// inject userRepo via your DI (provider / get_it / Riverpod) ...
```

The skill flips mock state via `POST /mock`:

```bash
# Disable mock to hit real API
curl -X POST localhost:9123/mock -d '{"action":"enable","enabled":false}'

# Inject a different fixture
curl -X POST localhost:9123/mock \
  -d '{"action":"set","key":"user.U1","value":{"id":"U1","name":"Bob"}}'
```

## 6. GoRouter integration

`navigatorKey` works with GoRouter via `GoRouter.navigatorKey`:

```dart
final router = GoRouter(
  navigatorKey: FlutterVisualLoop.navigatorKey,
  routes: [
    GoRoute(path: '/', builder: (_, __) => const HomePage()),
    GoRoute(path: '/order/:id', builder: (_, st) => OrderPage(id: st.pathParameters['id']!)),
  ],
);

runApp(MaterialApp.router(routerConfig: router));
```

For named GoRouter routes, you have two options:

1. Use the URL-style path as the route name:
   `POST /navigate {"route":"/order/123"}`. The SDK calls `pushNamed`,
   GoRouter parses the URL.

2. Bridge in your own router handler — easiest is to wrap `pushNamed`
   in your router and dispatch to `GoRouter.go(...)` based on a prefix.

## 7. Real-API mode + auth tokens

When the skill flips mock off and you want real API calls in a debug
build, you usually need a valid auth token. Two patterns:

**Pattern A — bake test token into debug:**
```dart
const debugAuthToken = String.fromEnvironment('TEST_AUTH_TOKEN');
flutter run --dart-define=TEST_AUTH_TOKEN=eyJ...
```

**Pattern B — inject via /mock:**
```bash
curl -X POST localhost:9123/mock \
  -d '{"action":"set","key":"auth.token","value":"eyJ..."}'
```

Your auth interceptor reads from `mock.get('auth.token')` first when
`mock.enabled == false` but the key exists. Trade-off: a tiny bit of
mock-data coupling buys you keep-real-API-loops-going.

## 8. Disabling the SDK in profile/release

Default `enableInDebugOnly: true` already does this. If you want it on
in profile builds (for QA):

```dart
await FlutterVisualLoop.start(
  config: const VisualLoopConfig(enableInDebugOnly: false),
);
```

Be careful — release+enabled means the HTTP port is open in production.

## 9. CI / golden-test coexistence

This SDK is for interactive loops, not unit/golden tests. If you have
both:

- `flutter test` runs in isolated process; SDK's `dart:io HttpServer`
  is fine but pointless there.
- Wrap `start()` in `if (!Platform.environment.containsKey('FLUTTER_TEST'))`
  to skip the bind in test runs.

```dart
import 'dart:io';

if (!Platform.environment.containsKey('FLUTTER_TEST')) {
  await FlutterVisualLoop.start();
}
```

## 10. Multi-flavor apps

Different flavors (dev/staging/prod) need different setup:

```dart
Future<void> mainDev() async {
  await FlutterVisualLoop.start(
    config: const VisualLoopConfig(port: 9123),
    mockProvider: DemoMockProvider(),
  );
  runApp(MyApp());
}

Future<void> mainProd() async {
  // SDK is no-op in release; you can still call start() — it returns
  // immediately. Or skip entirely:
  runApp(MyApp());
}
```
