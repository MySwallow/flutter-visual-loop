# 故障排查

现实里会碰到的失败模式 + 恢复方式。按"现象在哪一层暴露"分组。

> **注(2026-05-22):** 本文档反映 flutter-visual-loop **旧版**的脚本驱动行为。新版 skill 已重构为 thin orchestrator,实际设备操作(`env_check` / `setup` / `navigate` / `capture` / `hot_reload` / `mock_set` / `reset_device`)委托给 `flutterwright` skill(暂未实现,脚本已迁至 `~/Documents/dev/github/flutterwright/scripts/`)。下文中的脚本提及保留作为历史参考,待 flutterwright 落地后整体重写。

## `env_check.sh` 失败

### `ERR: adb not installed`

安装 Android platform-tools:

```bash
# macOS
brew install --cask android-platform-tools

# Ubuntu
sudo apt install adb

# 验证
adb --version
```

### `ERR: no adb device connected`

```bash
adb devices
# 如果是空的:在手机的"开发者选项"里开 USB 调试,
# 第一次连的时候在手机上接受 RSA 指纹弹窗。
```

模拟器先起一个:

```bash
emulator -list-avds
emulator -avd <name> -no-snapshot-load &
```

### `ERR: SDK not reachable on 127.0.0.1:9123`

要么 Flutter app 没在跑,要么跑了但没调 `FlutterVisualLoop.start()`,要么端口转发没设。

检查清单:

```bash
# 1. flutter run 还在吗?
jobs | grep flutter
# 或者直接找进程
pgrep -f 'flutter run'

# 2. 端口转发设了吗?
adb forward --list | grep 9123
# 没的话:
adb forward tcp:9123 tcp:9123

# 3. SDK 真的 bind 了吗?
# flutter run 输出里应该有:
#   [flutter_visual_loop] listening on http://127.0.0.1:9123
# 没有的话,app 没调过 FlutterVisualLoop.start() — 查 main.dart

# 4. 主机上有别的东西占了 9123 吗?
lsof -i :9123
# 有的话杀掉,或者改用 VisualLoopConfig(port: 9124)
```

## `/navigate` 问题

### 返回 `503 navigator not ready`

App 还在启动。任选其一:

- 等 ~500ms 重试一次。
- 用 `FlutterVisualLoop.start(autoStart: false)` 延后,第一帧后调 `FlutterVisualLoop.bind()`。

### 返回 `500 ...`,error 里带路由名

路由名没匹配上 `onGenerateRoute`(或静态 `routes:` map)。查:

```bash
curl http://localhost:9123/routes
# 看现有注册了什么。你的路由不在的话:
FlutterVisualLoop.routes.register('/your/route');
```

注意 `/routes` 只显示**已注册**的;`/navigate` 还是会把**任何**名字往 `onGenerateRoute` 推 — 报错说明 router 真的不认识那个 path。

### 页面切换了但 UI 没更新

通常是页面读的 state 没刷新。临时修法:

- 加 `popUntilRoot: true`(默认就是)强制重新 mount。
- 两次跳转之间重置 mock:`POST /reset {"clearMock":true}`。

## 截图问题

### `/screenshot` 返回 500

宿主没用 `VisualLoopRoot` 包根。任选其一:

- 修:`runApp(VisualLoopRoot(child: MyApp()))`。
- 绕开:循环里用 `adb exec-out screencap -p > cur.png`。

### 截图全黑

设备屏幕灭了。唤醒:

```bash
adb shell input keyevent 26      # 电源键
adb shell input keyevent 82      # menu,关掉锁屏提示
```

如果锁屏需要 PIN,在测试期间把测试设备的锁屏关掉。

### 截图被缩放了

通常是漏了 `adb forward`,或者 `wm size` / `wm density` 覆写不匹配。检查:

```bash
adb shell wm size       # 当前逻辑分辨率
adb shell wm density    # 当前 dpi
```

如果你设了 `wm size 1080x2400` 但 `wm density` 还是手机默认值(比如 Pixel 7 的 422dpi),实际 DP 就和预期不符。设备 reset 已迁至 flutterwright skill,这里手动跑 adb 即可:

```bash
adb shell wm size reset
adb shell wm density reset
```

## Mock 相关问题

### `/mock` 返回 `501 no MockDataProvider configured`

你调 `FlutterVisualLoop.start()` 时没传 `mockProvider:`。加一个:

```dart
final mock = InMemoryMockDataProvider();
await FlutterVisualLoop.start(mockProvider: mock);
```

### Mock 值改了但 UI 没反应

Repository / service 在缓存结果。常见修法:

- debug 下禁掉缓存:
  ```dart
  if (kDebugMode) cache.clear();
  ```
- 或者 `POST /mock` 后跟一次 `POST /reset`,然后重新跳转 — 新 mount 读新数据。

## 热重载问题

### `hot_reload.sh` 报 `nobody is reading FIFO`

要么 `flutter run` 退了,要么启动时没接 fifo。重启:

```bash
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d <device> < /tmp/flutter-vl-stdin &
```

### 改了代码没生效

- 热重载不会捕获 `main()` 和顶层初始化的改动。用热重启代替:`echo R > /tmp/flutter-vl-stdin`。
- 改了 const constructor 也要重启才生效。

## 任务结束后设备状态奇怪

```bash
adb shell wm size reset
adb shell wm density reset

# 如果之前设过 overscan:
adb shell wm overscan reset

# 如果屏幕灭着:
adb shell input keyevent 26

# 如果 app 卡在奇怪的路由:
curl -X POST http://localhost:9123/reset -d '{"clearMock":true}'
# 或者干脆重启 app:
adb shell am force-stop com.example.visualloop
```

## "Android 上没问题,iOS 上不行"

Skill 是 Android-only,因为:

- iOS Simulator 截图:`xcrun simctl io booted screenshot`(能用)
- iOS deep-link / port forward:不存在(没有 `adb forward` 等价物)

想支持 iOS Simulator,得:

- SDK 改成绑 UNIX socket 而不是 TCP,**或者**
- 用 `simctl spawn` + 一个能从主机访问的端口(不在隔离的 network namespace 里)

欢迎 PR。

## 中国厂商 ROM 特殊情况(MIUI、HarmonyOS、ColorOS 等)

这些 ROM 有时会静默拒绝 `wm size` / `wm density`。跑完 `setup.sh` 后验证:

```bash
adb shell wm size
# 期望: "Physical size: ..." 加上 "Override size: 1080x2400"
# 没有 Override 那行说明改动被拒了。
```

绕开方案:

- 用 `--no-lock`(跳过分辨率改动),接受设备默认。
- 换一台设备做设计还原。
- 试 ADB owner / device owner 权限(高级;部分设备会丢保修)。
