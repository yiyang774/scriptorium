# Scriptorium

> 一套 Claude Code 的规约体系 —— L0 派活 · L1 执行 · L2 快审 · L3 终检;逐层背书,字字有据
> 
> 可以依据此规则修改 Codex （AGENT.md）
>
> [English README](./README.en.md)

一套让 Claude Code 在做工程与研究任务时不再凭"应该没问题"下结论的规则体系。核心思路一句话:**L0 主循环当大脑,不当手**——只做思考、规划、监督、收口; 脏活累活按层级派给更便宜或更对口的模型,最后由 L0 拿证据拍板。

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

## 怎么装

⚠️ **先读"[谁能用](#谁能用)"节**——这套规则默认单机单用户、路径写死 `/Users/macbookpro/...`、`settings.json` 里带我个人的代理 token 与本地代理暴露的模型名(`gpt-5.6-sol` / `gpt-5.6-luna` / `claude-fable-5` 等)。**你不会开箱即用**,需要按下面步骤替换。

### 一、前置

必须装好:

- **Claude Code**(CLI 本体)——本机 `claude` 命令可用
- **git**、**bash**(macOS 自带 3.2 够用,但 Plan-Gate 脚本已按 3.2 兼容写)、**python3**(hook 里用)

按需装好(缺哪个对应功能就用不了):

- **`codex` CLI**——Plan-Gate、L3 终检、`[PRIMARY-SOURCE]` 原文取材都要它;没有的话 frontier 审查这一层直接坍掉
- **`gh` CLI**——`[PR-GATE]` 走 `gh pr create` / `gh pr merge`;没有就只能手工开 PR
- **`codegraph` CLI**——`impact` / `callers` / `callees` 三个命令(MCP 只暴露 `explore`);见"代码定位与影响面"节。**不装也能用,只是失去共用函数波及面分析**
- **`rtk`**——命令代理,60–90% token 节省;`settings.json` 的 PreToolUse hook 里挂了 `rtk hook claude`,**没装 hook 会静默跳过这一条**,规则本身不依赖它

### 二、拉仓 + 装到位

```bash
# 1. 备份现有 ~/.claude(如果有的话)——里面可能有你自己的会话/token,别覆盖掉
mv ~/.claude ~/.claude.backup.$(date +%Y%m%d)

# 2. Clone 到目标位置
git clone https://github.com/yiyang774/scriptorium.git ~/.claude
cd ~/.claude
```

### 三、必改项(不改就跑不起来或会用错帐号)

**1. 路径**:全仓 grep 一下写死的绝对路径,换成你自己的:

```bash
grep -rn "/Users/macbookpro" ~/.claude --include="*.sh" --include="*.py" --include="*.md" --include="*.json"
```

主要在 `settings.json`(hook 命令的绝对路径)、hooks/*.sh、bin/* 里;数量不多,机械替换成你的 `$HOME`(能用变量的地方用变量)。

**2. `settings.json` 的 `env` 段**:里面的 `ANTHROPIC_AUTH_TOKEN` 和 `ANTHROPIC_BASE_URL` 是**我的私人代理路由**,你必须换成:

- 官方 Anthropic API:删掉整个 `ANTHROPIC_BASE_URL`,`ANTHROPIC_AUTH_TOKEN` 换成你的 API key
- 或换成你自己的代理

**3. 模型名**:`ANTHROPIC_DEFAULT_*_MODEL` 与 `inferenceModels` / `models` 列表里 `claude-zyy00/*`、`tuzi-*` 都是我本地代理暴露的名字。用官方 API 的话:

- `ANTHROPIC_DEFAULT_OPUS_MODEL` → `claude-opus-5` 之类官方 ID
- `ANTHROPIC_DEFAULT_SONNET_MODEL` → `claude-sonnet-5`
- 其它同理,或者整段删掉走默认

**4. Codex 侧模型名**:`CLAUDE.md` 与 `ops/plan-gate.md`、`ops/l2.md` 里通篇写着 `gpt-5.6-sol` / `gpt-5.6-luna` —— 这也是本地代理名。你要么按 `~/.codex/config.toml` 里你实际能调的模型名重命名(全局搜索替换),要么改成 `gpt-5.5` / `gpt-5-mini` 一类 codex 官方模型 ID。**这一步不做,Plan-Gate 与 L3 全部报"unknown model"**。

**5. git 身份**:仓库里 `.git/config` 是我的 `yiyang774`。第一次 clone 后 git 会用你机器的全局身份,不需要动仓库级配置;要 push 到你自己的 fork 时改 `origin`。

### 四、体检 + 自测

```bash
# guard hook 自测(改过 guard 或 settings 都跑一次)
~/.claude/hooks/guard-selftest.sh

# 记忆结构体检(判据只查结构,不判内容)
~/.claude/bin/mem-check ~/.claude/projects/-Users-macbookpro/memory

# 全局记忆索引(会自动加载进会话)——本仓不装记忆内容,首次运行为空是正常的
ls ~/.claude/projects/-*/memory/ 2>/dev/null || echo "(空,你要自己攒)"
```

启一次 `claude`,随手问一句"当前工作目录",看:

- ✅ 会话正常起(env 段的 token / base URL 通了)
- ✅ 没被 hook 拦(所有 hook 脚本路径都对)
- ✅ `Skill` 工具可见 `brainstorming` / `plan` / `spec` 等(marketplace 段拉到了)

三条都对就装好了。

### 五、几个常见坑(先说,免得踩)

- **hook 脚本路径必须是绝对路径**——`settings.json` 里的 `command: /Users/macbookpro/...` 必须整段改,写 `~/.claude/hooks/...` 或 `$HOME/...` 都会静默失效,Claude Code 不解析 `~`
- **`.guard-off` 永不入库**——`.gitignore` 已排除,清帐时也别 commit
- **`settings.local.json` 用于机器本地覆写**——想临时改 token / hook / 模型别改 `settings.json`,写在 `settings.local.json` 里,它天然被 `.gitignore` 排除,不会污染仓库
- **`codegraph`、`rtk` 缺一个不影响主流程**——它们是加速器,不装只是慢一点/失去某个能力,规则本身仍能跑
- **不要 clone 我的全局记忆去用**——本仓 `.gitignore` 顶层 `projects/` 已排除全局记忆条目,新装完 `MEMORY.md` 索引为空是正常的;那些是我自己踩坑攒的教训,直接搬会污染你的判断

## 为什么要这么设计

因为一个人在长会话里最容易犯的错是**"感觉做过了 = 真做了"。**这套规则把每个容易翻车的环节都变成**硬门槛——**少数高频手滑路径由 hook 兜底**(直接推 `main`、审查缺 `-s read-only`、报数没跑命令、说了"我会…"但没做),**其余硬门槛靠 L0 按规则执行和留痕**——CLAUDE.md 明确写着"guard 不替代任何硬门槛"。

三个反复踩过的失败模式,规则各有对应答案:

| 失败模式 | 规则对策 |
|---|---|
| **计划错了,后面再严的审也在错地基上盖楼** | Plan-Gate:据以派活的 spec/plan 必过 Codex 异构对抗审(标准流水线在派活前;实证流在拿到实验数据后的第 ⑧ 步) |
| **同家族模型可能共享盲点** | frontier 审查恒用 Codex `gpt-5.6-sol`(前提:L0 是 Claude 家族)——不让做全部判断的 L0 给自己背书 |
| **"应该没问题"直接进入结论** | 证据分三级(一手 / 二手 / 零级——零级即"由协议/构造必然为真的结果",看着像数据其实零信息量);Stop hook 拦截"报了数字但没跑过命令"的量词断言 |

## 两条路:标准流水线 vs 实证流

拿到任务先分流,一句话判据:**做两个版本跑一跑,能用数字分出高下吗?**

- **能** → 走**实证流**:并行造原型 → **真跑出数据** → **后置**对抗审(让 frontier 模型拿到事实而非主张)
- **不能**(只有一条路;或产出本身就是最终物如规范文本、架构定位) → 走**标准流水线**(下一节)
- **拿不准** → 默认标准流水线

**实证流的入口有四条判据,必须全中**(缺一即走标准流水线):

1. 至少两个**关键机制有实质差异**的候选(改名 / 改参数 / 明显更差的陪跑项不算),能在同一接口、数据、资源预算、测量流程下运行
2. 本次选择会直接改变后续 spec、实现方向或资源投入;至少一个主指标或硬约束**必须真跑才能获知**
3. **在看结果之前** L0 已写好决策表(什么区间 → 触发什么动作,至少两个不同区间导致不同动作)
4. 各候选留下可追溯的原始数据、配置、代码 hash,能估计噪声

**九步流程**(细则 `ops/empirical-flow.md`,只列骨架):

```
① 预注册(候选表 + 指标契约 + 决策表 + 共享测量代码,过黄金样例)
② 设计审(advisory,fail 不阻断) → 测法不公平回 ①
③ 并行派 N 个 L1 写原型(spike;窄例外:允许 Gate 前派)，模型和人一样，给他一个topic，他也是胡思乱想，但是要是有具体的实验或者原型（从github上面找）简单实现之后再头脑风暴会好很多
④ 原型快审(跨家族;作者是 codex 时由 Claude 审,advisory)
⑤ 真跑 → runs/YYYY-MM-DD-<slug>-<候选>/
⑥ 互盲分析(⑥A Codex sol ultra 证据账本 ‖ ⑥B Claude 全新上下文独立审阅)
⑦ L0 亲自核原始数据 → 形成分歧清单 → 写 spec/plan
⑧ Plan-Gate(硬门槛,与标准流水线同款 sol ultra 四维单审)
⑨ 生产化六步协议 → PR-GATE
```

窄例外:① 共享测量代码与 ③ 候选原型允许在 Gate 前派活(四条边界全中才成立,`ops/empirical-flow.md` §2③ 有对照表)——**探测可以先派,交付不能先派**;⑦ 后的生产化 spec/plan 仍须过 ⑧ 才能派实现。

## 分层结构

```
L0 大脑(当前会话本体)     ← 思考、拆任务、定验收标准、收口
   ↓ 派活
L1 执行(codex luna / Sonnet 5 / Haiku 4.5)
   ↓ 产出
L2 快审(便宜的跨家族粗筛,fail 不阻断,不能替代 L3)
   ↓
L3 终检(Codex gpt-5.6-sol xhigh,只读)  ← 硬门槛
   ↓
L0 收口(读 L3 → 逐条核验 → 拍板)
```

**Plan-Gate**(单进程 sol ultra、四维单审)审的是 spec + plan,不是代码。**触发时点分两条路**:标准流水线在**据以派活的 spec/plan 派活之前**;实证流在第 ⑧ 步(拿到实验数据后)。这是把"异构换视角"移到最该兜底的地基层。

**Fable 5** 不进入执行/审查分层——它只是 Plan-Gate 架构僵局时的**只读顾问**,窄触发、每次现场征得用户同意。

## 硬门槛清单

| 锚点 | 作用 | 何时触发 |
|---|---|---|
| `[PLAN-GATE]` | 据以派活的 spec/plan 必过对抗审(标准流:派活前;实证流:第 ⑧ 步) | 任何据以派活的计划性产出 |
| `[OWNERSHIP]` | 意图与 go/no-go 归 L0 | 全程 |
| `[EVIDENCE-FIRST]` | 每层都要验证,证据分三级(一手/二手/零级) | 全程 |
| `[SELF-CONTAINED-BRIEF]` | 委派简报必须自包含 | 每次派 subagent |
| `[DELEGATION-BAND]` | 单次委派实现代码 ≤400 目标线、≤600 硬上限(测试不计) | 每次派活 / L0 自己动手 |
| `[GRANT-PERMISSIONS]` | 一次给足权限;审查者只读 | 每次调 codex / subagent |
| `[DIAGNOSE-FAILURE]` | 失败要诊断,别盲目重试——先定位,再改简报/升层/接管 | 任何一层产出差时 |
| `[SKILL-PIPELINE]` | 写代码/研究前必先 `brainstorming` | 任何编码或研究任务 |
| `[PR-GATE]` | GitHub 改动只开 PR、必过 Codex 终检 | 任何要进 GitHub 的改动 |
| `[PRIMARY-SOURCE]` | 需要原文支撑的外部取材必须走 codex,`WebSearch` 摘要禁止当原文 | 任何引用外部资料 |
| `[PLAIN-LANGUAGE]` | 别自创高浓度词汇 | 面向人的输出 |
| `[FABLE-ADVISOR]` | Fable 5 只读顾问,非常规 break-glass | 极窄触发 |
| `[ENGINE-ASSIGNMENT]` | frontier 审查只用 Codex | 全程 |

## 强制执行层(hooks)

规则光写着没用,人会忘。所以规则本身也被脚本兜底:

- 🔴 **PreToolUse 硬拦**:PR 直接合并、推默认分支、审查调用缺 `-s read-only` — 拦截**可识别的直接调用形式**(已知缺口见 MISTAKES.md E006:`VAR=val cmd ...` 前缀赋值会绕过前缀 glob;备案未修)
- 🟡 **Stop 证据闸**:回复里出现"共 N 处"、"全部通过"、"没有任何"这类量词断言但本回合没跑过任何检索命令 — 打回
- 🟡 **Stop 承诺闸**:回复里出现"我会…"、"稍后补…"这类第一人称未来承诺但本回合没对应动作 — 打回
- **SessionStart / PreCompact / Stop 三个 journal hook**:辅助记录——SessionStart 注入进行中日志清单,PreCompact 写 `.precompact/` 快照,Stop 提醒并给事实草稿;**规范事件流本身仍靠 L0 自觉**(见"记忆与任务日志"节)

急停两种方式,机制不同,别混用:
- **`GUARD_OFF=1`**:必须**在启动 Claude Code 之前**由外部环境预导出(`GUARD_OFF=1 claude ...`);PreToolUse 在命令执行**前**跑,同一次调用里写 `export GUARD_OFF=1 && <cmd>` 无效,`export` 还没进程内 hook 就已经拦了
- **`touch ~/.claude/.guard-off`**:会话中途也生效,但**必须当场向用户声明理由,用完立即 `rm -f`**,忘删会静默让整套 guard 失效(2026-08-07 实测踩过)

急停 ≠ 豁免任何硬门槛——Plan-Gate、L3、PR-GATE 照旧生效,guard 只是它们的提醒层。

## 代码定位与影响面:codegraph

grep 找得到"哪一行出现了这个名字",找不到"改了它会波及什么"——尤其聚合函数、共用工具、动态派发。规则把这层能力接进来:**改共用函数前必跑 `codegraph impact <symbol>`**,看波及面与会挂的测试。

**前提**:只在有 `.codegraph/` 索引的仓库适用;没有就当它不存在——**建不建索引是用户的决定,规则不擅自建**。

**用起来的四条命令**(细则 `ops/codegraph.md`):

```bash
codegraph impact <symbol>          # 改它会波及什么、哪些测试会挂
codegraph callers <symbol>         # 谁调用了它
codegraph callees <symbol>         # 它调用了谁
codegraph explore "<问题或符号名>"  # 逐字源码 + 调用路径
```

⚠️ `impact` / `callers` / `callees` **只有 CLI 有**——MCP 侧默认只暴露 `codegraph_explore` 一个工具(实测 `tools/list` 确认)。别去找 `mcp__codegraph__impact`,它不存在,走 Bash。

**为什么不是 grep 快慢的问题——是结构上做不到**:paperI_motivation 全仓实测(2026-08-05),`impact cluster_bootstrap` 报 **68 个受影响符号**,**其中 36 个所在文件从头到尾没出现过该符号名**(动态派发经聚合层链条到达),grep 永远找不到;且这 36 个里 33 个是测试。这正对症一次"聚合链最后一步藏雷、常数单测测不出"的事故(`delta_c_bootstrap` 双重 bootstrap 把置信区间压窄 28 倍)。

**日常零操心**:本机已接 MCP + `UserPromptSubmit` hook——代码类提问会**自动注入结构上下文**,不必主动想起;写 spec / 改措辞 / 问口径这类非代码对话注入 **0 字符**,无成本。

**派子代理时必须写进简报**(子代理无会话记忆,给路径没用):

> 本仓已建 codegraph 索引;改共用函数前先跑 `codegraph impact <symbol>`,看波及面与会挂的测试。

**卫生**:`.codegraph/` **必须进 `.gitignore`**——机器生成、体积不小,不进版本控制。参考开销:paperI_motivation 全仓 **4,930 节点 / 12,423 边、索引耗时 1.3 秒、产物 16 MB**。

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

## 记忆与任务日志

除了硬门槛和 hooks,规则本身还规定了 L0 该**记什么、怎么记、放哪儿**——因为跨会话最容易丢的东西是"上次踩过的坑"。

**三层记忆**(判据一句话:**换个项目还用得上吗?**)

| 层 | 位置 | 收什么 | 是否入库 |
|---|---|---|---|
| 全局 | `~/.claude/projects/<编码后的工作目录>/memory/*.md` + 同目录 `MEMORY.md` 索引(本机是 `projects/-Users-macbookpro/memory/`) | 跨项目可复用的教训 / 偏好 / 方法论(索引进会话自动加载) | 本仓库 `.gitignore` 忽略顶层 `projects/`,不入库 |
| 项目 | `<项目>/docs/superpowers/memory/*.md` + 该项目 `MEMORY.md` | 只有单个项目才用得上的状态与细节;进项目先读它自己的 `MEMORY.md` | 由**各项目自己**决定是否入库;本仓库的 `.gitignore` 不会自动排除 |
| 时间线 | `<项目>/docs/superpowers/journal/YYYY-MM-DD-<slug>.md` | 一任务一份;头部状态快照(每次覆写)+ 事件流(**只追加、绝不改写历史**——否则会"整理"掉不利记录,日志失去证据价值) | 同上 |

**何时建 journal**(命中任一即建):走 brainstorm+plan 的复杂任务、进 Plan-Gate、单次实现 >400 行、已产 spec/plan 且据以落地、判定进实证流(须在**任何 Gate 前实现派活之前**记入口判据 + 决策表——事后补记不算)。纯对话、小事实查询、≤400 行普通委派不建。

**错误档 `<项目>/docs/superpowers/journal/MISTAKES.md`**:只收本项目特有的坑(跨项目通用教训归全局 `memory/`)。派活前跑 `bin/mistakes [关键词]` 直接产出可粘贴到子代理简报里的教训片段(子代理无会话记忆,给路径没用)。

**记忆条目的固定形态**:frontmatter 里带 `name` / `description` / `type`(user | feedback | project | reference),body 里用 `[[name]]` 相互链接。写前先扫有没有覆盖同一件事的旧条目,重复的更新旧的、别新建;发现错的直接删掉。

**体检 / 工具**:
- `bin/mem-check [目录]` — 5 类**纯结构**检查(悬空 `[[链接]]`、`MEMORY.md` 索引同步、孤立笔记、frontmatter 缺字段、疑似重复);**不判断内容是否应下沉**,那要靠人
- `bin/mistakes [关键词]` — 从 MISTAKES.md 抽 active 项拼成简报片段
- **hook 只做辅助**:`SessionStart` 注入进行中日志清单、`PreCompact` 写 `.precompact/` 快照、`Stop` 提醒模型更新日志并给事实草稿——**规范事件流本身仍靠 L0 自觉**(`ops/journal.md` 明确写着"事件流内容仍靠自觉、无机器强制")

⚠️ **本仓库只装机制,不装内容**:全局记忆条目落在 `~/.claude/projects/`,由本仓库 `.gitignore` 顶层 `projects/` 排除;项目记忆和日志落在各项目自己的 `docs/superpowers/`,是否入库归各项目决定。**别 clone 我的全局记忆去用**——那是我自己踩坑攒的,直接搬会污染你的判断。你要建的是你自己的。

## 用起来大概长啥样

标准流水线一次典型任务(实证流的 ①–⑦ 见上一节;⑧ 起走本节的 3 步之后):

1. `brainstorming` skill 聊清意图 → 拿到用户认可(HARD-GATE,没认可不写一行代码)
2. `spec` + `plan` skill 拆任务,给验收标准
3. **Plan-Gate**(单进程 sol ultra 四维单审 + 有罪推定):按 `ops/plan-gate.md` 里的完整脚本发起;NO-GO 意见交给 L0 分诊——**go/no-go 归 L0**(异议若确属误报可书面放行;非致命异议自行取舍)
4. 派 L1(默认 codex luna;强耦合改动 → Sonnet 5;机械批量 → Haiku 4.5),简报自包含 + 显式全权授权 + 逐字带上"环境与威胁模型"段(`ops/plan-gate.md` §🔻)
5. L1 落地(先 `test` 写失败测试 → `build` 小步实现 → `review` 作者自检)
6. **L2 快审**(便宜的跨家族粗筛,fail 不阻断,不能替代 L3;见 `ops/l2.md`)
7. **L3 终检**:按 `ops/plan-gate.md` 里的调用形态,例如 `codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only review --uncommitted`
8. L0 分诊 → 逐条修 → **对【最终态】再跑一次 L3**(移动靶陷阱,§2.6;逐轮 GO 只对当轮的移动靶成立,不等于最终状态正确)→ 冻结态 L3 通过后由 **L0 拍板**
9. 要进 GitHub:先读 `ops/pr-merge.md` → `gh pr create` → codex 审 PR + head/base 双 OID 绑定 + 工作区纯净三闸 → 合并前重取远端 OID 与留痕逐一比对 → 由**用户本人**执行合并(L0 只给 go/no-go 建议,自己绝不跑 `gh pr merge`)

## 谁能用

这套规则是我个人在长任务里踩坑攒出来的,**默认单机单用户环境**——路径写死 `/Users/macbookpro/...`。

⚠️ **默认威胁模型是"本机单人开发、无不可信输入、产物不对外服务"**(见 `ops/plan-gate.md` §🔻,codex 简报里逐字带这段是为了覆盖 codex 默认按公网多租户产品设的模型)。**产物若要上线、对外服务、处理他人数据或进公共仓库,必须重写这段威胁模型**——否则外部读者拿这套规则去审对外产物,审查会按指令忽略在那个环境真实可达的输入与权限问题。

想跨机复用需要:

1. 用户名不同就全局改路径(或改成 `$HOME`)
2. `settings.json` 里的 token / base URL 是我的私人代理路由,你要换成自己的
3. `Fable 5` / `Codex gpt-5.6-sol / gpt-5.6-luna` 是我本地代理暴露的模型名,你环境里名字可能不一样
4. 本仓库**不含 skill 包**——`CLAUDE.md` 明确提到的 skill 名(`brainstorming`、`spec`、`plan`、`build`、`incremental-implementation`、`test`、`review`、`ship`、`systematic-debugging`、`debugging`、`writing-plans`、`dispatching-parallel-agents`、`using-agent-skills`、`using-superpowers`)由 `settings.json` 的 `enabledPlugins` / `extraKnownMarketplaces` 段列出的 marketplace 分发——Addy 的 `agent-skills`、`superpowers-marketplace`、`openai-codex`、`ralph-loop`。若你有其他本地私有 skill 想接进来,自己配 marketplace 或 symlink 即可,本仓库不提供

## 授权

规则文本部分:任意使用、修改、二次分发,不作任何保证——这是我个人工作流,不是产品。

## 引用

如果这套规则对你有启发,欢迎引用仓库地址:

```
https://github.com/yiyang774/scriptorium
```
