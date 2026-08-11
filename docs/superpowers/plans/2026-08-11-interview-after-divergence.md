# plan · 分歧清单形成后无条件 interview-me

- **对应 spec**: `~/.claude/docs/superpowers/specs/2026-08-11-interview-after-divergence.md`
- **日期**: 2026-08-11
- **状态**:
  - **本文件为 rev-4**(已吸收 L3 round-1/2/3 全部意见 + 用户 4 轮拍板)
  - 豁免 Plan-Gate,改由扩展 L3 承接(CLAUDE.md §2.2 三件事)
  - 用户一次性上位覆盖 `[PR-GATE]`(仅限本次推送;规则内无豁免路径)
- **实施**: L0 主循环亲自(非代码文档,`[DELEGATION-BAND]` §3 行数带不套;L0 通读得动)
- **累计行数**: rev-1 至 rev-4 全部改动,两文件 CLAUDE.md + ops/empirical-flow.md 共 ~190 行、README 双语共 ~80 行、ops/plan-gate.md 6 行、加 3 个新文件(spec/plan/journal)

## 任务拆分(rev-4 全景)

### 已完成 · rev-1 至 rev-3

- ✅ 起 spec + plan rev-1(旧位置 journal 事件 #9 起头)
- ✅ 改 `ops/empirical-flow.md` §2⑦ 拆 ⑦A/⑦B/⑦C(rev-1 版)
- ✅ 改 `CLAUDE.md` §2 第 1 步补 interview-me 节点(rev-1 版:旧顺序 brainstorming → interview)
- ✅ 起【扩展 L3 xhigh】round-1 → NO-GO(4 项致命)
- ✅ rev-2 修法(修 round-1 4 项 + 用户 Q1/Q2 拍板):迁 journal / ⑦B 5 处置 / skill 顺序颠倒 / PR-GATE 豁免留痕
- ✅ L3 round-2 → NO-GO(5 项致命,审查者标注"整体未漂移")
- ✅ 用户 Q3 拍板:继续修 5 项 + round-3
- ✅ rev-3 修法(修 round-2 5 项):⑦B/⑦C 分支控制流 / 子代理适用性 / README 5 处 / PR-GATE 措辞纠正 / journal 快照刷新
- ✅ L3 round-3 → NO-GO(5 项必修,审查者明确"未漂移")
- ✅ 用户 Q4 拍板:继续修 5 项 + round-4

### 已完成 · rev-4 修法(修 round-3 5 项)

- ✅ **修 #2**: CLAUDE.md §2 第 1 步第三步只保留 `writing-plans`;铁律 10 执行段改 test/TDD → build → review → ship
- ✅ **修 #3**: `ops/plan-gate.md` 加 `intent.txt` 必带输入,简报语言含初始原话+最终确认
- ✅ **修 #4**: `ops/empirical-flow.md` ⑦C 加"意向与数据不一致→回 ⑦B"回边;⑦B 前提改"用户离开则暂停"
- ✅ **修 #5**: 两份 README 健康检查显式列 `interview-me`;典型流程编号重排为 1-10
- ✅ **修 #1**: spec/plan 全文刷新到 rev-4(反映 rev-4 状态 + 3 轮 9 段原话 + 六行分支表)

### 待办 · 收口阶段

- [ ] **冻结态 L3 round-4**(§2.6 硬要求;简报要说明 rev-4 已修 round-3 全部 5 项 + 顺手修 2 非致命)
- [ ] **收口**:L3 round-4 GO 或 L0 书面裁定放行 → E006 三次调用推送(用户已一次性上位覆盖 PR-GATE)→ journal 事件流补收尾事件 + MISTAKES 回填 3 条(EVIDENCE-FIRST / PRIMARY-SOURCE / journal 位置)

## 修 #4 详解:PR-GATE 一次性上位覆盖(rev-2 新增 + rev-3 措辞纠正 + rev-4 保留)

用户 2026-08-11 明示: **同款 main 直推**(呼应前 8 次推送)。

**性质澄清**:`[PR-GATE]` 与 `ops/pr-merge.md` 都明写"无一例外",guard 急停也明说"急停 ≠ 豁免 PR-GATE"——**规则内不存在 PR-GATE 豁免路径**。本次动作的合法性来自"**用户对本任务的一次性上位指令覆盖绝对规则**",仅限本次推送。不得声称"依 PR-GATE 豁免路径合规";也不得据此对全局 `[PR-GATE]` 新增普遍豁免。将来任何直推 main 都须重新明示、独立留痕。

推送姿势(严格三次独立 Bash 调用,E006 已知缺口):
1. `touch ~/.claude/.guard-off`(独立调用)
2. `trap 'rm -f ~/.claude/.guard-off' EXIT INT TERM; git push origin main`(独立调用)
3. `ls -la ~/.claude/.guard-off; echo GUARD_OFF: ${GUARD_OFF:-unset}; git log & status`(独立调用,验四闸)

## 验收(rev-4 最终态)

- [ ] `ops/empirical-flow.md` grep 校验:
  - `grep -c "⑦B" ops/empirical-flow.md` ≥ 5
  - `grep -c "回 ⑦B\|回边" ops/empirical-flow.md` ≥ 2(数据不一致回边)
  - `grep -c "选其一\|合成\|全部不选\|停止\|补测" ops/empirical-flow.md` 覆盖全五种
- [ ] `CLAUDE.md` grep 校验:
  - `grep -c "writing-plans" CLAUDE.md` §2 第 1 步和铁律 10 各一处;**不含 "agent-skills:plan/spec" 作为替代路径**
  - `grep -c "test/TDD → build\|test → build" CLAUDE.md` 铁律 10 执行段
- [ ] `ops/plan-gate.md`: `grep -c "intent.txt" ops/plan-gate.md` ≥ 2(需要一处必带检查、一处 printf)
- [ ] `README.md` / `README.en.md` 健康检查行含 `interview-me`;典型流程编号 1-10
- [ ] `journal/2026-08-11-...md` 头部快照 5 字段齐全反映 rev-4;事件流有事件 9-11
- [ ] L3 round-4 GO,或 L0 书面裁定放行(留痕)
- [ ] 推送落地,四闸验通过

## MISTAKES 回填清单(收口时做)

3 条本次坐实的项目错误(未来派活前必扫):

1. **规则文件涉及 skill 调用时,必须先 Read 那些 skill 的 SKILL.md 原文**——违反 `[PRIMARY-SOURCE]`+`[EVIDENCE-FIRST]`;L3 round-1 #2、round-2 #2、round-3 #2 三轮都是同类问题
2. **journal 追加位置必须先 Read `ops/journal.md`**——不能沿用 hook 兜底位置;L3 round-1 #3 逮出
3. **规则文件变更类任务的扩展 L3 承接效率不如 Plan-Gate 前置**——本次 3 轮 L3 + 4 版 rev 才收干净;后续同类任务优先走 Plan-Gate,不走豁免

## 风险与已知边界

- **rev-3 → rev-4 增量修改**:spec/plan 全文重写,ops/CLAUDE.md/README 精改;若 L3 round-4 仍逮真问题,考虑是否需要"分批推送+后续 rev-5"的新策略
- **扩展 L3 打折价再次坐实**:本次 4 rev 3 L3 = "补丁式修法" vs Plan-Gate 前置一次审能拦大部分;未来规则改进类任务默认走 Plan-Gate 前置
- **skill 目录被 plugin cache 覆盖**:本次不改 skill 本体,只在规则层写覆盖依据——升级 skill 目录时本文件不受影响
