# Architecture

## High-level flow

```
+--------------------+        +---------------------+        +-----------------+
| Claude Code        |  HTTP  | flutter_visual_loop |  app   | Host Flutter    |
| + flutter-visual-  | <----> | (debug HTTP server) | hooks  | App on device   |
| loop skill         |  9123  | (in-process)        |        |                 |
+--------------------+        +---------------------+        +-----------------+
        ^                                                          ^
        |                                                          |
        |          adb forward / adb exec-out screencap            |
        +----------------------------------------------------------+
```

## Components

### SDK (`packages/flutter_visual_loop`)

- **`FlutterVisualLoop`** facade — start/stop, exposes `navigatorKey`.
- **`VisualLoopHttpServer`** — binds `127.0.0.1:9123` (configurable) using
  `dart:io HttpServer`. Routes requests to handlers.
- **Handlers** — one file per endpoint. Pure functions over a
  request/response context. Keeps blast radius small.
- **`RouteRegistry`** — wraps host app's named-route table so the skill can
  discover available routes via `GET /routes`.
- **`MockDataProvider`** — interface the host implements. Defaults to an
  `InMemoryMockDataProvider`. SDK doesn't dictate where mock data goes —
  host app injects it into repositories/services.
- **`VisualLoopRoot`** — optional widget the host wraps around its root to
  make `/screenshot` reliable (provides the `RepaintBoundary`).

### Skill (`skills/flutter-visual-loop`)

- **`SKILL.md`** — top-level instructions. Reads design input, drives loop.
- **`scripts/`** — small bash helpers. Skill stays declarative; scripts
  hide adb/curl plumbing.

## Safety constraints

- SDK refuses to start if `kDebugMode == false` (default config gate).
- Server binds to `127.0.0.1` only — never exposes to LAN.
- `adb wm size` / `wm density` overrides are recorded by the skill and
  reset at task end (or on any failure path).
- All endpoints log a single-line summary to debug console; bodies larger
  than `maxBodyBytes` (default 1 MiB) get a 413.

## What's intentionally NOT in the SDK

- Hot reload triggering — `flutter run` owns that; skill drives it via
  a fifo on the host machine.
- Visual diffing — done by the LLM at skill level.
- Figma client — skill uses existing `figma-context` MCP when input is a URL.
