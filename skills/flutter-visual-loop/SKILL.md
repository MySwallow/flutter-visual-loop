---
name: flutter-visual-loop
description: 驱动一个 Flutter app 在真实 Android 设备或模拟器上,把 UI 还原到设计稿(PNG 或 Figma frame)。通过 adb 截图,通过 flutter_visual_loop SDK 的 HTTP API 跳转路由,配合热重载迭代到视觉收敛。当用户在已集成 flutter_visual_loop 的 Flutter 项目里给出 design image + 目标 route 时使用。
---

# Flutter Visual Loop

自动化 UI 还原循环:设计稿 → Flutter 代码 → 设备截图 → 对比 → 改代码 → 热重载 → 重截图,直到视觉匹配。需要宿主 Flutter app 已集成 `flutter_visual_loop` SDK(见 `packages/flutter_visual_loop/README.md`)。

启动时声明:**"Using flutter-visual-loop to restore <route> against <design>."**

## 何时使用

- 用户给出设计稿(PNG 路径 / PNG 目录 / Figma URL)并要求"把这个 UI 还原到 `<route>`"或类似表述。
- Flutter 项目必须已经初始化了 `flutter_visual_loop`(`main()` 里调过 `FlutterVisualLoop.start()`),并且通过 `adb` 连了 Android 设备/模拟器。

## 输入

| 参数             | 形式                                                | 例子                          |
|------------------|-----------------------------------------------------|-------------------------------|
| `<design>`       | PNG 路径、含 PNG 的目录、含 spec 的 .md、或 Figma URL | `example/design/order.png`    |
| `<route>`        | app router 里的命名路由                             | `/order/detail`               |
| `[args_json]`    | (可选)路由参数 JSON                                | `'{"id":"ORD-001"}'`          |
| `[--no-lock]`    | 跳过 `wm size/density` 设备覆写                     |                               |
| `[--mock k=json]` | (可重复)跳转前注入 mock 数据                       | `--mock order='{"id":"X"}'`   |

## Checklist(开始时 TodoWrite 整个清单)

1. 确认 `adb devices` 至少有 1 个设备 → 跑 `scripts/env_check.sh`。
2. 确认 SDK 可达 `127.0.0.1:9123` (`/health`)。
3. 解析设计稿输入:
   - 单个 PNG → 用 Read tool 读(Claude 看得到 PNG)。
   - `.md` 设计说明 → 读出里面的 spec 值。
   - Figma URL → 用 `figma-context` MCP 拉 frame + assets。
   - 目录 → 列出 `.png`/`.md`,取明显目标或问用户。
4. 确定设计稿分辨率和 density:
   - PNG:用 `sips -g pixelWidth -g pixelHeight <file>` (macOS) 或 `identify <file>` (ImageMagick) 测尺寸,查下面的表。
   - Figma:从 MCP 响应里读 frame 尺寸。
5. (除非 `--no-lock`)跑 `scripts/setup.sh <w> <h> <density>`。
6. 输入是 PNG 且无 `.md` spec 时,做**一轮** spec 提案(模板见下),等用户确认(≤30s)后进入循环。
7. 通过 `scripts/mock_set.sh` 应用 `--mock=...` 覆写。
8. 最多 5 轮循环:
   1. `scripts/navigate.sh <route> [args]`
   2. `scripts/capture.sh $CLAUDE_JOB_DIR/round-<N>.png`
   3. 读两张图,视觉对比,改 Dart 文件(`Edit` 工具)。
   4. `scripts/hot_reload.sh`
   5. 凭自己判断"够接近了"就 break。
9. `scripts/reset_device.sh` — **永远**要跑,失败/abort 也要。
10. 把报告写到 `$CLAUDE_JOB_DIR/report.md`。

## 循环前环境检查(**先**跑这个)

```bash
bash skills/flutter-visual-loop/scripts/env_check.sh
```

期望:`ok: device=<id> port=9123`。出错时脚本打印 `ERR: <原因>` 并非零退出 — 反馈给用户并停下。

## 分辨率查表(PNG → logical → wm 参数)

| PNG 尺寸       | 大概率设计稿        | `wm size`     | `wm density` |
|----------------|---------------------|---------------|--------------|
| 1290×2796      | iPhone 14/15 Pro 3x | 1290x2796     | 480          |
| 1170×2532      | iPhone 12/13/14 3x  | 1170x2532     | 480          |
| 1179×2556      | iPhone 14 Pro 3x    | 1179x2556     | 480          |
| 1242×2688      | iPhone XS Max 3x    | 1242x2688     | 480          |
| 1080×2400      | Android 3x          | 1080x2400     | 480          |
| 720×1600       | Android 2x          | 720x1600      | 320          |
| 750×1624       | iOS 2x              | 750x1624      | 320          |
| 360×800        | Android 1x 标注稿   | 360x800       | 160          |

PNG 尺寸偏差超 ±5% 时,**问**用户用哪个 density。不要自己猜超过 ±5%。

## Spec 提案模板(PNG 模式,无 `.md` spec 文件)

按这个格式输出,等用户确认再进循环:

```
Estimated spec (confidence H/M/L):
  primary color:        #2E7CF6   (H)
  background:           #FFFFFF   (H)
  body font size:       14sp      (M)
  title font size:      18sp      (M)
  title weight:         medium    (L — 可能是 semibold)
  card corner radius:   12dp      (L — 可能是 8 或 16)
  default padding:      16dp      (H)

Override any of these (用 k=v 形式回复) or say "ok" to proceed.
```

## 单轮循环模板(每轮,≤5 轮)

```
Round N/5
  navigate <route> <args>
  capture  $CLAUDE_JOB_DIR/round-N.png
  diff against <design>
  changes:
    - <file>:<line> ...
  hot reload
```

## 始终清理

不论循环成功、出错、还是 abort,**最后一步**必须是:

```bash
bash skills/flutter-visual-loop/scripts/reset_device.sh
```

设备的 `wm size` 留着错的话,用户会很不爽。把 reset 当作硬性后置条件。如果你启动了长跑 shell,用 trap-on-exit:

```bash
trap 'bash skills/flutter-visual-loop/scripts/reset_device.sh' EXIT
```

## 热重载准备(一次性,告诉用户)

用户必须用 fifo 启动 `flutter run`,skill 才能驱动热重载:

```bash
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d <device-id> < /tmp/flutter-vl-stdin &
# 等到出现 "Flutter run key commands" 行
```

如果他们没这么干,循环还是能跑 — 只是跳过 `hot_reload.sh`,告诉用户每轮自己按 `r`。或者建议带 fifo 重启。

## 常见失败模式 + 应对

| 现象                                    | 处理                                                     |
|-----------------------------------------|----------------------------------------------------------|
| `env_check.sh` 说 SDK 不可达             | 告诉用户先 `flutter run` 再重连                          |
| `/navigate` 返回 503                     | Navigator 还没准备好 — 等 1s 重试一次                    |
| `/screenshot` 返回 500                   | 宿主没用 `VisualLoopRoot` 包 — 改用 capture.sh           |
| 截图全黑                                | 设备睡了 — `adb shell input keyevent 26`                 |
| 热重载 fifo 不存在                       | 跳过 hot_reload.sh,告诉用户重设 fifo,继续              |
| 5 轮后视觉仍然漂移                       | 停。打印剩余 gap。**不要**静默超过 5 轮                  |
| `wm size` 在锁死的 ROM 上被拒            | 退回 `--no-lock`,告诉用户存在缩放                       |

## 报告

结束时(成功或 abort)往 `$CLAUDE_JOB_DIR/report.md` 写:

```markdown
# Visual Loop Report — <route>

- 设计稿: <path>
- 轮次: <n>/5
- 结果: <收敛 | 有遗留 gap | 中止>

## 各轮截图
- round-1.png
- round-2.png
...

## 代码变更
- example/lib/pages/order_detail_page.dart:42-67
- example/lib/pages/order_detail_page.dart:120 (新增颜色常量)

## 遗留 gap(如有)
- 卡片阴影对不上设计 — `BoxShadow` blurRadius 偏低
```
