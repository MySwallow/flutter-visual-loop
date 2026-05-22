# 更新日志

## 0.1.0 (首次发布)

- 仅 debug 启用的 HTTP server,默认绑 `127.0.0.1:9123`(可配置)。
- Endpoints: `/health`, `/routes`, `/navigate`, `/reset`, `/mock`, `/screenshot`。
- `MockDataProvider` 接口 + `InMemoryMockDataProvider` 默认实现。
- `VisualLoopRoot` Widget 包装,让 app 内截图更可靠。
- Release 构建是 no-op(由 `kDebugMode` 守门)。
