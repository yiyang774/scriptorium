# spec · 分歧清单形成后无条件 interview-me

- **日期**: 2026-08-11
- **状态**:
  - **本文件为 rev-4**(已吸收 L3 round-1/2/3 全部 15+ 项意见 + 用户 4 轮拍板)
  - 已由用户明示豁免 Plan-Gate,改由落地后【扩展 L3】承接(CLAUDE.md §2.2 三件事之 ①)
  - 用户 2026-08-11 明示**一次性上位覆盖** `[PR-GATE]`(仅限本次推送;规则内不存在豁免路径)
  - 用户 2026-08-11 拍板"skill 顺序采纳 L3 建议"、"继续修 rev-3 + round-3"、"继续修 rev-4 + round-4"
- **发起人**: 用户
- **实施**: L0 主循环亲自(非代码文档,`[DELEGATION-BAND]` §3 行数带不套)

## 1. 背景与动机

当前流水线在**分歧清单形成**到**写 spec/plan**之间是一步跳:L0 拿到分歧清单后就自行选/合成、下笔写 spec/plan。实测踩过的坑:

- 分歧清单里最贵的那类是"**选哪条其实是用户偏好,不是数据问题**"——L0 自作主张选一条,后面 Plan-Gate/L3 才逮到"方向不合",返工代价比一开始就问用户高得多
- L0 自己判"有没有歧义"本身就可能是错的——"我以为自己听懂了"是最典型的漏网口
- 主观触发阀(如"若歧义显著才问")必被拿来自我豁免,和 `[PLAN-GATE]` 判据只用机械项("产出是否会成为派活依据")是同一路道理

## 2. 变更(rev-4:已吸收 L3 round-1/2/3 全部意见)

### 2.1 实证流 `ops/empirical-flow.md` §2⑦ 拆分

**从**: `### ⑦ L0 定案(决策不外包)`

**改为**:

- **⑦A · L0 核数据 + 形成分歧清单**(原第 1、2 要点保留不动)
- **⑦B · 强制 `interview-me` 意图对齐**(**本次新增**,只固化偏好、不作技术选择)
  - **触发**: 无条件——⑦A 完成即触发,不看清单条目多少、不看 L0 主观感觉"有没有歧义"
  - **前提·必须有活跃用户**: `interview-me` 是交互式 skill,禁在 subagent / CI / loop 等非交互上下文调用。**长实验结束时用户可能已离开** —— 若发起 ⑦B 时无活跃用户,**暂停,待用户回来再继续**,不得替用户走完 interview
  - **形态**: invoke `agent-skills:interview-me` skill,把分歧清单作为完整上下文喂入,一问一答直到 ~95% 意图对齐;鼓励发散多个可行方向、把偏好/权衡/边界摆到台面上
  - **skill 契约覆盖**: `interview-me` 默认 "When NOT" 禁在"无歧义 / 机械操作 / 已有 ≥95% 把握"时调用,且其默认输出是"用户明确确认的意图陈述"而非技术方案。**本节明写覆盖**——⑦B 无条件触发、额外要求附一个"处置意向"(见下)。技术选择仍归 ⑦C。
  - **产出**(两块,缺一不可):
    - 一份**用户确认的意图/偏好/非目标**(`interview-me` 默认输出,属"意图陈述")
    - 一个**处置意向**(五种之一,L0 与用户共同拟定;具体分支执行在 ⑦C):
      - 选其一 —— 从分歧清单挑一个候选
      - 合成 —— 融合多个候选
      - 全部不选后新做 —— 分歧清单里的都不合意图,需要新候选
      - 停止 —— 数据/意图都不支持任何候选,本任务应暂停或回退
      - 补测 —— 现有证据不足以定,必须回 ①/③/⑤ 补跑再来
  - **收敛失败**: 数轮不收敛按 `interview-me` 内规("三轮以上信心不提升"红旗)**暂停并报告 blocker**
- **⑦C · 按 ⑦B 处置意向分支执行**(唯一决定谁进 ⑧,rev-3/rev-4 定形):
  - 六行分支表: 选其一 / 合成 / 全部不选后新做 / 停止 / 补测 / **意向与数据不一致(回边)**
  - 只有"选其一(数据一致)/ 合成(已测)"才写 spec/plan 进 ⑧;其他各自出口
  - **数据不一致回边**(rev-4 新增,修 L3 round-3 #4):选其一/合成的候选若与 ⑦A 数据不一致,不得静默覆盖用户或卡死——**回 ⑦B 重新过一遍 interview**
  - **不允许"停止/补测/新做/回边"绕道进 ⑧**

### 2.2 标准流水线 `CLAUDE.md` §2 第 1 步 完全重写(顺序颠倒)

**从**: `1. brainstorming(HARD-GATE) → plan/spec`

**改为**:

- **适用范围**: 本步只适用于 **L0 / 活跃用户上下文**;L1 子代理只消费已批准的 intent/spec/plan
- **第一步 → 无条件 invoke `agent-skills:interview-me`**:探意图/偏好/非目标(skill 契约覆盖同 ⑦B)
- **第二步 → `brainstorming` skill**:依 interview 结果聊到候选方案并取得认可(HARD-GATE:没出设计、没拿到认可不写代码;终态按 skill 契约后接 writing-plans)
- **第三步 → `writing-plans`**(按 brainstorming 唯一后继契约;**不用 `agent-skills:plan/spec` 替代**——brainstorming 已在自身内部产出 spec,替代 skill 会重复生成或覆盖)
- **收敛失败**: 同 ⑦B

### 2.3 铁律 10 `[SKILL-PIPELINE]` 拆规划段/执行段

- **规划段(仅 L0/活跃用户)**: interview-me → brainstorming → writing-plans
- **执行段(可派子代理)**: **test/TDD → build → review → ship**(注意顺序:TDD 是"先失败测试后实现",不得倒置)
- **规划段的两个交互式 skill 只适用于 L0/活跃用户上下文**——子代理不重复调用

### 2.4 Plan-Gate 输入契约同步(rev-4 新增,修 L3 round-3 #3)

`ops/plan-gate.md` 加 `intent.txt`(interview 后用户确认的意图/裁定)为必带输入。简报语言含**初始原话 + 用户确认的最终意图**,**两者冲突时以最新明确确认为解释来源**;初始原话仅用于核查演变是否有依据。

### 2.5 README 同步

两份 README 五处同步:
- 实证流概览拆 ⑦A/⑦B/⑦C
- 硬门槛表 `[SKILL-PIPELINE]` 规划段/执行段描述
- 典型流程 1-10 编号(interview-me → brainstorming → writing-plans → Plan-Gate → L1 → 执行段 → L2 → L3 → 冻结态 → PR)
- skill 清单加 `interview-me`
- **健康检查显式列 `interview-me`**(rev-4 新增,修 L3 round-3 #5)

### 2.6 PR-GATE 一次性上位覆盖(rev-2 新增 + rev-3 措辞纠正)

`[PR-GATE]` 与 `ops/pr-merge.md` 都写"无一例外",**规则内不存在 PR-GATE 豁免路径**。本次动作合法性来自"**用户对本任务的一次性上位指令覆盖绝对规则**",仅限本次推送。不得声称"依 PR-GATE 豁免路径合规",也不得据此对全局 `[PR-GATE]` 新增普遍豁免。将来任何直推 main 都须重新明示、独立留痕。

推送姿势: E006 三次独立 Bash 调用(touch → trap+push → 核验)。

### 2.7 journal 位置 + 状态字段(rev-4 新增)

- 本任务正式 journal: `~/.claude/docs/superpowers/journal/2026-08-11-interview-after-divergence.md`(slug 对齐 spec/plan)
- 旧位置 `~/.claude/projects/-Users-macbookpro/journal/2026-08-10-git-init-claude-rules.md` 只留历史指针
- 头部快照按 `ops/journal.md` "每次覆写"契约刷新到当前状态,事件流"只追加、绝不改写历史"

## 3. 验收标准(rev-4)

- [ ] `ops/empirical-flow.md` §2⑦ 拆成 ⑦A/⑦B/⑦C,⑦B 5 种处置意向 + 数据不一致回边全在
- [ ] `CLAUDE.md` §2 第 1 步先 interview → 后 brainstorming → **只接 writing-plans**(不接替代 skill)
- [ ] `CLAUDE.md` 铁律 10 执行段顺序为 **test/TDD → build → review → ship**
- [ ] `ops/plan-gate.md` 加 `intent.txt` 必带输入 + 简报语言含初始原话+最终确认
- [ ] `ops/empirical-flow.md` ⑦B 前提: "长实验结束用户已离开则暂停"
- [ ] `ops/empirical-flow.md` ⑦C: 六行分支表(五种处置 + 数据不一致回边)
- [ ] `README.md` + `README.en.md` 六处同步:实证流 / 硬门槛表 / 典型流程 1-10 / skill 清单 / 健康检查列 interview-me / ⑦C 引用
- [ ] journal 头部快照按 ops/journal.md 覆写到 rev-4 状态,事件流追加事件 9-11
- [ ] 【扩展 L3 xhigh】round-4 终检通过(冻结态)
- [ ] 用户一次性上位覆盖 PR-GATE 后 → E006 推送 → journal 收尾

## 4. 不做什么(YAGNI)

- **不改** `interview-me` / `brainstorming` / `writing-plans` skill 本身(动别人写的 skill 且 plugin cache 会被升级覆盖)
- **不为** interview-me 加进度指标(问题数 / 轮数 / 收敛度)——skill 内部机制
- **不加** 新 ops 文件——现有文件够放
- **不改** `[PLAN-GATE]` `[SKILL-PIPELINE]` 等硬门槛本身的强制性——只调整触发前的顺序与输入

## 5. 相关

- **用户原话(3 轮共 9 段,逐字)**:

  【轮 1 · 4 决策 + 修正 + 豁免 Plan-Gate】
  1. "我觉得在L0 亲自核原始数据 → 形成分歧清单 → 写 spec/plan,形成分歧清单之后要加上一个Ask question的环节,让模型头脑风暴去问问题,可以准备很多问题,可以递进式的提问"
  2. "每次形成分歧清单后都跑,全走 interview-me 一问一答,宁可慢一点,也要尽可能激发用户和模型的想象力,获得更多可行方案,之后形成方案在过Plan-Gate,标准流水线也可以加上这个"
  3. "无论有没有关键歧义,都要问问题"
  4. "确认,直接修改"
  5. AskUserQuestion Q1 拍板路径: 选 A "豁免 Plan-Gate,走扩展 L3 兜底"

  【轮 2 · L3 round-1 后 2 项拍板】
  6. skill 顺序 Q2A: 选 "采纳 L3 建议:先 interview → 后 brainstorming"
  7. PR-GATE Q2B: 选 "同款 main 直推豁免"(呼应前 8 次推送)

  【轮 3 · L3 round-2 后 1 项拍板】
  8. Q3(收口方向): 选 "继续修 5 项 + round-3"

  【轮 4 · L3 round-3 后 1 项拍板】
  9. Q4(收口方向): 选 "继续修 5 项 + round-4"

- **相关 skill**: `agent-skills:interview-me`, `superpowers:brainstorming`, `superpowers:writing-plans`, `agent-skills:spec`, `agent-skills:plan`
- **相关规则**: CLAUDE.md §2/§9/`[PLAN-GATE]`/`[SKILL-PIPELINE]`/`[PR-GATE]`
- **L3 报告**: round-1 `.../l3-2026-08-11-interview/out.txt`;round-2 `.../round2/out.txt`;round-3 `.../round3/out.txt`
