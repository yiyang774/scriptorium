# 实施指南（实证法，取代文本 spec 作为派活依据）

日期：2026-08-03　　依据：用户裁定 D8（四轮方向关不收敛 → 换实证法）
基线快照：`~/.claude-band-snapshots/claudemd-fix-20260803-090524`（cp -a，39 文件）

> 本文件是**唯一派活依据**。四轮 Plan-Gate 的 64 条意见中的有效约束已浓缩于此。
> 矛盾用**真实 diff** 暴露：改得出来的是伪矛盾，改不出来的是真矛盾。

## 交付白名单（只写这 10 个路径，多一个即越界）

```
CLAUDE.md
ops/l2.md（新建）
ops/fable5.md   ops/plan-gate.md   ops/pr-merge.md
ops/line-count.md   ops/journal.md   ops/journal-templates.md
workflows/plan-gate-direction.js
agents/fable-readonly-advisor.md
```

**审计白名单**（裁定 D7，留痕用，不计行数、不算越界）：
`.plangate/<run>/`、`docs/superpowers/`；临时产物走 `mktemp`。

---

## 任务 A · 锚点定义（CLAUDE.md §三）

为 12 条铁律标题各追加锚点，**从后往前改**（避免行号移位）。三元组已实测核对：

| 行 | 编号 | 标题关键词（实测原文） | 锚点 |
|---|---|---|---|
| 87 | 12 | Fable 5 是 Plan-Gate 阶段的只读架构顾问 | `[FABLE-ADVISOR]` |
| 86 | 11 | 第一步必过 Plan-Gate | `[PLAN-GATE]` |
| 84 | 10 | 写代码／做研究：先 brainstorm | `[SKILL-PIPELINE]` |
| 82 | 9 | GitHub 改动一律"只开 PR… | `[PR-GATE]` |
| 80 | 8 | Subagent 执行只用 Claude | `[ENGINE-ASSIGNMENT]` |
| 79 | 7 | 失败要诊断，别盲目重试 | `[DIAGNOSE-FAILURE]` |
| 78 | 6 | 给足权限，不被卡住 | `[GRANT-PERMISSIONS]` |
| 71 | 5 | 联网取材 | `[PRIMARY-SOURCE]` |
| 70 | 4 | 每层都要验证 | `[EVIDENCE-FIRST]` |
| 58 | 3 | 委派粒度带 | `[DELEGATION-BAND]` |
| 57 | 2 | 自包含简报 | `[SELF-CONTAINED-BRIEF]` |
| 56 | 1 | 意图与验收标准永远归 | `[OWNERSHIP]` |

写法：`3. **委派粒度带：…** \`[DELEGATION-BAND]\` 委派有开销（…`
（锚点紧跟标题加粗段之后、正文之前。）

§三 顶部插入：

> **引用规则**：跨文件引用只写锚点（如 `[PLAN-GATE]`）并标宿主"CLAUDE.md §三"，**不写数字**；
> 编号仅供人读与本文件内导航。插入新铁律时编号会变、**锚点永不变**。
> **锚点不得复用**：条款废止则锚点退役（本节留一行退役登记），不得转指他条。
> **配置根**：本规则体系的根目录 = 本文件所在目录（本机 `~/.claude`）；
> 下文所有 `~/.claude/...` 路径按此解析。

---

## 任务 B · 引用改锚点（21 处错误 + 形式迁移）

### B-1 错误引用 21 处（逐项核销，**含 2 处 grep 抓不到的裸条目号**）

| 文件:行 | 现写 | 改为 |
|---|---|---|
| CLAUDE.md:23 | 铁律 11 | `[FABLE-ADVISOR]` |
| CLAUDE.md:52 | 铁律 8 | `[PR-GATE]` |
| CLAUDE.md:108 | 铁律 7 | `[ENGINE-ASSIGNMENT]` |
| ops/fable5.md:1 | 铁律 11（标题） | `[FABLE-ADVISOR]` |
| **ops/fable5.md:7** | **`11.` 裸条目号** | **`12.`** ← grep 抓不到 |
| ops/fable5.md:8 | 铁律 10 ×2 | `[PLAN-GATE]` ×2 |
| ops/fable5.md:11 | 铁律 5 ×2 | `[GRANT-PERMISSIONS]` ×2 |
| ops/fable5.md:12 | 铁律 10 ×2 | `[PLAN-GATE]` ×2 |
| ops/plan-gate.md:27 | 铁律 10 | `[PLAN-GATE]` |
| ops/plan-gate.md:86 | 铁律10（无空格） | `[PLAN-GATE]` |
| ops/plan-gate.md:106 | 铁律 5 | `[GRANT-PERMISSIONS]` |
| ops/plan-gate.md:109 | 铁律 5 | `[GRANT-PERMISSIONS]` |
| ops/pr-merge.md:1 | 铁律 8（标题） | `[PR-GATE]` |
| **ops/pr-merge.md:6** | **`8.` 裸条目号** | **`9.`** ← grep 抓不到 |
| workflows/…js:17 | 铁律 7 | `[ENGINE-ASSIGNMENT]` |
| workflows/…js:101 | 铁律 7、铁律 5 | `[ENGINE-ASSIGNMENT]`、`[GRANT-PERMISSIONS]` |
| agents/fable-readonly-advisor.md:3 | 铁律 11 | `[FABLE-ADVISOR]` |

### B-2 形式迁移（编号本正确，一并改锚点）

`ops/line-count.md:1`(铁律3→`[DELEGATION-BAND]`)、`ops/journal.md:9,22`(同)、
`ops/journal.md:13`(铁律4→`[EVIDENCE-FIRST]`)、`ops/journal-templates.md:52,98,116`(铁律3→同)、
`workflows/…js:4,178`(铁律11→`[PLAN-GATE]`)、CLAUDE.md 内其余全部。

**不改**：`workflows/…js` 的任何逻辑/schema/命令参数；`agents/*.md` 的 `tools:` 字段；
所有 bash 代码块内的命令、哨兵、三闸。

---

## 任务 C · L2 外置为 ops/l2.md

**权威基线 = CLAUDE.md §四 的 L2 大段**（唯一完整规范表述），逐字搬入。

`ops/l2.md` 确定结构（顺序固定）：
```
# L2 跨家族快审（唯一事实源，从 CLAUDE.md §四 外置）
> 配置根：若本体系不在 ~/.claude，按 CLAUDE.md 所在目录解析
§1 定位与触发范围
§2 跨家族选档矩阵
§3 有效发起四判据 + fail-不阻断语义 + 固定记录句式
§4 调用（bin/l2 首选；§二·4 的 bin/l2 表述搬到此处）
§5 输出契约（must-fix/nit）与 must-fix 修完复审
§6 待办登记（不裁定）
```

§6 原文：
> **待办（本次不裁定）**：Claude 侧 L2 现有两种落地形式——`Agent` 工具与 `bin/l2` 内的 `claude -p`。
> 二者在独立上下文、互盲性、留痕上是否等价**尚未验证**。本次搬迁不改变任何一方现状，
> 也**不就其有效性作出裁定**。另：`bin/l2` 不消费本文件，
> **规范源与执行实现的一致性检查登记为独立待办**。

**主文五处改纯指针**（裁定 D6，五处逐字一致，无任何操作语义词）：

> ▶ **跑 L2 前必须先 `Read ~/.claude/ops/l2.md`；读不到则不得发起 L2。**

| 位置 | 目标 |
|---|---|
| §一表格 L2 行 | 表格字段保留，"负责什么"格 = 该指针 |
| §二·4 | 整条压成该指针 |
| §四 L2 大段 | **整段删除**（搬入 l2.md），原位留该指针 |
| §五速记 L2 行 | 删 L2 部分（含修 :127 错误指针），改该指针 |
| 铁律 8 附则 | **保留硬门槛句**"L2 不得作为跳过 L3/Plan-Gate 的理由" + 其后附同一指针 |

**"单一定义处"的准确目标**（据 r4 v3-6 收窄）：
**四判据与操作参数仅在 ops/l2.md 定义**；硬门槛句与加载指针是明确例外。

---

## 任务 D · 角色解耦

1. 作为 **L0 角色名**的 "Opus" → **"L0 主循环"**：CLAUDE.md:5(第0铁律豁免边界)、:9、:17、:21、
   §二/§三/§四/§六 各处流程描述；白名单内 ops 文件同理。
2. **例外保留字面**（此处指具体模型）：
   - 铁律 8 "永不 Opus / Fable" → 留 CLAUDE.md
   - §四 开头 "永不用 Opus / Fable" → **留 CLAUDE.md**
   - 结果：**CLAUDE.md 恰好 2 处 "Opus"，ops/l2.md 0 处**

   > **实证修正（2026-08-03，据 Claude 侧 L2 must-fix 1）**：本项原预判为
   > "§四那句随 L2 段搬入 ops/l2.md，故 CLAUDE.md 剩 1 处、l2.md 1 处"。
   > 实际改完后核对发现：§四 :92 那句是**§四开头对 "Subagent" 的总定义**
   > （"Subagent = 一切派出去的执行单元…"），**不属于**被搬走的 L2 大段，
   > 因此它正确地留在了 CLAUDE.md。**预判错误，实测状态正确**——
   > 这正是换实证法要暴露的那类文本推演偏差。验收标准据此更正为 2 处 / 0 处。
3. §一顶部加一句（**不含能力门槛**，D3 已撤回）：
   > **L0 由用户选定的模型担任**。本规则约束的是**角色**而非特定模型。
4. 铁律 12 加消歧：
   > 本条只读硬约束针对**作为顾问被派出的 Fable 5 子代理**，与 L0 主循环自身是什么模型无关。
   > 若 L0 本身即 Fable 5，本条既不因此失效、也不自动满足。

---

## 交付验收（实证，全部可跑）

1. **改动文件集** == 交付白名单 10 个路径
2. **零残留**：`grep -rnE '铁律 *[0-9]'` 对 **8 个非 CLAUDE 既有文件 + 新增 ops/l2.md** 输出 0 行；
   CLAUDE.md **仅允许** §三 12 个标题行前缀匹配
3. **两处裸条目号已核销**（grep 抓不到，人工确认 fable5.md:7、pr-merge.md:6）
4. **三元组正确**：12 行逐个核对"编号—标题关键词—锚点"
5. **五处指针逐字一致**且不含"跨家族/便宜档/fail 不阻断"
6. **Opus 分布**：CLAUDE.md 1 处、ops/l2.md 1 处
7. **机械校验**：`node --check workflows/plan-gate-direction.js` rc=0；
   `agents/fable-readonly-advisor.md` 的 `tools:` 逐字未变；代码块 ``` 计数为偶数
8. **行数**：`git diff --no-index --numstat`（rc 容忍 0/1）汇总，预期 A 档（≤400）

## 交付后（L0 收口）

- L2 跨家族快审（按作者家族选档）→ L3 终检（`gpt-5.6-sol` + `xhigh` + `-s read-only`）
- 回滚方案：逐路径记 `基线sha256 → 目标sha256` + 类型权限；恢复前**双向校验**（源与目标）；
  临时文件 + `mv -f` 原子替换；新增文件显式 `rm`（rm 前校验哈希）。
  **已知边界**：无原子 CAS，依赖"回滚期间无其他写者"（本机单人单会话成立，由操作者确认）
