# flutter-visual-loop

Claude Code skill,自主驱动 Flutter UI 视觉对比循环 —— 给定设计稿 URL + 目标路由,Claude 自己拉资产、跑设备、视觉比对、改 Dart 代码、热重载,迭代到收敛。

## 目的

把"按设计稿还原 Flutter UI"这件事自动化。手工拉切图、量距离、改组件、热重载、再对比这套循环,Claude 自己跑,最多 5 轮。结束自动恢复设备状态。

## 依赖的 skill / MCP

| 依赖 | 层级 | 角色 | 仓库 / 下载地址 |
|---|---|---|---|
| `figma-context` MCP | 上游 | 输入是 Figma frame URL 时,拉 frame data + 切图 | 任一兼容 Figma MCP 实现(自行配置) |
| `mockplus-context` skill | 上游 | 输入是 Mockplus develop **page** URL 时,产出结构化 JSON(metadata + globalVars + nodes)+ 下载切图到指定目录 | <https://github.com/MySwallow/mockplus-context> |
| `flutter-wright` skill | 下层 | 驱动 Flutter Android 设备(run / stop / health / goto / screenshot / reload / setViewport / resetViewport / reset) | <https://github.com/MySwallow/flutterwright> |

**上游二选一**:设计稿是 Figma → 只需要 `figma-context` MCP,**不**需要 mockplus-context;设计稿是 Mockplus(摹刻) → 只需要 `mockplus-context` skill,**不**需要 Figma MCP。下游 `flutter-wright` skill 任何场景都必需。三者均已就绪,端到端可跑。

## 怎么用

在一个集成了 `flutter_wright_sdk` 的 Flutter 项目里(程序化 `goto` 导航需要它,见 [flutterwright 仓库](https://github.com/MySwallow/flutterwright)),接上 Android 设备或模拟器,跟 Claude 说:

> 按这个 Figma frame 还原 `/order/detail` 页面:
> https://www.figma.com/...

或者:

> 按这个 Mockplus 页面还原 `/cart` 页面:
> https://app.mockplus.cn/app/.../develop/design/...

Claude 自己识别 URL 类型,调上游拉资产,用 flutter-wright `run` 起 app、`goto` 到目标页、截图视觉比对、改 Dart `reload`,迭代到收敛,结束 `reset` + `stop` 清理设备。

## 两种入口:Skill vs Command

本仓库同时提供两种触发方式,指令体一致,差别只在**谁来触发**:

| | `skills/flutter-visual-loop/SKILL.md` | `commands/flutter-visual-loop.md` |
|---|---|---|
| 触发方 | **模型自动判断**(model-invoked):Claude 读 `description`,命中"按 Figma/Mockplus 还原 Flutter 页面"等场景就自动唤起 | **只有你显式打** `/flutter-visual-loop ...`,模型不会自动调 |
| `description` 的作用 | 触发信号——写得越像场景,越容易被自动调起 | 仅作 `/` 菜单里的说明文字 |
| 接收输入 | 从对话上下文里自己识别 URL + route | 通过 `argument-hint` 提示,正文用 `$ARGUMENTS` 接收 |
| 适合 | 希望"提到还原就自动兜底" | 希望**只在我明确要求时**才跑这套重流程 |

> 注:即使在 SKILL 的 `description` 里写"手动触发不自动",那也只是软约束,模型仍可能自动调起。要**硬保证只显式触发**,slash command 是唯一干净的办法。
>
> 两份文件的编排指令保持一致——**改一处记得同步另一处**。

**在 Codex 用**:Codex CLI 支持 custom prompts,把命令文件复制到 `~/.codex/prompts/flutter-visual-loop.md`,即可在 Codex 里用 `/flutter-visual-loop` 显式触发。但注意本 skill 是"瘦编排器",真正干活靠下面三个依赖——命令文件只搬指令文本,**不会把依赖带过去**;要在 Codex 端到端跑通,需在 Codex 侧另行配好 figma-context MCP、`mockplus-context` 与 `flutter-wright` 两个 skill。

## 仓库结构

```
.
├── skills/flutter-visual-loop/SKILL.md     # skill 本体(自动触发,6 行)
├── commands/flutter-visual-loop.md         # 同一编排的手动命令源文件(复制到 .claude/commands/ 即可 /flutter-visual-loop)
├── docs/superpowers/
│   ├── specs/                              # 设计 spec
│   └── plans/                              # 实施 plan
└── LICENSE
```

## 关联仓库

| 仓库 | 内容 |
|---|---|
| [MySwallow/flutterwright](https://github.com/MySwallow/flutterwright) | `flutter-wright` skill + `flutter_wright_sdk` Dart SDK + 演示 app |
| [MySwallow/mockplus-context](https://github.com/MySwallow/mockplus-context) | `mockplus-context` skill |

## 设计文档

- [设计 spec — 2026-05-22](docs/superpowers/specs/2026-05-22-flutter-visual-loop-refocus-design.md):本次聚焦化重构的来龙去脉与契约
- [实施 plan — 2026-05-22](docs/superpowers/plans/2026-05-22-flutter-visual-loop-refocus.md):任务级落地
- [实施 plan — 2026-05-21](docs/superpowers/plans/2026-05-21-flutter-visual-loop.md):重构前的原 monorepo 实施 plan(历史档)

## 许可证

MIT — 见 [`LICENSE`](LICENSE)。
