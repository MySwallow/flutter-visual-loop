# flutter-visual-loop Refocus Implementation Plan

> **For agentic workers:** Use the subagent-driven-development skill (recommended) or executing-plans skill to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Refocus `flutter-visual-loop` to a thin orchestration skill (matching `figma-visual-loop`'s minimalist style) by rewriting `SKILL.md`, removing the now-empty `scripts/` directory, and updating two doc references to the migrated `reset_device.sh`.

**Architecture:** Single-skill refactor inside `~/Documents/dev/github/flutter-visual-loop`. The 7 device-driver shell scripts have already been moved (in a prior commit `dc06fc4`) to `~/Documents/dev/github/flutterwright/scripts/`. This plan completes the spec's actions A2–A5; A1 (script migration) is already done.

**Tech Stack:** Bash, Markdown, git. No code execution — purely textual edits + filesystem housekeeping + verification grep.

**Spec reference:** `docs/superpowers/specs/2026-05-22-flutter-visual-loop-refocus-design.md`

---

## File Structure (full list of changes)

```
flutter-visual-loop/
├── skills/flutter-visual-loop/
│   ├── SKILL.md                ← Task 1: rewrite (overwrite full file)
│   └── scripts/                ← Task 2: remove (empty directory)
└── docs/
    ├── e2e-checklist.md        ← Task 3: edit lines 117–121
    └── troubleshooting.md      ← Task 4: edit lines 121–128
```

No new files. No new directories. No `package.json` / `pubspec.yaml` / build config touched.

---

## Task 1: Rewrite SKILL.md to minimalist form

**Files:**
- Modify (overwrite full content): `skills/flutter-visual-loop/SKILL.md`

- [ ] **Step 1: Overwrite SKILL.md with the new minimalist content**

Replace the entire file with exactly this content (frontmatter included):

````markdown
---
name: flutter-visual-loop
description: 自主 Flutter UI → 设计稿 验证循环。给定设计稿 URL(Figma frame 或 Mockplus develop 页)+ 目标 Flutter route,Claude 自己调上游拉资产、调 flutterwright 跑设备、截图视觉对比迭代到收敛(最多 5 轮),不需要你审中间状态。**触发场景**:按 Figma 还原 Flutter 页面、按 Mockplus 还原、Flutter 页面像素对齐;以及 safe-area-inset 反复迭代、按设计稿距离硬抄定位等历史踩坑信号——这些场景**必须**用这个 skill 兜底。
---

Build me an autonomous Flutter visual-loop. Given a design-source URL (Figma frame URL or Mockplus develop URL) and a target Flutter route, the agent should: (1) fetch design data — for Figma call the figma-context MCP, for Mockplus invoke the `mockplus-context` skill via the Skill tool and consume its `<PAGE_DIR>` output, (2) call `flutterwright` to lock device size/density and navigate to the route, (3) call `flutterwright` to capture an on-device screenshot, (4) use vision to compare rendered-vs-design and produce a structured diff report (spacing off by Xpx, color mismatch, missing element, text invisible on background, etc.), (5) apply targeted Dart fixes and hot-reload via `flutterwright`, (6) loop until visual delta is acceptable or 5 iterations hit, (7) always call `flutterwright` reset before exit. Critically: do not transform or re-flatten the upstream design data; if mockplus-context's spec is insufficient that is mockplus-context's bug, not this skill's responsibility.
````

- [ ] **Step 2: Verify SKILL.md meets the spec §8 acceptance criteria**

Run these 4 checks. All must pass:

```bash
cd ~/Documents/dev/github/flutter-visual-loop

# Check 1: ≤20 lines total
wc -l skills/flutter-visual-loop/SKILL.md
# Expected: a number ≤ 20 (the new file is 5 lines).

# Check 2: No bash / adb / scripts/ mentions
grep -E '(\bbash\b|\badb\b|scripts/)' skills/flutter-visual-loop/SKILL.md && echo "FAIL: forbidden tokens found" || echo "OK"
# Expected: "OK"

# Check 3: Only references figma-context / mockplus-context / flutterwright
grep -oE '(figma-context|mockplus-context|flutterwright)' skills/flutter-visual-loop/SKILL.md | sort -u
# Expected (in some order):
#   figma-context
#   flutterwright
#   mockplus-context

# Check 4: Trigger scenarios cover all three categories
grep -E '(Figma|Mockplus|像素对齐)' skills/flutter-visual-loop/SKILL.md
# Expected: at least 3 matches across one or more lines.
```

If any check fails, re-do Step 1 — the content block above is authoritative.

- [ ] **Step 3: Stage changes for user review**

```bash
cd ~/Documents/dev/github/flutter-visual-loop
git add skills/flutter-visual-loop/SKILL.md
```

**Do not commit** — leave for user review at the end.

---

## Task 2: Remove empty scripts/ directory

**Files:**
- Delete (empty directory): `skills/flutter-visual-loop/scripts/`

Background: the 7 scripts were already moved (commit `dc06fc4`). The directory itself is now empty. Git does not track empty directories, so this step has **no effect on `git status`** — it is pure filesystem housekeeping. Inclusion is recommended only because the spec §8 acceptance criterion 5 says the directory should be "不存在 / 为空" (gone or empty).

- [ ] **Step 1: Remove the empty directory**

```bash
cd ~/Documents/dev/github/flutter-visual-loop
rmdir skills/flutter-visual-loop/scripts
```

`rmdir` (not `rm -rf`) intentionally — it will refuse if the directory is not empty, which is a safety check that the move from commit `dc06fc4` actually emptied it.

- [ ] **Step 2: Verify the directory is gone**

```bash
[ ! -d skills/flutter-visual-loop/scripts ] && echo "OK: scripts/ removed" || echo "FAIL: scripts/ still exists"
```

Expected: `OK: scripts/ removed`

- [ ] **Step 3: Nothing to stage**

`git status` should not show any new change from this task. Move on to Task 3.

---

## Task 3: Update docs/e2e-checklist.md reset_device.sh reference

**Files:**
- Modify: `docs/e2e-checklist.md:117-121`

- [ ] **Step 1: Replace the 5-line block referencing the moved script**

Find this exact block (lines 117–121):

```
如果还有 Override,手动跑:

```bash
bash skills/flutter-visual-loop/scripts/reset_device.sh
```
```

Replace it with:

```
如果还有 Override,手动跑(skill 重构后设备 reset 已迁至 flutterwright,这里直接用 adb):

```bash
adb shell wm size reset
adb shell wm density reset
```
```

- [ ] **Step 2: Verify no stale references remain in this file**

```bash
grep -n 'reset_device.sh\|skills/flutter-visual-loop/scripts' docs/e2e-checklist.md && echo "FAIL: stale ref" || echo "OK"
```

Expected: `OK`

- [ ] **Step 3: Stage**

```bash
git add docs/e2e-checklist.md
```

**Do not commit.**

---

## Task 4: Update docs/troubleshooting.md reset_device.sh reference

**Files:**
- Modify: `docs/troubleshooting.md:121-128`

- [ ] **Step 1: Replace the block referencing the moved script**

Find this exact block (lines 121–128):

```
如果你设了 `wm size 1080x2400` 但 `wm density` 还是手机默认值(比如 Pixel 7 的 422dpi),实际 DP 就和预期不符。Skill 会记录原始值并在 `reset_device.sh` 时还原 — 但如果你非正常退出,手动跑一次:

```bash
bash skills/flutter-visual-loop/scripts/reset_device.sh
# 或者
adb shell wm size reset
adb shell wm density reset
```
```

Replace it with:

```
如果你设了 `wm size 1080x2400` 但 `wm density` 还是手机默认值(比如 Pixel 7 的 422dpi),实际 DP 就和预期不符。设备 reset 已迁至 flutterwright skill,这里手动跑 adb 即可:

```bash
adb shell wm size reset
adb shell wm density reset
```
```

- [ ] **Step 2: Verify no stale references remain in this file**

```bash
grep -n 'reset_device.sh\|skills/flutter-visual-loop/scripts' docs/troubleshooting.md && echo "FAIL: stale ref" || echo "OK"
```

Expected: `OK`

- [ ] **Step 3: Stage**

```bash
git add docs/troubleshooting.md
```

**Do not commit.**

---

## Task 5: Final acceptance verification

This task runs the full spec §8 acceptance checklist against the staged state, plus a repo-wide grep to confirm no stale script references remain anywhere except the historical 2026-05-21 plan (which is preserved on purpose as a historical record).

- [ ] **Step 1: Run all 5 acceptance criteria from spec §8**

```bash
cd ~/Documents/dev/github/flutter-visual-loop

echo "--- Criterion 1: SKILL.md ≤20 lines ---"
lines=$(wc -l < skills/flutter-visual-loop/SKILL.md)
[ "$lines" -le 20 ] && echo "OK ($lines lines)" || echo "FAIL ($lines lines)"

echo "--- Criterion 2: SKILL.md contains no bash / adb / scripts/ ---"
grep -E '(\bbash\b|\badb\b|scripts/)' skills/flutter-visual-loop/SKILL.md > /dev/null && echo "FAIL" || echo "OK"

echo "--- Criterion 3: SKILL.md references figma-context, mockplus-context, flutterwright ---"
for tok in figma-context mockplus-context flutterwright; do
  grep -q "$tok" skills/flutter-visual-loop/SKILL.md && echo "  OK: $tok" || echo "  FAIL: $tok missing"
done

echo "--- Criterion 4: Trigger description covers Figma + Mockplus + 像素对齐 ---"
for tok in Figma Mockplus 像素对齐; do
  grep -q "$tok" skills/flutter-visual-loop/SKILL.md && echo "  OK: $tok" || echo "  FAIL: $tok missing"
done

echo "--- Criterion 5: scripts/ directory absent or empty ---"
if [ ! -d skills/flutter-visual-loop/scripts ]; then
  echo "OK: directory absent"
elif [ -z "$(ls -A skills/flutter-visual-loop/scripts)" ]; then
  echo "OK: directory empty"
else
  echo "FAIL: directory has contents"
fi
```

Every line must end in `OK`. If anything reports `FAIL`, return to the relevant earlier task.

- [ ] **Step 2: Repo-wide grep for stale script references**

```bash
cd ~/Documents/dev/github/flutter-visual-loop
grep -rnE 'scripts/(env_check|setup|navigate|capture|hot_reload|mock_set|reset_device)\.sh|skills/flutter-visual-loop/scripts' \
  --include='*.md' --include='*.yaml' --include='*.yml' --include='*.json' \
  --exclude-dir=docs/superpowers \
  .
```

Expected output: empty (no match). The `--exclude-dir=docs/superpowers` deliberately omits the spec (which describes paths intentionally) and the historical 2026-05-21 plan (which is a historical record we do not rewrite).

If any line is printed outside `docs/superpowers/`, **stop and hand back to the user with the grep output**. The plan deliberately does not auto-extend — an unanticipated reference may need a judgment call (e.g., is it a doc that should mention the migration to flutterwright, or a tangential historical mention to leave alone). Do not edit any file the plan has not explicitly listed.

- [ ] **Step 3: Show the staged change summary for the user**

```bash
cd ~/Documents/dev/github/flutter-visual-loop
git status
echo "---"
git diff --cached --stat
```

Expected `git diff --cached --stat` (4 files changed):

```
 docs/e2e-checklist.md                    | <few lines>
 docs/troubleshooting.md                  | <few lines>
 skills/flutter-visual-loop/SKILL.md      | <many lines>
 <maybe nothing for scripts/ — empty dir removal is invisible to git>
```

- [ ] **Step 4: Hand off to user — do not commit**

Print:

> All 4 spec actions (A2 / A3 / A4-as-stage / A5) complete and staged.
> Spec acceptance criteria all passed.
> Review `git diff --cached` then commit with a message such as:
>
> `refactor(skill): refocus flutter-visual-loop to thin orchestrator`
>
> See spec `docs/superpowers/specs/2026-05-22-flutter-visual-loop-refocus-design.md` for rationale.

---

## What this plan deliberately does NOT do

- **Does not implement the `flutterwright` skill.** Out of scope — separate brainstorming → spec → plan cycle.
- **Does not optimize `mockplus-context`.** Out of scope — separate cycle.
- **Does not edit the historical plan `docs/superpowers/plans/2026-05-21-flutter-visual-loop.md`.** It is a frozen historical record of the prior implementation.
- **Does not touch `packages/flutter_visual_loop` (the Dart SDK), `example/`, `README.md`, or `CHANGELOG.md`.** No SDK or example code changes; the README/CHANGELOG can be revised separately once flutterwright lands and the public-facing story is finalized.
- **Does not push** to the remote. Local stage only; user reviews and commits + pushes manually.
