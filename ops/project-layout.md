# 项目布局与命名规范（唯一事实源）

> **新建自研项目前先读本文件**；已有项目改到相关部分时顺手向规范靠拢，**不做一次性大迁移**。
> **外来仓库（克隆的第三方代码，如 `detr`）不套本规范。**
>
> 动因（实测，2026-08-05）：`motivation-figure` 同时存在 `output/` 与 `outputs/`；
> `paperI_motivation` 的实验数据散在 `exp_data/` `pilot_data/` `_diag_ck5/` `alfworld_data/`
> `archive/` `deliverables/` 六处，且 `__pycache__`、`keys.local.txt` 躺在根目录。
> 查一次结果要翻六个地方——本规范就是为了消除这个。

## 1. 目录骨架（新建项目强制）

```
<project>/
├── README.md              # 一句话说明 + 怎么跑起来
├── EXPERIMENTS.csv        # 实验总表（机器重生成，勿手改；notes 列除外）
├── EXPERIMENTS.xlsx       # 同源，装了 openpyxl 时才生成
├── src/                   # 实现代码（唯一入口，不再另开 lib/ 或散在根）
├── tests/                 # 测试
├── runs/                  # 实验产物，一次实验一目录
│   └── YYYY-MM-DD-<slug>/
│       ├── config.json    # 输入参数快照（必须含 git_sha）
│       ├── metrics.csv    # 指标，总表的数据源
│       ├── run.log
│       └── artifacts/     # 重产物（权重/checkpoint/原始数据），gitignore
├── docs/superpowers/      # specs/ plans/ journal/（沿用 ops/journal.md）
└── scratch/               # 临时，随时可删，gitignore
```

**三条硬约束**

1. **根目录只放上表所列**。`__pycache__`、`*.local.*`、密钥、临时脚本一律不许在根
   （进 `.gitignore` 或 `scratch/`）。
2. **`runs/` 只追加、绝不修改**——改了等于毁证据（同 `ops/journal.md` 的只追加原则）。
   跑错了就新开一个 run 目录并在旧目录的 `config.json` 里把 `status` 标 `discarded`。
3. **一次实验的东西全在它自己的 run 目录里**：配置、指标、日志、产物同处，不散落。

## 2. 命名规则

| 对象 | 规则 | 正例 / 反例 |
|---|---|---|
| 项目根目录 | `kebab-case` 名词短语，不带 `-project` / `-test` / `-new` 后缀 | `type-offset-calibrator` ✓ ／ `calib-test-new` ✗ |
| run 目录 | `YYYY-MM-DD-<slug>`，**日期取创建日不随更新变** | `2026-08-03-calib-sweep` ✓ ／ `run3` ✗ |
| 同日多次 | 追加 `-a` `-b` `-c`，**不用时分秒** | `2026-08-03-calib-sweep-b` |
| slug | 锚定**实验意图**，不是动作 | `calib-sweep` ✓ ／ `fix-bug` `test2` ✗ |
| **slug 对齐** | 同一任务的 run / spec / plan / journal **必须同 slug** | 四处都是 `calib-sweep` |
| 指标列名 | `snake_case`，带单位后缀 | `ece_test`、`latency_ms`、`auroc_within` |
| status | **只允许四值** | `running` / `done` / `failed` / `discarded` |

> slug 对齐是本规范最实用的一条：从任务日志能直接找到对应的 run，反之亦然。

## 3. `config.json` 最小契约

```json
{
  "run_id": "2026-08-03-calib-sweep",
  "status": "done",
  "git_sha": "b365494d",
  "started_at": "2026-08-03T14:02:11",
  "params": { "model": "qwen3-8b", "n_samples": 5509 }
}
```

`run_id` 必须等于目录名；`git_sha` 缺失时写 `"nogit"` 但**不许省略字段**。
`params` 自由，其余四个字段必填。

## 4. EXPERIMENTS 总表

由 `~/.claude/bin/exp-index` **重生成**，不手改。固定列：

| 列 | 来源 |
|---|---|
| `run_id` `date` `slug` `status` `git_sha` | `config.json` |
| `started_at` | `config.json` |
| 各指标列 | `metrics.csv`（列名自动并集，缺的留空） |
| `artifacts_path` `artifacts_bytes` | 扫 `artifacts/` |
| `notes` | **人工写，跨重生成保留**（按 run_id 合并回来） |

- **`notes` 是唯一允许人写的列**——记"为什么废弃""结论是否采纳"。重生成时按 `run_id` 合并，不会丢。
- **始终写 `.csv`**（可 grep / diff / 进 git）；装了 `openpyxl` 才额外写 `.xlsx`。
- **缺 `config.json` 的 run 目录照样列进表**并标 `status=unknown` + 报警——
  **绝不静默跳过**（静默跳过 = 表看着干净但漏了东西，是最坏的失败模式）。

## 5. 工具

```bash
~/.claude/bin/newproj <name> [父目录]   # 建骨架（已存在则拒绝，不覆盖）
~/.claude/bin/exp-index [项目根]        # 扫 runs/ 重生成总表；默认当前目录
```

## 6. 适用范围（边界）

- **强制**：新建的自研项目。
- **渐进**：已有自研项目（`paperI_motivation`、`motivation-figure` 等）——
  **只在改到相关部分时向规范靠拢**，不做一次性大迁移（会动到已有脚本的路径引用，风险不划算）。
- **不适用**：克隆的第三方仓库（`detr` 等），保持上游布局。

---

## 7. 记忆库（Obsidian vault）

位置：`~/.claude/projects/-Users-macbookpro/memory/`（已配 `.obsidian/`，可直接用 Obsidian 打开）

**先说清楚它改善的是什么**：Obsidian 是**渲染层**，不改变文件内容——
模型读的仍是纯文本 `.md`，`[[wikilink]]` 对模型就是字符串。
**它不会让模型记得更牢**；它让**你**能看见模型记了什么、记乱没乱
（反向链接面板、关系图、按 type 着色、孤立笔记一眼可见）。

### 体检（机器能查的部分，别靠肉眼）

```bash
~/.claude/bin/mem-check          # 退出码 0=干净，1=有问题
```

查五类纯结构问题：**悬空链接**（含 macOS 下肉眼看不出的大小写不一致）、
**MEMORY.md 索引不同步**（漏列 / 列了但文件已删）、**孤立笔记**、
**frontmatter 缺字段或 name 与文件名不符**、**疑似重复主题**（相似度提示，需人工判断）。

> **首次体检实测（2026-08-06）**：60 条笔记查出 **11 项**问题——
> 5 个悬空链接（3 个是 `paperi` vs `paperI` 大小写不一致，macOS 不区分大小写所以一直没被发现）、
> 7 条 frontmatter 的 `name` 与文件名不符、索引漏列 3 条、1 条 description 只写了"B3"两个字。
> **全部是肉眼扫不出来的结构性问题**，这就是要有脚本的原因。

### 三层分工（2026-08-07 重构，实测有效）

| 层 | 放什么 | 位置 | 加载方式 |
|---|---|---|---|
| **全局** | 跨项目可复用：教训 / 用户偏好 / 方法论 / 通用环境 | `~/.claude/projects/-Users-macbookpro/memory/` | 每次会话加载索引（**目标 ≤25 条**） |
| **项目** | 该项目的实验状态、根因诊断、数据契约、专属环境 | `<项目>/docs/superpowers/memory/` | 进该项目时按需读 |
| **时间线** | 这个项目**发生了什么**（只追加） | `<项目>/docs/superpowers/journal/` | 断片后先读 |

**判据一句话：换个项目还用得上吗？** 用得上→全局；用不上→项目内。

> **重构实测（2026-08-07）**：全局原有 61 条，其中 **52% 是 paperI 的实验细节**
> （"#129 阶段1 已完成、7 个 commit 未 push"这类），每次会话都占索引位置却与当前任务无关。
> 下沉 29 条到 paperI、9 条到 innovation-hunt 后，**全局 61→22 条、索引 64→34 行**。
>
> **同样带 paperI 前缀，性质可能完全不同**——`blas-oversubscription-trap`（多核开进程池
> 反而更慢）虽在 paperI 发现，但换任何项目都会踩，属跨项目教训，留全局；
> 而 `paperi-b3-129-stage1`（几个 commit、待办什么）只对该项目有意义，下沉。
>
> **跨层链接会断**：分层后原本的 `[[wikilink]]` 指向了别层的笔记。
> 处置：跨层引用改成 `` `笔记名`（见 <路径>/） `` 的形式，同层内仍用 `[[ ]]`。

### 维护约定

- 一条笔记一个事实；frontmatter 的 `name` **必须**等于文件名（去掉 `.md`）
- `type` 只允许 `user` / `feedback` / `project` / `reference`
- 新增笔记后**必须**在 `MEMORY.md` 加一行索引（`mem-check` 会查）
- 链接用 `[[笔记名]]`，指向尚未建立的笔记也可以（标记"该写"），但**别拿它当说明文字**
