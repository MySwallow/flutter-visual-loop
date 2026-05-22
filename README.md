# Flutter Visual Loop

Automated Figma / PNG → Flutter UI restoration loop. Drives a real device or
emulator with `adb`, captures screenshots, and iterates code against design
references using Claude Code.

This repo contains three things:

| Path                              | What it is                                                |
|-----------------------------------|-----------------------------------------------------------|
| `packages/flutter_visual_loop/`   | Dart package: debug-only HTTP control server for any app |
| `skills/flutter-visual-loop/`     | Claude Code skill that runs the loop                      |
| `example/`                        | Demo Flutter app showing SDK integration                  |

## Quick start

1. Add `flutter_visual_loop` to your Flutter app's `pubspec.yaml`
   (`path` or `git` reference until published to pub.dev).
2. In `main()`, call `FlutterVisualLoop.start()` (only runs in debug).
3. Run your app on a device: `flutter run -d <id>`.
4. From Claude Code, invoke:

   ```
   /flutter-visual-loop example/design/order_detail.png /order/detail
   ```

See [`packages/flutter_visual_loop/README.md`](packages/flutter_visual_loop/README.md)
and [`skills/flutter-visual-loop/SKILL.md`](skills/flutter-visual-loop/SKILL.md)
for details.

## Documentation

| Doc                                                           | What's in it                                          |
|---------------------------------------------------------------|-------------------------------------------------------|
| [`docs/getting-started.md`](docs/getting-started.md)          | 5-minute walkthrough from clone to first loop         |
| [`docs/architecture.md`](docs/architecture.md)                | Component diagram + safety constraints                |
| [`docs/api-reference.md`](docs/api-reference.md)              | Full HTTP API contract + curl recipes                 |
| [`docs/integration-guide.md`](docs/integration-guide.md)      | Mock data, GoRouter, auth, multi-flavor patterns      |
| [`docs/troubleshooting.md`](docs/troubleshooting.md)          | Failure modes grouped by symptom                      |
| [`docs/e2e-checklist.md`](docs/e2e-checklist.md)              | Manual smoke test (run once after cloning)            |
| [`docs/superpowers/plans/2026-05-21-flutter-visual-loop.md`](docs/superpowers/plans/2026-05-21-flutter-visual-loop.md) | Full implementation plan                  |
| [`CONTRIBUTING.md`](CONTRIBUTING.md)                          | How to add features / fix bugs                        |
| [`SECURITY.md`](SECURITY.md)                                  | Threat model + how to report vulnerabilities          |
| [`CHANGELOG.md`](CHANGELOG.md)                                | Release notes                                         |

## License

MIT — see [`LICENSE`](LICENSE).
