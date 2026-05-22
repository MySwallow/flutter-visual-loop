# 更新日志

本项目的所有重要变更都会记录在此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),版本规则遵循
[Semantic Versioning](https://semver.org/spec/v2.0.0.html)。

## [0.1.0] — 2026-05-21

### 新增 — SDK (`packages/flutter_visual_loop`)
- `FlutterVisualLoop.start()` / `stop()` / `bind()` 门面 API
- HTTP server(默认 `127.0.0.1:9123`),提供以下 endpoint:
  - `GET /health`
  - `GET /routes`
  - `POST /navigate` — `{route, args, popUntilRoot}`
  - `POST /reset` — `{clearMock}`
  - `POST /mock` — `{action: enable|set|get|reset|list, ...}`
  - `GET /screenshot` — Flutter 渲染树截图(PNG)
- `MockDataProvider` 接口 + `InMemoryMockDataProvider` 实现
- `RouteRegistry` 管理可发现的命名路由
- `VisualLoopRoot` Widget 包装,确保 app 内截图可靠
- `VisualLoopConfig` 提供 port / host / 截图模式 / body 上限等配置
- Release 构建是 no-op(由 `kDebugMode` 守门)
- 单元测试: `route_registry_test`, `mock_provider_test`

### 新增 — Skill (`skills/flutter-visual-loop`)
- `SKILL.md` 含 checklist、分辨率查表、失败模式、报告模板
- 脚本:
  - `env_check.sh` — adb / curl / 设备 / 端口预检
  - `setup.sh` — 记录并覆写 `wm size`/`wm density`
  - `navigate.sh` — `POST /navigate`
  - `capture.sh` — `adb exec-out screencap`,带 PNG magic 校验
  - `hot_reload.sh` — 往 flutter run 的 fifo 写 `r`
  - `reset_device.sh` — 还原原始值(始终 exit 0)
  - `mock_set.sh` — `POST /mock action=set`

### 新增 — Example
- `example/` 演示 Flutter app,4 个页面 + 一个 mock provider
- `example/design/` 下的占位设计稿说明

### 新增 — 文档
- `README.md` — 入口
- `docs/architecture.md` — 高层组件图
- `docs/getting-started.md` — 5 分钟上手
- `docs/api-reference.md` — 完整 HTTP API
- `docs/integration-guide.md` — Mock / Router / Auth 等集成场景
- `docs/troubleshooting.md` — 按症状分类的故障排查
- `docs/e2e-checklist.md` — 手动 smoke test
- `docs/superpowers/plans/2026-05-21-flutter-visual-loop.md` — 完整实施计划
- `CONTRIBUTING.md`, `SECURITY.md`, `CHANGELOG.md`
- `.github/workflows/ci.yml` — push/PR 触发 flutter test
- `.github/ISSUE_TEMPLATE/*`, `PULL_REQUEST_TEMPLATE.md`

### 已知限制
- 仅 Android(iOS 没有 `adb forward` 等价物)
- 暂不支持 Web 平台(`dart:io HttpServer` 不可用)
- 部分国产 ROM(MIUI / HarmonyOS)会静默拒绝 `wm size`/`wm density` 覆写,
  此时退化到 `--no-lock`
