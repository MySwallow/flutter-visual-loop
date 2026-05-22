# flutter-visual-loop

Claude Code skill,自主驱动 Flutter UI 视觉对比循环 —— 给定设计稿 URL + 目标路由,Claude 自己拉资产、跑设备、视觉比对、改 Dart 代码、热重载,迭代到收敛。

## 目的

把"按设计稿还原 Flutter UI"这件事自动化。手工拉切图、量距离、改组件、热重载、再对比这套循环,Claude 自己跑,最多 5 轮。结束自动恢复设备状态。

## 依赖的 skill / MCP

| 依赖 | 层级 | 角色 |
|---|---|---|
| `figma-context` MCP | 上游 | 当输入是 Figma frame URL 时,拉 frame data + 切图 |
| `mockplus-context` skill | 上游 | 当输入是 Mockplus develop URL 时,产出 spec.md + design.png + assets/ |
| `flutterwright` skill | 下层 | 驱动 Flutter 设备(setup / navigate / capture / hot_reload / mock_set / reset) |

> ⚠️ **当前状态:** `flutterwright` skill 尚未实现,设备驱动调用暂时落空。设计稿数据获取(`figma-context` + `mockplus-context`)已可用;skill 的编排逻辑已重构。flutterwright 落地后即可端到端跑通。

## 怎么用

在已经集成 `flutter_visual_loop` SDK(见 [`flutterwright`](../flutterwright/) 仓库)且 app 跑在设备上的 Flutter 项目里,跟 Claude 说:

> 按这个 Figma frame 还原 `/order/detail` 页面:
> https://www.figma.com/...

或者:

> 按这个 Mockplus 页面还原 `/cart` 页面:
> https://app.mockplus.cn/app/.../develop/design/...

Claude 自己识别 URL 类型,调上游拉资产,调 flutterwright 跑设备,迭代到视觉收敛。

## 仓库结构

```
.
├── skills/flutter-visual-loop/SKILL.md    # skill 本体(6 行)
├── docs/superpowers/
│   ├── specs/                              # 设计 spec
│   └── plans/                              # 实施 plan
└── LICENSE
```

## 关联仓库

| 仓库 | 内容 |
|---|---|
| [`flutterwright`](../flutterwright/) | Flutter 设备驱动 skill(规划中) + Dart SDK + 演示 app |
| [`mockplus-context`](~/.claude/skills/mockplus-context) | Mockplus 设计稿抓取 skill |

## 设计文档

- [设计 spec — 2026-05-22](docs/superpowers/specs/2026-05-22-flutter-visual-loop-refocus-design.md):本次聚焦化重构的来龙去脉与契约
- [实施 plan — 2026-05-22](docs/superpowers/plans/2026-05-22-flutter-visual-loop-refocus.md):任务级落地
- [实施 plan — 2026-05-21](docs/superpowers/plans/2026-05-21-flutter-visual-loop.md):重构前的原 monorepo 实施 plan(历史档)

## 许可证

MIT — 见 [`LICENSE`](LICENSE)。
