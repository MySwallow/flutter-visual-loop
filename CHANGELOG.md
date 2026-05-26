# 更新日志

本项目的所有重要变更都会记录在此文件。

格式遵循 [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),版本规则遵循
[Semantic Versioning](https://semver.org/spec/v2.0.0.html)。

## [0.3.0] — 2026-05-26

### 变更 — 对齐 flutter-wright 0.6.0

flutter-wright 升级到 0.6.0(SDK 可选化 + AI 持有 `flutter run` daemon + 移除 mock),
本 skill 的编排契约随之更新:

- **SKILL.md**:编排序列新增 `run`(开头由 flutter-wright 起 app 并持有 daemon —— 0.6.0 的
  `reload` 只热重载 flutter-wright 自己 `run` 起的 daemon,app 不再能由外部手动启动)与
  `stop`(退出清理为 `reset` → `resetViewport` → `stop`,补上原本漏掉的 `resetViewport` 使设备分辨率也还原);并点明 `goto` 程序化导航需 app 集成 `flutter_wright_sdk`。
- **README.md**:下层 flutter-wright 方法列表改为
  `run / stop / health / goto / screenshot / reload / setViewport / resetViewport / reset`
  (移除已删的 `mock`,补上新增的 `run` / `stop`);"怎么用"前提从 "app 跑在设备上" 改为
  "由 flutter-wright `run` 起 app",并点明 SDK 是因 `goto` 导航而需。

> 历史 `docs/superpowers/{specs,plans}/*` 为 point-in-time 存档,描述重构当时的契约,不回写。

## [0.2.0] — 2026-05-22

### 重构 — Skill (`skills/flutter-visual-loop`)

把 SKILL.md 从 163 行(含 7 个 shell 脚本 + checklist + 分辨率查表 + 失败模式表)
重构为 6 行 thin orchestrator,与 `figma-visual-loop` skill 形态对标。
新版职责仅限于:编排上游数据获取、调用下层设备驱动、视觉对比、改 Dart 代码、5 轮循环。

- 删除 7 个内嵌设备驱动脚本(env_check / setup / navigate / capture / hot_reload / mock_set / reset_device);相关脚本迁至 [`flutterwright`](../flutterwright/) 仓库
- 删除 PNG / PNG 目录 / `.md` spec 三种旧输入分支,仅保留两个入口:Figma URL 与 Mockplus URL
- 设计稿数据获取改由上游 skill / MCP 提供:`figma-context` MCP 处理 Figma,`mockplus-context` skill 处理 Mockplus
- 设备操作改由下层 `flutterwright` skill 提供(暂未实现,SKILL.md 已声明依赖)

### 迁移 — SDK / Example / SDK 文档迁至 flutterwright 仓库

以下物料从本仓库迁至 `~/Documents/dev/github/flutterwright/`,因其全部为设备驱动层物料:

- `packages/flutter_visual_loop/` — Dart SDK(进程内 HTTP server + handlers + route registry + mock provider)
- `example/` — SDK 演示 Flutter app(`pubspec.yaml` path 依赖 SDK,跟随迁出)
- `docs/architecture.md` / `api-reference.md` / `getting-started.md` / `integration-guide.md` / `e2e-checklist.md` / `troubleshooting.md` — 全部描述 SDK + 设备驱动行为
- `CONTRIBUTING.md` / `SECURITY.md` — 内容均针对 SDK(贡献规则、网络威胁模型)

### 移除

- `scripts/validate.sh` — 校验范围 70% 在迁出物料上
- `.github/workflows/ci.yml` — 3 个 job 中 2 个完全依赖 SDK / example

### 本仓库当前状态

仅剩 skill 本体 + 设计文档 + 历史 plan + LICENSE + issue/PR 模板。CI 已移除。
本仓库现已严格对标 `figma-visual-loop` 的纯 skill 仓库形态。

详见 [`docs/superpowers/specs/2026-05-22-flutter-visual-loop-refocus-design.md`](docs/superpowers/specs/2026-05-22-flutter-visual-loop-refocus-design.md)。

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
