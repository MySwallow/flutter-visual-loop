# 快速上手(5 分钟)

这份指南带你从零跑通一次视觉循环。跑一次之后,把 SDK 集成进你自己的 app 也是同样的 3 步。

## 前置条件

- Flutter SDK 3.10+ — `flutter doctor` 全绿
- Android 真机(开了 USB 调试),或 Android 模拟器
- `adb` 在 PATH 里(Android platform-tools 自带)
- `curl`

## 第 1 步 — clone 并初始化 demo

```bash
git clone https://github.com/MySwallow/flutter-visual-loop.git
cd flutter-visual-loop/example
flutter create . --platforms=android,ios --org com.example.visualloop
flutter pub get
```

`flutter create .` 只会补 `android/` 和 `ios/` 脚手架,已有文件不动。

## 第 2 步 — 用一个 fifo 启动 app(让 skill 能触发热重载)

fifo 是 skill 把 `r` 发给 flutter run 触发热重载的通道。

```bash
mkfifo /tmp/flutter-vl-stdin 2>/dev/null || true
flutter run -d $(adb devices | awk 'NR>1 && $2=="device"{print $1; exit}') \
  < /tmp/flutter-vl-stdin &
```

等到看见:

```
[flutter_visual_loop] listening on http://127.0.0.1:9123
```

## 第 3 步 — 端口转发

```bash
adb forward tcp:9123 tcp:9123
curl http://localhost:9123/health
# → {"ok":true,"version":"0.1.0","service":"flutter_visual_loop"}
```

到此整个准备工作完成。之后的事 skill 会驱动。

## 第 4 步 — 在 Claude Code 里跑 skill

在 Claude Code 会话(打开了本 repo 根目录):

```
/flutter-visual-loop example/design/order_detail.md /order/detail
```

Skill 会做这些事:

1. 检查设备 + SDK 是否可达。
2. (输入是 PNG 且无 `.md` spec 文件时)要求你确认设计 spec。
3. 循环最多 5 轮:跳转 → 截图 → 对比 → 改代码 → 热重载。
4. 还原设备 `wm size`/`wm density` 覆写。
5. 输出一份报告到 `$CLAUDE_JOB_DIR/report.md`。

## 第 5 步 — 集成到你自己的 app

照搬 `example/lib/main.dart` 的集成模式:

```dart
import 'package:flutter_visual_loop/flutter_visual_loop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterVisualLoop.start(
    testRoutes: const ['/home', '/order/detail', '/login'],
  );
  runApp(VisualLoopRoot(child: const MyApp()));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: FlutterVisualLoop.navigatorKey,
      onGenerateRoute: yourRouter,
    );
  }
}
```

到此就够了。继续读:

- [`integration-guide.md`](integration-guide.md) — Mock 数据接入和真实 API 模式。
- [`api-reference.md`](api-reference.md) — 完整 HTTP API。
- [`troubleshooting.md`](troubleshooting.md) — 出问题时查。
