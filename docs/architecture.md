# 架构

## 整体流程

```
+--------------------+        +---------------------+        +-----------------+
| Claude Code        |  HTTP  | flutter_visual_loop |  app   | 宿主 Flutter    |
| + flutter-visual-  | <----> | (debug HTTP server) | hooks  | App 跑在设备上  |
| loop skill         |  9123  | (进程内)            |        |                 |
+--------------------+        +---------------------+        +-----------------+
        ^                                                          ^
        |                                                          |
        |          adb forward / adb exec-out screencap            |
        +----------------------------------------------------------+
```

## 组件

### SDK (`packages/flutter_visual_loop`)

- **`FlutterVisualLoop`** 门面 — start/stop,暴露 `navigatorKey`。
- **`VisualLoopHttpServer`** — 用 `dart:io HttpServer` 绑 `127.0.0.1:9123`(可配置),分发请求给 handler。
- **Handlers** — 每个 endpoint 一个文件。基于 request/response context 的纯函数。让影响面尽量小。
- **`RouteRegistry`** — 包装宿主 app 的命名路由表,skill 通过 `GET /routes` 拿到可发现的路由列表。
- **`MockDataProvider`** — 宿主实现的接口。默认提供 `InMemoryMockDataProvider`。SDK 自身不会读 mock 数据,只把控制命令路由给 provider — 真正读数据是宿主 app 在 repository / service 里做。
- **`VisualLoopRoot`** — 可选的 Widget 包装,宿主把它包在 root 上让 `/screenshot` 可靠地工作(提供 `RepaintBoundary`)。

### Skill (`skills/flutter-visual-loop`)

- **`SKILL.md`** — 顶层指引,读设计稿、驱动循环。
- **`scripts/`** — 小 bash 脚本。Skill 保持声明式,脚本封装 adb / curl 的细节。

## 安全约束

- 当 `kDebugMode == false` 时,SDK 拒绝启动(由默认 config 守门)。
- Server 仅绑定 `127.0.0.1`,不暴露到 LAN。
- `adb wm size` / `wm density` 覆写由 skill 记录,任务结束(或任何失败路径)必还原。
- 每个 endpoint 在 debug console 输出一行汇总;超过 `maxBodyBytes`(默认 1 MiB)的请求返回 413。

## 故意**不**做的事

- 触发热重载 — 那是 `flutter run` 自己的事,skill 通过 fifo 驱动。
- 视觉对比 — 在 skill 层由 LLM 完成。
- Figma 客户端 — 输入是 URL 时,skill 用现有的 `figma-context` MCP。
