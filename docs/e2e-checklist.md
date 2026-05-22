# 端到端验证清单

这份是手动 smoke test,证明 SDK + Skill 端到端工作正常。开发机器没有 Flutter 工具链(没有 `flutter`、没有 `dart`、没有 `adb`),所以 plan 作者没法跑;clone 之后在你笔记本上跑一次。

## 前置条件

- macOS / Linux,装了 **Flutter SDK**(`flutter doctor` 全绿)
- **Android 设备**,USB 调试已开,或 Android 模拟器在跑
- `adb devices` 显示设备为 `device`(不是 `unauthorized`)

## 第 1 步 — 给 example app 生成平台脚手架

```bash
cd flutter-visual-loop/example
flutter create . --platforms=android,ios --org com.example.visualloop
flutter pub get
```

`flutter create .` 不会覆盖已存在的文件,只补 `android/`、`ios/` 和一些小文件。

## 第 2 步 — 跑 SDK 单元测试(不需要设备)

```bash
cd flutter-visual-loop/packages/flutter_visual_loop
flutter pub get
flutter test
```

期望:

```
00:01 +X: All tests passed!
```

## 第 3 步 — 用热重载 fifo 启动 example app

```bash
cd flutter-visual-loop/example
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d $(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}') \
  < /tmp/flutter-vl-stdin &
```

等到看见:

```
[flutter_visual_loop] registered route: /
[flutter_visual_loop] registered route: /login
[flutter_visual_loop] registered route: /product/detail
[flutter_visual_loop] registered route: /order/detail
[flutter_visual_loop] listening on http://127.0.0.1:9123
```

## 第 4 步 — 端口转发 + HTTP API 烟雾测试

```bash
adb forward tcp:9123 tcp:9123

curl -sf http://localhost:9123/health
# → {"ok":true,"version":"0.1.0","service":"flutter_visual_loop"}

curl -sf http://localhost:9123/routes
# → {"ok":true,"routes":["/","/login","/product/detail","/order/detail"]}

curl -sf -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail","args":{"id":"ORD-001"}}'
# → {"ok":true,"route":"/order/detail"}
# 设备应该显示订单页

# 截屏
adb exec-out screencap -p > /tmp/order.png
file /tmp/order.png
# → /tmp/order.png: PNG image data, ...

# 切 mock
curl -sf -X POST http://localhost:9123/mock \
  -H 'content-type: application/json' \
  -d '{"action":"set","key":"order","value":{"id":"X","amount":1.0,"status":"hi","items":[]}}'

# 重新跳一次看新数据
curl -sf -X POST http://localhost:9123/navigate \
  -H 'content-type: application/json' \
  -d '{"route":"/order/detail"}'

# 重置
curl -sf -X POST http://localhost:9123/reset \
  -H 'content-type: application/json' \
  -d '{"clearMock":true}'
```

## 第 5 步 — 跑 skill 对齐 demo 设计稿

Claude Code 会话(cwd 是本 repo):

```
/flutter-visual-loop example/design/order_detail.md /order/detail
```

(或用真实 PNG。)Skill 应该:

- 通过 `env_check.sh`。
- 让你确认 spec 值(输入是 `.md`/PNG 但没内嵌 spec 时)。
- 最多跑 5 轮。截图存到 `$CLAUDE_JOB_DIR/round-N.png`。
- 跑完 `reset_device.sh`,并在 `$CLAUDE_JOB_DIR` 写一份 `report.md`。

## 第 6 步 — 确认设备被还原

```bash
adb shell wm size
# 期望:只有 "Physical size: ..."(没有 "Override size:" 这行)

adb shell wm density
# 期望:只有 "Physical density: ..."(没有 "Override density:" 这行)
```

如果还有 Override,手动跑:

```bash
bash skills/flutter-visual-loop/scripts/reset_device.sh
```

## 怎么算"工作正常"

- `/health` 返回 200,版本号对。
- `/navigate` 真的让界面跳转了。
- 截图文件非空且是 PNG,视觉上和设备所见一致。
- `/mock` set + 跳转后,可见数据变了。
- `wm size` / `wm density` 跑完恢复。
- SDK 单元测试通过。

## 历史踩过的坑(逐项检查)

- **PNG 截图 magic bytes**:`head -c 4 file.png | xxd -p` 应该是 `89504e47`。不是的话,可能设备锁屏,或者 shell 吃掉了二进制流。
- **`wm size` 被拒**:有些厂商 ROM(MIUI、HarmonyOS)会静默拒绝。跑完 `setup.sh 1080 2400 480` 后再 `adb shell wm size`,确认 "Override size: 1080x2400" 出现了。
- **两台设备混淆**:模拟器 + 真机同时连,`adb` 可能选错。设 `ANDROID_SERIAL=<id>` 环境变量。
- **端口被占**:笔记本上 9123 已被占,用 `VisualLoopConfig(port: 9124)` 启 SDK,然后 `adb forward tcp:9124 tcp:9124`。
