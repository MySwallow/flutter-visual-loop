# Changelog

## 0.1.0 (initial release)

- Debug-only HTTP server on `127.0.0.1:9123` (configurable).
- Endpoints: `/health`, `/routes`, `/navigate`, `/reset`, `/mock`, `/screenshot`.
- `MockDataProvider` interface with `InMemoryMockDataProvider` default impl.
- `VisualLoopRoot` widget wrapper for reliable in-app screenshots.
- Production builds are no-op (gated by `kDebugMode`).
