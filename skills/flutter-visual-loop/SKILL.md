---
name: flutter-visual-loop
description: Drive a Flutter app on a real Android device or emulator to restore UI from a design reference (PNG or Figma frame). Captures screenshots via adb, navigates via the flutter_visual_loop SDK's HTTP API, iterates with hot reload until convergence. Use when user gives a design image + target route in a Flutter project that has flutter_visual_loop integrated.
---

# Flutter Visual Loop

Automated UI-restoration loop: design reference → Flutter code → device
screenshot → diff → code edit → hot reload → re-screenshot, until visual
match. Requires the host Flutter app to embed the `flutter_visual_loop`
SDK (see `packages/flutter_visual_loop/README.md`).

Declare on start: **"Using flutter-visual-loop to restore <route> against <design>."**

## When to use

- User points to a design (PNG path / dir of PNGs / Figma URL) and says
  "restore this to `<route>`" or similar.
- The Flutter project must have `flutter_visual_loop` initialized (i.e.
  `FlutterVisualLoop.start()` is called in `main()`) and an Android
  device/emulator connected via `adb`.

## Inputs

| Arg            | Format                                              | Example                       |
|----------------|-----------------------------------------------------|-------------------------------|
| `<design>`     | PNG path, dir with `.png`s, MD with spec, or Figma URL | `example/design/order.png`    |
| `<route>`      | named route in the app's router                     | `/order/detail`               |
| `[args_json]`  | (optional) JSON args for the route                  | `'{"id":"ORD-001"}'`          |
| `[--no-lock]`  | skip `wm size/density` device override              |                               |
| `[--mock k=json]` | (repeatable) inject mock data before navigation  | `--mock order='{"id":"X"}'`   |

## Checklist (TodoWrite this entire list at start)

1. Confirm `adb devices` shows ≥1 device → run `scripts/env_check.sh`.
2. Confirm SDK is reachable on `127.0.0.1:9123` (`/health`).
3. Resolve design input:
   - If single PNG → read with the Read tool (Claude can see PNG).
   - If `.md` design notes → read for spec values.
   - If Figma URL → use `figma-context` MCP to fetch frame + assets.
   - If dir → list `.png`/`.md`, take the obvious target or ask user.
4. Determine design resolution & density:
   - PNG: probe dimensions with `sips -g pixelWidth -g pixelHeight <file>`
     (macOS) or `identify <file>` (ImageMagick) and look up the table below.
   - Figma: read frame dimensions from the MCP response.
5. (Unless `--no-lock`) run `scripts/setup.sh <w> <h> <density>`.
6. For PNG without `.md` spec, do **one** spec-proposal turn (template below)
   and wait for user confirmation (≤30 s) before entering the loop.
7. Apply `--mock=...` overrides via `scripts/mock_set.sh`.
8. Loop, max 5 rounds:
   1. `scripts/navigate.sh <route> [args]`
   2. `scripts/capture.sh $CLAUDE_JOB_DIR/round-<N>.png`
   3. Read both images, diff visually, edit Dart files (`Edit` tool).
   4. `scripts/hot_reload.sh`
   5. If "close enough" by your own judgment → break.
9. `scripts/reset_device.sh` — ALWAYS runs, even on failure/abort.
10. Write report to `$CLAUDE_JOB_DIR/report.md`.

## Pre-loop env check (run FIRST)

```bash
bash skills/flutter-visual-loop/scripts/env_check.sh
```

Expected: `ok: device=<id> port=9123`. On error, the script prints
`ERR: <reason>` and exits non-zero — surface it to the user and stop.

## Resolution lookup table (PNG → logical → wm args)

| PNG size       | Probable design     | `wm size`     | `wm density` |
|----------------|---------------------|---------------|--------------|
| 1290×2796      | iPhone 14/15 Pro 3x | 1290x2796     | 480          |
| 1170×2532      | iPhone 12/13/14 3x  | 1170x2532     | 480          |
| 1179×2556      | iPhone 14 Pro 3x    | 1179x2556     | 480          |
| 1242×2688      | iPhone XS Max 3x    | 1242x2688     | 480          |
| 1080×2400      | Android 3x          | 1080x2400     | 480          |
| 720×1600       | Android 2x          | 720x1600      | 320          |
| 750×1624       | iOS 2x              | 750x1624      | 320          |
| 360×800        | Android 1x mark-up  | 360x800       | 160          |

If the PNG height/width pair matches none of these within ±5%, ASK the
user which density to use. Do **not** guess past ±5%.

## Spec proposal template (PNG mode, no `.md` spec file)

Output exactly this format and wait for confirmation before the loop:

```
Estimated spec (confidence H/M/L):
  primary color:        #2E7CF6   (H)
  background:           #FFFFFF   (H)
  body font size:       14sp      (M)
  title font size:      18sp      (M)
  title weight:         medium    (L — could be semibold)
  card corner radius:   12dp      (L — could be 8 or 16)
  default padding:      16dp      (H)

Override any of these (reply with k=v lines) or say "ok" to proceed.
```

## Loop iteration template (per round, ≤5 rounds)

```
Round N/5
  navigate <route> <args>
  capture  $CLAUDE_JOB_DIR/round-N.png
  diff against <design>
  changes:
    - <file>:<line> ...
  hot reload
```

## Always-cleanup

Whether the loop succeeds, errors out, or you abort, the **last** action
must be:

```bash
bash skills/flutter-visual-loop/scripts/reset_device.sh
```

If the user's device is left at the wrong `wm size`, they will be unhappy.
Treat reset as a hard postcondition. Use a trap-on-exit pattern if you
spawn a long-running shell:

```bash
trap 'bash skills/flutter-visual-loop/scripts/reset_device.sh' EXIT
```

## Hot reload setup (one-time, document for user)

The user must start `flutter run` so the skill can drive hot reload:

```bash
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d <device-id> < /tmp/flutter-vl-stdin &
# wait for "Flutter run key commands" line
```

If they didn't, the loop still works — just skip `hot_reload.sh` and tell
the user to press `r` themselves between rounds. Or restart with the fifo.

## Common failure modes & responses

| Symptom                                | Fix                                                  |
|----------------------------------------|------------------------------------------------------|
| `env_check.sh` says SDK unreachable    | Tell user to run `flutter run` first and reconnect   |
| `/navigate` returns 503                | Navigator not ready — wait 1s and retry once         |
| `/screenshot` returns 500              | Host didn't wrap with `VisualLoopRoot` — fall back to capture.sh |
| Screenshot all-black                   | Device is asleep — `adb shell input keyevent 26`     |
| Hot reload fifo not present            | Skip hot_reload.sh; instruct user, continue          |
| Persistent visual drift after 5 rounds | Stop. Print remaining gaps. Do NOT silently exceed   |
| `wm size` rejected on locked-down ROM  | Fall back to `--no-lock`; warn user about scale      |

## Reporting

At end (success or abort), write `$CLAUDE_JOB_DIR/report.md`:

```markdown
# Visual Loop Report — <route>

- Design: <path>
- Rounds: <n>/5
- Result: <converged | gaps remain | aborted>

## Per-round screenshots
- round-1.png
- round-2.png
...

## Code changes
- example/lib/pages/order_detail_page.dart:42-67
- example/lib/pages/order_detail_page.dart:120 (new color constant)

## Remaining gaps (if any)
- Card shadow not matching design — `BoxShadow` blurRadius too low
```
