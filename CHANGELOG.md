# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] — 2026-05-21

### Added — SDK (`packages/flutter_visual_loop`)
- `FlutterVisualLoop.start()` / `stop()` / `bind()` facade
- HTTP server (default `127.0.0.1:9123`) with endpoints:
  - `GET /health`
  - `GET /routes`
  - `POST /navigate` — `{route, args, popUntilRoot}`
  - `POST /reset` — `{clearMock}`
  - `POST /mock` — `{action: enable|set|get|reset|list, ...}`
  - `GET /screenshot` — Flutter render tree as PNG
- `MockDataProvider` interface + `InMemoryMockDataProvider` impl
- `RouteRegistry` for discoverable named routes
- `VisualLoopRoot` widget wrapper for reliable in-app screenshots
- `VisualLoopConfig` with port / host / screenshot-mode / body-limit knobs
- Production builds are no-op (gated by `kDebugMode`)
- Unit tests: `route_registry_test`, `mock_provider_test`

### Added — Skill (`skills/flutter-visual-loop`)
- `SKILL.md` with checklist, lookup tables, failure modes, reporting
- Scripts:
  - `env_check.sh` — adb/curl/device/port preflight
  - `setup.sh` — record + override `wm size`/`wm density`
  - `navigate.sh` — `POST /navigate`
  - `capture.sh` — `adb exec-out screencap` with PNG magic check
  - `hot_reload.sh` — write `r` to flutter-run fifo
  - `reset_device.sh` — restore originals (always exits 0)
  - `mock_set.sh` — `POST /mock action=set`

### Added — Example
- `example/` Flutter app with 4 pages, demo mock provider
- Placeholder design notes in `example/design/`

### Added — Docs
- `README.md` — entry point
- `docs/architecture.md` — high-level component diagram
- `docs/getting-started.md` — 5-min walkthrough
- `docs/api-reference.md` — full HTTP contract
- `docs/integration-guide.md` — mock/router/auth patterns
- `docs/troubleshooting.md` — failure modes by symptom
- `docs/e2e-checklist.md` — manual smoke test
- `docs/superpowers/plans/2026-05-21-flutter-visual-loop.md` — full plan
- `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`
- `.github/workflows/ci.yml` — flutter test on push/PR
- `.github/ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE.md`

### Known limitations
- Android-only (no iOS Simulator port forward)
- No web platform support yet (`dart:io HttpServer` not available)
- `wm size`/`wm density` overrides silently rejected on some
  vendor ROMs (MIUI / HarmonyOS) — fall back to `--no-lock`
