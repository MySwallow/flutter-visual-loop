# Flutter Visual Loop

自动化的 Figma / PNG → Flutter UI 还原循环。通过 `adb` 驱动真机或模拟器,
截屏并基于设计稿用 Claude Code 迭代代码。

仓库里包含三样东西:

| 路径                              | 是什么                                                  |
|-----------------------------------|--------------------------------------------------------|
| `packages/flutter_visual_loop/`   | Dart 包:任何 app 都能集成的 debug-only HTTP 控制 server |
| `skills/flutter-visual-loop/`     | Claude Code skill,负责驱动整个循环                    |
| `example/`                        | 演示 Flutter app,展示 SDK 集成方式                    |

## 快速上手

1. 在 Flutter app 的 `pubspec.yaml` 里加 `flutter_visual_loop` 依赖
   (pub.dev 发布前用 `path:` 或 `git:`)。
2. `main()` 里调 `FlutterVisualLoop.start()`(仅 debug 启用)。
3. 用 `flutter run -d <id>` 把 app 跑起来。
4. 在 Claude Code 里:

   ```
   /flutter-visual-loop example/design/order_detail.png /order/detail
   ```

详见 [`packages/flutter_visual_loop/README.md`](packages/flutter_visual_loop/README.md)
和 [`skills/flutter-visual-loop/SKILL.md`](skills/flutter-visual-loop/SKILL.md)。

## 架构

详见 [`docs/architecture.md`](docs/architecture.md)。TL;DR:SDK 在宿主 app 进程内跑一个 debug-only 的 HTTP server,绑 `127.0.0.1:9123`;skill 用 `adb` 转发该端口,然后用 `curl` + `adb exec-out screencap` 驱动循环。

## 文档

| 文档                                                          | 内容                                                  |
|---------------------------------------------------------------|------------------------------------------------------|
| [`docs/getting-started.md`](docs/getting-started.md)          | 5 分钟从 clone 走到第一次循环                         |
| [`docs/architecture.md`](docs/architecture.md)                | 组件图 + 安全约束                                     |
| [`docs/api-reference.md`](docs/api-reference.md)              | 完整 HTTP API + curl 示例                             |
| [`docs/integration-guide.md`](docs/integration-guide.md)      | Mock 数据、GoRouter、Auth、多 flavor 等集成模式       |
| [`docs/troubleshooting.md`](docs/troubleshooting.md)          | 按现象分类的故障排查                                  |
| [`docs/e2e-checklist.md`](docs/e2e-checklist.md)              | 手动 smoke test(clone 后跑一遍)                     |
| [`docs/superpowers/plans/2026-05-21-flutter-visual-loop.md`](docs/superpowers/plans/2026-05-21-flutter-visual-loop.md) | 完整实施计划(英文,作为历史 artifact 保留) |
| [`CONTRIBUTING.md`](CONTRIBUTING.md)                          | 怎么加功能 / 修 bug                                   |
| [`SECURITY.md`](SECURITY.md)                                  | 威胁模型 + 漏洞上报方式                               |
| [`CHANGELOG.md`](CHANGELOG.md)                                | 版本变更记录                                          |

## 许可证

MIT — 见 [`LICENSE`](LICENSE)。
