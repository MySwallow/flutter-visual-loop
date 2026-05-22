# HTTP API Reference

`flutter_visual_loop` exposes a small JSON-over-HTTP API on
`127.0.0.1:9123` (configurable). The Claude Code skill uses this API,
but anything that speaks HTTP can.

## Conventions

- **Bind address**: `127.0.0.1` by default. Never bind `0.0.0.0` in
  shared networks — mock controls are not authenticated.
- **Content-Type**: requests with bodies must use
  `application/json`. JSON parse failures are silently treated as `{}`.
- **Response envelope**:
  - Success: `{"ok": true, ...}` (extra fields per endpoint)
  - Failure: `{"ok": false, "error": "<reason>"}` with HTTP 4xx/5xx
- **Body limit**: 1 MiB by default, configurable via
  `VisualLoopConfig.maxBodyBytes`. Larger bodies get HTTP 413.

## GET /health

Liveness + version check.

**Response 200**
```json
{ "ok": true, "version": "0.1.0", "service": "flutter_visual_loop" }
```

## GET /routes

List routes the host has registered as visual-loop-discoverable.

**Response 200**
```json
{ "ok": true, "routes": ["/", "/login", "/order/detail"] }
```

> Routes appear here only if the host called
> `FlutterVisualLoop.routes.register('/x')` or passed them via the
> `testRoutes:` argument to `start()`.

## POST /navigate

Push a named route onto the navigator.

**Request body**
```json
{
  "route": "/order/detail",
  "args": { "id": "ORD-001" },
  "popUntilRoot": true
}
```

| Field          | Type     | Default | Notes                                       |
|----------------|----------|---------|---------------------------------------------|
| `route`        | string   | —       | Required. Passed to `Navigator.pushNamed`.  |
| `args`         | any JSON | `null`  | Sent as `arguments` to the route.           |
| `popUntilRoot` | bool     | `true`  | Pop to root before push. Stops state stack drift between loop iterations. |

**Response 200**
```json
{ "ok": true, "route": "/order/detail" }
```

**Errors**
- `400` — missing `route`
- `503` — `navigatorKey.currentState` is null (app not mounted yet)
- `500` — push threw (route not in `onGenerateRoute`, args cast failed, etc.)

## POST /reset

Pop the navigator to root. Optionally clear mock state.

**Request body**
```json
{ "clearMock": true }
```

| Field        | Type | Default | Notes                                       |
|--------------|------|---------|---------------------------------------------|
| `clearMock`  | bool | `false` | If true, calls `mockProvider.reset()`.      |

**Response 200**
```json
{ "ok": true, "clearedMock": true }
```

## POST /mock

Control mock data. Five actions:

### action: enable
```json
{ "action": "enable", "enabled": true }
```
Toggle mock mode globally. Response: `{ "ok": true, "enabled": true }`.

### action: set
```json
{ "action": "set", "key": "user", "value": { "name": "Alice" } }
```
Write a key. Response: `{ "ok": true, "key": "user" }`.

### action: get
```json
{ "action": "get", "key": "user" }
```
Read a key. Response: `{ "ok": true, "key": "user", "value": ... }`.

### action: reset
```json
{ "action": "reset" }
```
Clear all keys and restore initial enabled flag. Response: `{ "ok": true, "reset": true }`.

### action: list
```json
{ "action": "list" }
```
Inspect current state. Response:
```json
{ "ok": true, "enabled": true, "keys": ["user", "order"] }
```

**Errors**
- `501` — no `MockDataProvider` configured on `FlutterVisualLoop.start()`
- `400` — missing/wrong-typed `key`/`enabled`/`action`

## GET /screenshot

Capture the Flutter render tree as PNG. Excludes OS chrome (status bar,
nav bar). For full device frame, use `adb exec-out screencap` instead.

**Response 200**
```
Content-Type: image/png
<binary PNG bytes>
```

**Errors**
- `500` — capture failed; host probably didn't wrap with `VisualLoopRoot`
- `501` — `screenshotMode = ScreenshotMode.external` (use adb instead)

## Lifecycle endpoints (not exposed via HTTP)

These are Dart-side only:

```dart
FlutterVisualLoop.start({...});   // bind server
FlutterVisualLoop.bind();         // bind if autoStart was false
FlutterVisualLoop.stop();         // close server
FlutterVisualLoop.isRunning;      // bool
```

## Curl recipes

```bash
# 1. Sanity
curl -sf http://localhost:9123/health

# 2. List routes
curl -sf http://localhost:9123/routes

# 3. Navigate with args
curl -sf -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail","args":{"id":"ORD-001"}}'

# 4. Set mock then re-navigate
curl -sf -X POST http://localhost:9123/mock \
  -H 'content-type: application/json' \
  -d '{"action":"set","key":"order","value":{"id":"X","amount":1.0}}'

curl -sf -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail"}'

# 5. Reset
curl -sf -X POST http://localhost:9123/reset \
  -H 'content-type: application/json' \
  -d '{"clearMock":true}'

# 6. Screenshot via SDK (Flutter render tree only)
curl -sf http://localhost:9123/screenshot -o cur.png

# 7. Screenshot via adb (full device, recommended for visual-loop)
adb exec-out screencap -p > cur.png
```
