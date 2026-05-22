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

## Architecture

See [`docs/architecture.md`](docs/architecture.md). TL;DR: the SDK runs a
debug-only HTTP server on `127.0.0.1:9123` inside the host app; the skill
forwards that port via `adb` and drives the loop with `curl` +
`adb exec-out screencap`.

## End-to-end verification

See [`docs/e2e-checklist.md`](docs/e2e-checklist.md).

## License

MIT — see [`LICENSE`](LICENSE).
