# spec · 规则文件叙事清理

- **日期**: 2026-08-11
- **状态**:
  - 用户明示豁免 §2 第 1 步 brainstorming + writing-plans skill + Plan-Gate 前置(Q5),改由落地后【扩展 L3 xhigh】承接
  - 用户明示 PR-GATE 不推定,推送前单独问
- **发起人**: 用户
- **实施**: L0 主循环亲自(非代码文档,`[DELEGATION-BAND]` §3 行数带不套)

## 1. 背景与动机

`~/.claude/CLAUDE.md` 每次会话自动加载全文(232 行);`~/.claude/ops/*.md` 12 个文件在硬门槛前必读(总 1594 行)。这些文件里塞了大量**叙事内容**:用户裁定注释、实测案例、A/B 对照数据、"某次踩坑过程"。它们每次以输入 token 形式进模型上下文,而**位置错**——按 `ops/journal.md` "七类必记事件"的分工,这些应该在 journal 或 MISTAKES.md 里,不在规则本体。

用户原话点出核心:"用户裁定不应该放在日志吗,写在这里干嘛"、"震慑不重要,规则纯净优先"。

## 2. 变更

### 2.1 CLAUDE.md 抽叙事

**目标**:232 行 → 约 200 行;每会话省 ~25-40 行输入 token

**已识别叙事段(至少 17 处)**:
- L57 豁免代价(Paper I 一段)
- L65 preflight 74 条历史错误(长句)
- L69 冻结态终审(memory 引用)
- L99 子代理自检禁令扫描(2026-08-05 实测)
- L108-115 空输出 / 约定回声(实测 4 撞 + Paper I)
- L116-122 PRIMARY-SOURCE 3 处 codex 报告实测
- L140-141 两轮上限 + 用户裁定简化
- L163-167 §4 Plan-Gate 简化 + luna max 裁定 + 实测漏过两次
- L174-177 Stop 承诺闸来由 + .guard-off 忘删

**抽后目标**: 保留规则本身("必须/禁止"语义),叙事全走归宿;不留反向指针

### 2.2 ops/enforcement.md 抽叙事(~50 行)

- L51-65 引号感知的两次误拦来由 → MISTAKES(复用型:guard 判定的历史踩坑)
- L67-79 急停实测陷阱 `export GUARD_OFF=1 &&` 无效 → MISTAKES(复用型:未来 push/急停任务价值高)
- L138-141 承诺闸来由(实测) → journal 附录(一次性:2026-08-05 那次)
- L154-158 顺带修复的既有 bug → journal 附录
- L179-201 命令反例误拦裁定过程 → journal 附录(2026-08-05 用户裁定选 B)

### 2.3 ops/plan-gate.md 抽叙事(~20 行)

- L28-40 A/B 对照表 → journal 附录(2026-08-05 一次性)
- L46 Paper I 双路 30 条数据 → journal 附录(2026-08-05 一次性)
- L144 guard 交付 L3 错拦案例 → MISTAKES(复用型:威胁模型错配教训)

### 2.4 ops/project-layout.md 抽叙事(~15 行)

- L6 动因(motivation-figure output/outputs) → journal 附录
- L119-124 首次体检 60→11 → journal 附录
- L134 重构 61→3 层实测 → journal 附录

### 2.5 ops/empirical-flow.md + preflight.md 少量

- empirical-flow L6 CLAUDE.md 重构 64 条 → journal 附录
- preflight 若干 → 视具体内容

### 2.6 MISTAKES.md 新增 4-6 条(E010 起)

预计:
- E010 guard 判定必用引号感知分段(不是子串匹配)
- E011 急停 `export GUARD_OFF=1 && cmd` 无效,必用文件式
- E012 codex 简报缺威胁模型 → L3 会把不适用理论风险判成阻断
- E013 忘删 `.guard-off` 致全 guard 静默失效 → selftest 大批 FAIL 先查此文件
- E014? E015? 待抽走时按需

## 3. 验收标准

- [ ] CLAUDE.md 从 232 行降至约 200 行,17+ 处叙事全部抽走
- [ ] ops/enforcement.md 从 217 行降至约 165 行
- [ ] ops/plan-gate.md 从 155 行降至约 135 行
- [ ] ops/project-layout.md 从 150 行降至约 135 行
- [ ] MISTAKES.md 新增 4-6 条 E010-E015(active,格式对齐现有 E001-E009)
- [ ] `docs/superpowers/journal/2026-08-11-rule-narrative-extract.md` 附录 A 收拢所有归 journal 的叙事,按原位置和日期排
- [ ] 规则本体自读一遍:读者不会遇到"某句话缺上下文"
- [ ] 不留反向指针("详见 journal:LXXX")
- [ ] 不改规则强制性(grep "必须|禁止|不得|MUST|不允许" 数量前后一致)
- [ ] 【扩展 L3 xhigh】审通过
- [ ] PR-GATE 时问用户,不推定

## 4. 不做什么(YAGNI)

- **不改** RTK.md(29 行纯 CLI,零叙事)
- **不改** 任何 skill 的 SKILL.md
- **不改** `docs/superpowers/{spec,plan,journal}/` 现有历史档案
- **不改** `settings.json` / `hooks/*` / `bin/*`
- **不新增** ops 文件
- **不重构** 规则结构(章节/13 铁律/锚点数不动)
- **不清理** memory/ 或 MEMORY.md
- **不改** skill 顺序或哪个 skill 归哪(那是上次任务范围)
- **不加** "反向指针" 到抽走处

## 5. 相关

- 用户原话 7 段:见对应 journal `事件 1`
- 相关规则: CLAUDE.md §2/§2.2/§9/`[SKILL-PIPELINE]`/`[PR-GATE]`
- 参考文件: `ops/journal.md`(七类必记事件分工)
- 前一任务 MISTAKES: E009(扩展 L3 兜底效率不如 Plan-Gate 前置)——本次仍走豁免属用户知情选择
