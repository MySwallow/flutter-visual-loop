# flutter-visual-loop 聚焦化重构 · Design Spec

**日期:** 2026-05-22
**范围:** 仅 flutter-visual-loop skill 的职责重定义与 SKILL.md 重写
**范围外:** mockplus-context 优化、flutterwright skill 实现(均为独立后续项目)

---

## 1. 问题陈述

当前 `skills/flutter-visual-loop/SKILL.md`(163 行 + 7 个 shell 脚本)同时承担了:

1. 多种设计稿来源的分发(PNG / PNG 目录 / `.md` spec / Figma URL)
2. 设备驱动逻辑(adb 截图、`wm size/density` lock、热重载 fifo、reset)
3. 设计稿尺寸推导(分辨率查表 + 猜测 density)
4. 视觉对比循环编排
5. Dart 代码修改

这与对标的 `figma-visual-loop`(6 行 SKILL.md,纯编排,数据由 figma-context MCP 直接返回)形成鲜明对比。

**根因:** figma-context MCP 已经吐出 LLM 友好的精简结构化数据,所以 figma-visual-loop 可以极简;而 mockplus-context 当前为了让数据可读,在 skill 内部做了 `to-spec.py` 扁平化转换。flutter-visual-loop 原本想兼容 PNG / `.md` / Figma 多源,自己也兜底了一层。

**结论:** 数据精简的责任**不应在** flutter-visual-loop。它应该跟 figma-visual-loop 对标 — 只做"视觉对比循环编排",数据由上游提供,设备由下层提供。

---

## 2. 三层架构

本次重构把 Flutter 还原生态明确切分为三层:

```
┌─────────────────────────────────────────────────────┐
│ Layer 3 · 视觉对比循环 (skill)                       │
│   Web:     figma-visual-loop                        │
│   Flutter: flutter-visual-loop  ← 本 spec 重构范围   │
│                                                     │
│   职责: 编排上游数据 + 视觉判断 + 改代码 + 调下层     │
└─────────────────────────────────────────────────────┘
         ↓                              ↓
┌──────────────────────┐      ┌──────────────────────┐
│ Layer 2a · 设计稿数据 │      │ Layer 2b · 平台执行   │
│   figma-context MCP  │      │   Web:     Playwright │
│   mockplus-context*  │      │   Flutter: flutterwright** │
│                      │      │                      │
│ 职责: 出干净结构化    │      │ 职责: setup/截图/    │
│ 数据                 │      │      重载/reset       │
└──────────────────────┘      └──────────────────────┘

* mockplus-context 需后续优化对齐 figma MCP 的数据精简水准(独立后续项目)
** flutterwright 是新建的 Flutter 设备驱动 skill,本次 spec 不实现(独立后续项目)
```

**flutter-visual-loop 的全部职责:**

1. 接收"设计稿 URL + 目标 Flutter route"
2. 调用 Layer 2a 拿设计稿数据 + 资产
3. 调用 Layer 2b 完成设备 setup / navigate / capture / hot reload / reset
4. 自己负责: 视觉对比判断 + 修改 Dart 代码 + 编排循环 + 写报告
5. 循环上限 5 轮(硬性,无覆盖)

**flutter-visual-loop 不再做的事:**

- 不再做任何设计稿数据精简/转换
- 不再写任何 adb 命令
- 不再维护分辨率查表 / density 猜测
- 不再接受 PNG / PNG 目录 / `.md` spec 这三种"原始"输入(唯一入口是设计稿 URL)

---

## 3. 设计决策

| # | 决策 | 选择 | 理由 |
|---|---|---|---|
| D1 | 本次 brainstorming 范围 | 只 flutter-visual-loop | mockplus-context 优化作为独立后续项目;两者可并行,flutter-visual-loop 现阶段消费"现状 mockplus-context"产出 |
| D2 | flutter-visual-loop 责任边界 | 与 figma-visual-loop 对标:只做循环编排 | 设备驱动彻底交给新下层 skill `flutterwright` |
| D3 | SKILL.md 风格 | 方案 A 极简描述式(8-12 行) | 跟 figma-visual-loop 风格一致;细节藏在 Claude 推理空间里 |
| D4 | 旧输入分支(PNG / 目录 / .md spec) | 全删 | 精度不够;Figma/Mockplus 双入口足够覆盖 |
| D5 | mockplus-context 调用方式 | 通过 Skill 工具切换到 mockplus-context skill | 责任分明,cookie/401 等错误处理走原生逻辑 |
| D6 | figma-context 调用方式 | 直接调 figma MCP 工具(`mcp__figma-context__*`) | MCP 工具本就为 Claude 设计,无需 skill 切换 |
| D7 | 循环上限 | 保留 5 轮硬上限,不提供覆盖 | 与 figma-visual-loop 一致;Claude 看视觉 delta 自主中止 |
| D8 | 7 个旧 shell 脚本归宿 | 已搬到 `~/Documents/dev/github/flutterwright/scripts/` | 作为 flutterwright skill 后续实现的起点 |
| D9 | 是否产出"图像归一化" spec.md | 不归一化 | figma 用 frame data,mockplus 用 mockplus-context 产出的 spec.md;循环逻辑统一即可,数据载体不必一致 |

---

## 4. 新 SKILL.md(草案)

放在 `~/Documents/dev/github/flutter-visual-loop/skills/flutter-visual-loop/SKILL.md`,完整内容:

```markdown
---
name: flutter-visual-loop
description: 自主 Flutter UI → 设计稿 验证循环。给定设计稿 URL(Figma frame 或 Mockplus develop 页)+ 目标 Flutter route,Claude 自己调上游拉资产、调 flutterwright 跑设备、截图视觉对比迭代到收敛(最多 5 轮),不需要你审中间状态。**触发场景**:按 Figma 还原 Flutter 页面、按 Mockplus 还原、Flutter 页面像素对齐;以及 safe-area-inset 反复迭代、按设计稿距离硬抄定位等历史踩坑信号——这些场景**必须**用这个 skill 兜底。
---

Build me an autonomous Flutter visual-loop. Given a design-source URL (Figma frame URL or Mockplus develop URL) and a target Flutter route, the agent should: (1) fetch design data — for Figma call the figma-context MCP, for Mockplus invoke the `mockplus-context` skill via the Skill tool and consume its `<PAGE_DIR>` output, (2) call `flutterwright` to lock device size/density and navigate to the route, (3) call `flutterwright` to capture an on-device screenshot, (4) use vision to compare rendered-vs-design and produce a structured diff report (spacing off by Xpx, color mismatch, missing element, text invisible on background, etc.), (5) apply targeted Dart fixes and hot-reload via `flutterwright`, (6) loop until visual delta is acceptable or 5 iterations hit, (7) always call `flutterwright` reset before exit. Critically: do not transform or re-flatten the upstream design data; if mockplus-context's spec is insufficient that is mockplus-context's bug, not this skill's responsibility.
```

**与现状的对比:**

| 维度 | 现状(163 行) | 新版(~12 行) |
|---|---|---|
| 输入种类 | 4 种 | 2 种 (Figma URL / Mockplus URL) |
| 设备脚本调用 | 7 个内嵌 shell 脚本 | 委托给 flutterwright |
| 分辨率推导 | sips + 8 行查表 | 委托给 flutterwright + 上游数据 |
| Spec 提案模板 | 有 | 删(数据由上游给) |
| 失败模式表 | 有(7 行) | 删(归 flutterwright) |
| 循环模板 | 有 | 删(口述即可) |
| 总长 | 163 行 + 7 脚本 | ~12 行,0 脚本 |

---

## 5. 数据流(实际运行时)

```
                  Figma URL                            Mockplus URL
                       │                                    │
                       ↓                                    ↓
         ┌─────────────────────────┐         ┌──────────────────────────┐
         │ figma-context MCP        │         │ mockplus-context skill   │
         │ (Claude 直接调 MCP 工具) │         │ (通过 Skill 工具切换)     │
         │ - get_figma_data         │         │ 产出 <PAGE_DIR>/{        │
         │ - download_figma_images  │         │   spec.md,design.png,    │
         │ → frame JSON + assets    │         │   assets/ }              │
         └─────────────────────────┘         └──────────────────────────┘
                       │                                    │
                       └──────────────┬─────────────────────┘
                                      ↓
                       flutter-visual-loop:
                       - 读视觉锚定(design.png 或 figma 渲染)
                       - 读结构化参考(spec.md 或 frame JSON)
                       - 推断尺寸/density 透传给 flutterwright
                       - 改 Dart 代码
                                      ↓
                       ┌──────────────────────────────────┐
                       │ flutterwright(本 spec 范围外)    │
                       │ 提供 6 个隐含能力 — 见 §6        │
                       └──────────────────────────────────┘
                                      ↓
                       循环 ≤5 轮,Claude 看视觉 delta 决定中止
                                      ↓
                       reset_device + report.md
```

---

## 6. 对 flutterwright 的隐含接口契约

flutter-visual-loop 的新 SKILL.md 隐含地要求 flutterwright 提供以下能力。**本 spec 不展开 flutterwright 的实现细节**,但记录这份契约,供后续 flutterwright brainstorming 直接引用。

| 能力 | 输入 | 输出 / 副作用 | 当前对应脚本 |
|---|---|---|---|
| `setup` | 画板宽 / 高 / density | 锁定设备 `wm size` + `wm density`;`flutter_visual_loop` SDK 心跳确认 | `setup.sh` + `env_check.sh` |
| `navigate` | route 名 + 可选 args JSON | 通过 SDK HTTP API 跳路由 | `navigate.sh` |
| `capture` | 输出 PNG 路径 | adb 截图到指定路径 | `capture.sh` |
| `hot_reload` | (无) | 触发 Flutter 热重载 | `hot_reload.sh` |
| `mock_set` | 键 + JSON 值 | 注入 mock 数据 | `mock_set.sh` |
| `reset_device` | (无) | 恢复 `wm size/density` 默认值 | `reset_device.sh` |

**约定:**

- 调用方式由 flutterwright 自己决定(MCP / shell / 其他)
- flutter-visual-loop 不感知具体协议,只表达"需要这些操作"
- 失败模式(SDK 不可达、Navigator 503、截图全黑等)由 flutterwright 自己处理并给出可读错误

---

## 7. 实施动作清单

按以下顺序执行(实施阶段由 writing-plans → executing-plans 完成):

- [x] **A1.** 把 `~/Documents/dev/github/flutter-visual-loop/skills/flutter-visual-loop/scripts/` 的 7 个脚本搬到 `~/Documents/dev/github/flutterwright/scripts/`(本 brainstorming 阶段已完成)
- [ ] **A2.** 重写 `~/Documents/dev/github/flutter-visual-loop/skills/flutter-visual-loop/SKILL.md` 为 §4 草案
- [ ] **A3.** 删除空目录 `~/Documents/dev/github/flutter-visual-loop/skills/flutter-visual-loop/scripts/`(可选,git 不跟踪空目录)
- [ ] **A4.** 在 flutter-visual-loop 仓库执行 `git add -A` + commit,记录脚本搬迁与 SKILL.md 重写
- [ ] **A5.** 复核 `README.md` / `CHANGELOG.md` / `docs/`:看是否有"skill 里有 setup.sh"之类的描述指向已搬走的脚本。有则更新或加引导句指向 flutterwright;没有则不动。

**不在本次范围内:**

- flutterwright skill 的实现(`SKILL.md` + 任何重组/重写脚本) — 独立后续项目
- mockplus-context 输出精简化 — 独立后续项目
- `packages/flutter_visual_loop` Dart SDK 不动
- `example/` Flutter app 不动

---

## 8. 验收标准

新 SKILL.md 落地后,验证以下断言:

1. SKILL.md 总行数 ≤20 行(对标 figma-visual-loop 的 ~6 行)
2. SKILL.md 内不包含任何 `bash`、`adb`、`scripts/` 字样
3. SKILL.md 内提到的所有外部依赖只有: figma-context MCP、mockplus-context skill、flutterwright(未来)
4. 触发场景描述至少覆盖: Figma URL、Mockplus URL、像素对齐回归三类
5. `skills/flutter-visual-loop/scripts/` 在新 commit 后不存在 / 为空

---

## 9. 后续项目衔接

**flutterwright(下一轮 brainstorming):**

- 基础物料:`~/Documents/dev/github/flutterwright/scripts/` 里的 7 个脚本
- 接口契约: 本 spec §6 已列出
- 重要决策待定: 是包装成 MCP server,还是保持 skill + shell 脚本形态

**mockplus-context 优化(独立 brainstorming):**

- 目标:让 mockplus-context 的产出直接可读,无需 `to-spec.py` 扁平化(对齐 figma MCP)
- 路径选项: 把 to-spec 逻辑做成 MCP server 内嵌 / 改造 to-spec.py 让输出格式靠近 figma frame data / 不动 spec.md 但优化字段密度
- 不影响 flutter-visual-loop 现版本 — flutter-visual-loop 直接消费 mockplus-context 的产出,无论是 spec.md 还是更精简的格式
