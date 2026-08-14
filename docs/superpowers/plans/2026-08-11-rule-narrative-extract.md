# plan · 规则文件叙事清理

- **对应 spec**: `~/.claude/docs/superpowers/specs/2026-08-11-rule-narrative-extract.md`
- **日期**: 2026-08-11
- **状态**: 用户明示豁免 brainstorming/writing-plans skill + Plan-Gate 前置;走扩展 L3 兜底
- **实施**: L0 主循环亲自(非代码文档,`[DELEGATION-BAND]` §3 行数带不套)
- **累计行数预估**: 抽走 ~90-120 行叙事;MISTAKES +80-120 行;journal 附录 +100-150 行;净 token 影响 = 每会话 CLAUDE.md 省 ~25-40,ops 单次读时省 20-90

## 任务拆分

### 任务 1 · 清 CLAUDE.md(每会话省最多,先做)

- **依赖**: 无
- **动作**:
  - Read CLAUDE.md 定位每处叙事(前面已 grep 17+ 处)
  - 每处按分类:用户裁定/一次性 → journal 附录;复用型教训 → MISTAKES entry(暂记编号)
  - 用 Edit 精改,只删叙事段,不动规则强制性
- **验收**:
  - CLAUDE.md 行数 232 → ≤210
  - grep "必须|禁止|不得|MUST|不允许" 前后一致
  - grep "20[0-9]{2}-[0-9]{2}-[0-9]{2}|实测|A/B 对照|连撞|某次|某轮|用户裁定" 前后差 ≥17

### 任务 2 · 清 ops/enforcement.md(重灾)

- **依赖**: 无(可与任务 1 并行,但 L0 顺序做,不派子代理)
- **动作**(rev-2 已按 Q6 归宿修正后的实际映射):
  - L51-65 引号感知误拦 → **MISTAKES E014**(rev-2 重排)
  - L67-79 急停实测陷阱 → **MISTAKES E015**(rev-2 重排)
  - L138-141 承诺闸来由 → 就地压缩为规则文字(未搬 journal 附录)
  - L154-158 顺带修复的 bug → 就地压缩为"用户级 hook 必须绝对路径"通用规则
  - L179-201 命令反例误拦裁定过程 → 就地压缩(保留判据 + 处置结论)
- **验收**: enforcement.md 217 → ≤175(实际 182,微超但可接受)

### 任务 3 · 清 ops/plan-gate.md

- **依赖**: 无
- **动作**(rev-2/rev-4 按 Q6 归宿修正后的实际映射):
  - L28-40 A/B 对照表 → 就地压缩为"为什么带此段有效"一句(细节归 journal 附录 A.2)
  - L46 Paper I 双路 → 就地压缩为"两路会独立逮到同一条致命项互为佐证"(细节归附录)
  - L144 guard 交付案例 → **就地删除 E012 指针**(rev-2 修错指针:案例本身**是威胁模型错配**,但 E012 编号是"约定的回声"——嫁接错;规则文本已自包含,删指针即可,不用建新 MISTAKES 条)

### 任务 4 · 清 ops/project-layout.md

- **依赖**: 无
- **动作**(rev-2 已按 Q6 归宿修正后的实际映射):
  - L6 动因(motivation-figure output/outputs 等) → 附录 A.2 归档,规则里保留通用说明
  - L119-124 首次体检 60→11 → 附录 A.2 归档,规则里保留"结构性问题肉眼扫不出"判据
  - L134-140 重构实测(全局 61→22) → 附录 A.2 归档,规则里保留"同一发现地不同笔记性质可能不同"判据
  - **注 rev-3 修 round-2 反馈**:E012/E013 已按 Q6 移 memory(convention-mistaken-for-evidence + codex-report-secondhand-must-verify),MISTAKES 保留 tombstone,plan 相关指针已同步
- **验收**: project-layout.md 150 → ≤140(实际 137,达标)

### 任务 5 · 清 ops/empirical-flow.md + preflight.md 少量

- **依赖**: 无
- **动作**:
  - empirical-flow L6 CLAUDE.md 重构 → journal 附录
  - preflight 若干视具体
- **验收**: 两文件叙事命中 → 0

### 任务 6 · MISTAKES 新增 E010-E015(视抽取过程增减)

- **依赖**: 任务 1-5 抽出的复用型教训明确
- **动作**: 按现有 E001-E009 格式(name/state/触发场景/正确做法/判据),4-6 条
- **验收**: `~/.claude/bin/mistakes` 能列出 E010+;每条 active/未修

### 任务 7 · journal 附录 A 归拢

- **依赖**: 任务 1-5 抽出的一次性叙事明确
- **动作**: 按原位置(文件:行)+ 原日期归档到附录,不改字
- **验收**: 附录 A 条目数 ≥15;每条含"原位置 + 原日期 + 原文"

### 任务 8 · 起【扩展 L3 xhigh】后台跑

- **依赖**: 任务 1-7 全完成(冻结态)
- **动作**:
  - Read `~/.claude/ops/plan-gate.md` 拼命令(不凭记忆)
  - 简报含:用户原话 7 段 + spec 全文 + plan 全文 + 所有改动 diff + 明令覆盖 Plan-Gate 原四维 + 落地正确性 + 跨文件一致性(六维)
  - `codex exec --skip-git-repo-check -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only -C ~/.claude -o .../out.txt -`
  - 走 subagent 或直接 bash 后台
- **验收**: 后台任务已启,GUARD_OFF unset

### 任务 9 · 收口

- **依赖**: 任务 8 回
- **动作**:
  - L3 GO 或 L0 书面裁定放行(留痕)
  - 若 NO-GO 非漂移 → 修 → 冻结态再跑(§2.6)
- **验收**: L3 结论清晰;修法完成

### 任务 10 · 推送

- **依赖**: 任务 9 GO
- **动作**:
  - **PR-GATE 单独问用户**(不推定):A 一次性上位覆盖直推 / B 走 PR + codex 审
  - 若 A → E006 三次调用
  - 若 B → gh pr create → codex 审 → 你合
- **验收**: remote SHA = local HEAD;四闸验通过

## 风险与已知边界

- **E009 代价确认**: 4 rev 3+ L3 已知代价;用户明知选此路径
- **规则强制性守护**: 每次 Edit 抽走都是"只删叙事段"——不动 "必须/禁止/不得"等门槛语义;grep 前后核对
- **抽出教训分类边界**: "急停实测陷阱"这类踩坑教训 = MISTAKES;"A/B 对照""某次决策过程" = journal;拿不准就归 journal(不主动预警好过错误预警)
