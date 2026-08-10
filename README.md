# claude-ops

> Personal Claude Code rule system — 分层协作流水线 · 硬门槛 · 强制执行 · 证据优先
>
> [English README](./README.en.md)

一套让 Claude Code 在做工程与研究任务时不再凭"应该没问题"下结论的规则体系。核心思路一句话:**L0 主循环当大脑,不当手**——只做思考、规划、监督、收口;脏活累活按层级派给更便宜或更对口的模型,最后由 L0 拿证据拍板。

## 这仓库是什么

`~/.claude/` 的**规则本体**,不含运行时数据。

包含 56 个文件,按目录:

| 目录 | 文件数 | 内容 |
|---|---|---|
| `ops/` | 14 | 各硬门槛的细则(唯一事实源,不得凭记忆拼命令) |
| `hooks/` | 13 | 强制执行层(PreToolUse / Stop / SessionStart 等 hook 脚本) |
| `workflows/` | 9 | 工作流脚本(`deep-research.js`、`finding-loop/` Python 模块、`_retired/` 退役件) |
| `docs/` | 8 | `docs/superpowers/{journal,plans,specs}/` 里的历史任务档案(留作范例) |
| `bin/` | 5 | 命令行小工具(`newproj` / `mem-check` / `mistakes` / `l2` / `exp-index`) |
| `agents/` | 1 | 目前只有 `fable-readonly-advisor.md`(Fable5 顾问的 subagent 定义) |
| 顶层 | 6 | `CLAUDE.md`(13 铁律 + 4 章分层)、`README.md` / `README.en.md`、`RTK.md`、`settings.json`、`.gitignore` |

**不包含**:`projects/`(会话数据)、`plugins/`(缓存)、`backups/`、`sessions/`、`tasks/`、机器本地覆写(`settings.local.json`)——这些属运行时数据,永不入库(见 `.gitignore`)。

## 为什么要这么设计

因为一个人在长会话里最容易犯的错是**"感觉做过了 = 真做了"**。这套规则把每个容易翻车的环节都变成**硬门槛**:该审的必须审、该跑的必须跑、跳过就被 hook 拦下。

三个反复踩过的失败模式,规则各有对应答案:

| 失败模式 | 规则对策 |
|---|---|
| **计划错了,后面再严的审也在错地基上盖楼** | Plan-Gate:派活前必过 Codex 异构对抗审 |
| **同源模型看不见自己的盲点** | frontier 审查恒用 Codex `gpt-5.6-sol`(L0 若是 Claude 家族)——不让做全部判断的 L0 给自己背书 |
| **"应该没问题"直接进入结论** | 证据分三级(一手 / 二手 / 零级);Stop hook 拦截"报了数字但没跑过命令"的量词断言 |

## 分层结构

```
L0 大脑(当前会话本体)     ← 思考、拆任务、定验收标准、收口
   ↓ 派活
L1 执行(codex luna / Sonnet 5 / Haiku 4.5)
   ↓ 产出
L2 快审(跨家族粗筛,减负漏斗,非硬门槛)
   ↓
L3 终检(Codex gpt-5.6-sol xhigh,只读)  ← 硬门槛
   ↓
L0 收口(读 L3 → 逐条核验 → 拍板)
```

**Plan-Gate**(sol ultra 单审、四维覆盖)在派活**之前**发生——审的是 spec + plan,不是代码。这是把"异构换视角"前移到最该兜底的地基层。

**Fable 5** 不进入执行/审查分层——它只是 Plan-Gate 架构僵局时的**只读顾问**,窄触发、每次现场征得用户同意。

## 硬门槛清单

| 锚点 | 作用 | 何时触发 |
|---|---|---|
| `[PLAN-GATE]` | spec/plan 派活前必过对抗审 | 任何据以派活的计划性产出 |
| `[OWNERSHIP]` | 意图与 go/no-go 归 L0 | 全程 |
| `[EVIDENCE-FIRST]` | 每层都要验证,证据分三级 | 全程 |
| `[SELF-CONTAINED-BRIEF]` | 委派简报必须自包含 | 每次派 subagent |
| `[DELEGATION-BAND]` | 单次委派实现代码 ≤400 目标线、≤600 硬上限 | 每次派活 / L0 自己动手 |
| `[GRANT-PERMISSIONS]` | 一次给足权限;审查者只读 | 每次调 codex / subagent |
| `[SKILL-PIPELINE]` | 写代码/研究前必先 brainstorming | 任何编码或研究任务 |
| `[PR-GATE]` | GitHub 改动只开 PR、必过 Codex 终检 | 任何要进 GitHub 的改动 |
| `[PRIMARY-SOURCE]` | 联网取材必派 codex,`WebSearch` 摘要禁止当原文 | 任何引用外部资料 |
| `[PLAIN-LANGUAGE]` | 别自创高浓度词汇 | 面向人的输出 |
| `[FABLE-ADVISOR]` | Fable 5 只读顾问,非常规 break-glass | 极窄触发 |
| `[ENGINE-ASSIGNMENT]` | frontier 审查只用 Codex | 全程 |

## 强制执行层(hooks)

规则光写着没用,人会忘。所以规则本身也被脚本兜底:

- 🔴 **PreToolUse 硬拦**:PR 直接合并、推默认分支、审查调用缺 `-s read-only` — 直接失败
- 🟡 **Stop 证据闸**:回复里出现"共 N 处"、"全部通过"、"没有任何"这类量词断言但本回合没跑过任何检索命令 — 打回
- 🟡 **Stop 承诺闸**:回复里出现"我会…"、"稍后补…"这类第一人称未来承诺但本回合没对应动作 — 打回
- **SessionStart / PreCompact / Stop 三个 journal hook**:自动记会话边界事件(所以我不能靠"忘了记"逃避留痕)

急停:`export GUARD_OFF=1`(当次)或 `touch ~/.claude/.guard-off`(持久,但**必须当场声明并用完立即删**)。急停 ≠ 豁免任何硬门槛,只关掉 hook 的提醒层。

## ops 文件是"唯一事实源"

`CLAUDE.md` 只给指针,不复制内容。每个硬门槛的**可跑命令、参数顺序、失败处理、实测踩过的坑**都写在 `ops/<name>.md` 里:

- `ops/plan-gate.md` — Plan-Gate 命令 + agent 类型对照 + L3 拆多路并发实测
- `ops/l2.md` — L2 快审的选档、格式、fail-不阻断细则
- `ops/pr-merge.md` — PR 三闸(head/base 双 OID 绑定 + 工作区纯净)
- `ops/enforcement.md` — guard hook 的自测、加规则、临时关闭
- `ops/preflight.md` — 跑实验/连远程/用 GPU 前的一次性 checklist
- `ops/journal.md` — 七类必记事件、错误档双状态字段
- `ops/line-count.md` — `[DELEGATION-BAND]` 的机械行数复核细则
- `ops/empirical-flow.md` — 实证流(能拆 ≥2 个可比候选时走这条)
- `ops/project-layout.md` — 项目骨架 / slug 命名 / 实验总表口径
- `ops/fable5.md` — Fable5 顾问的四件事记录、现场同意 fail-closed
- `ops/codegraph.md` — 代码定位与影响面分析

**跑硬门槛前先 Read 对应 ops 文件**——凭记忆拼参数会静默失效或被 hook 挡下,这是实测踩出来的。

## 用起来大概长啥样

一次典型的复杂任务:

1. `brainstorming` skill 聊清意图 → 拿到用户认可(HARD-GATE,没认可不写一行代码)
2. `spec` + `plan` skill 拆任务,给验收标准
3. **Plan-Gate**:`codex exec -m gpt-5.6-sol -c model_reasoning_effort="ultra" -s read-only` 四维单审 → NO-GO 就打回改 spec/plan 重审
4. 派 L1(默认 codex luna;强耦合改动 → Sonnet 5;机械批量 → Haiku 4.5),简报自包含 + 显式授权
5. L1 落地(先 `test` 写失败测试 → `build` 小步实现 → `review` 五维自检)
6. **L2 快审**(减负漏斗,非硬门槛)
7. **L3 终检**:`codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only`
8. L0 收口:读 L3 → 逐条核验 → 修或放行 → 拍板 → 冻结态再跑一次终检(移动靶陷阱)
9. 要进 GitHub:`gh pr create` → codex 审 PR head SHA → 由**用户本人**合并

## 谁能用

这套规则是我个人在长任务里踩坑攒出来的,**默认单机使用**——路径写死 `/Users/macbookpro/...`。想跨机复用需要:

1. 用户名不同就全局改路径(或改成 `$HOME`)
2. `settings.json` 里的 token / base URL 是我的私人代理路由,你要换成自己的
3. `Fable 5` / `Codex gpt-5.6-sol / gpt-5.6-luna` 是我本地代理暴露的模型名,你环境里名字可能不一样
4. 本仓库**不含 skill 包**——`CLAUDE.md` 提到的若干 skill(如 `brainstorming`、`autoresearch`、`innovation-hunt`、`oral-review`、Addy 的 agent-skills、superpowers 系列)由 Claude Code 的 plugin marketplace 或独立仓库分发,自行按 `settings.json` 的 `enabledPlugins` 与 `extraKnownMarketplaces` 段获取

## 授权

规则文本部分:任意使用、修改、二次分发,不作任何保证——这是我个人工作流,不是产品。

## 引用

如果这套规则对你有启发,欢迎引用仓库地址:

```
https://github.com/yiyang774/claude-ops
```
