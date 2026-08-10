# 任务日志 hooks（B 包 · 最小可用版）

三个 hook 已注册在 `~/.claude/settings.json`（全局，与 rtk 的 `PreToolUse` 并存）。
**设计全部基于实测**，依据见 `~/docs/superpowers/journal/2026-07-26-hook-probe-findings.md`。

## 职责与实测依据

| hook | 做什么 | 为何这样写（实测） |
|---|---|---|
| `journal-sessionstart.sh` | 注入本项目**进行中**任务清单（只列文件名+日期，不含正文） | SessionStart 的 stdout **确认会进模型上下文** |
| `journal-stop.sh` | 会话结束前，用 **`exit 2` + stderr** 要求模型更新日志 | **`exit 0` 模型完全不理**；`exit 2` 才真的续跑并执行 |
| `journal-precompact.sh` | 压缩前**自己读 transcript** 写摘要到 `journal/.precompact/` | PreCompact 的 `exit 2` **只阻断压缩、不驱动模型**，故改为 hook 自主落盘 |
| `journal-facts.sh` | PostToolUse：把**硬事实**攒进 `journal/.facts-<日期>.md`，Stop 时随提醒一并交给模型提炼 | `PostToolUse` 能拿到 `tool_name`/`tool_input`/`tool_response`（实测） |

## 共同的安全边界

- **项目根用 `$CLAUDE_PROJECT_DIR`**，不上溯猜（上溯会让子项目继承祖先项目的 journal，
  且 `$HOME/docs/superpowers/` 确实存在）
- **无 `docs/superpowers/journal/` 目录即静默退出 0** —— 该目录的存在就是 opt-in 标记
- **一律 fail-safe**：实测 hook 不存在 / 语法错 / 无执行权限**都不会阻断会话**
- **绝不自动创建日志** —— 建档是语义决策，机器不代劳

## 各自的触发条件（避免噪音）

**SessionStart**：只列头部 `状态：进行中` 的日志；最多 10 条、超出提示数量；
日期不合 `YYYY-MM-DD` 则显示"日期未知"（不原样透传文件内容）；跳过 symlink。

**Stop**：四重闸门，任一不满足即静默——
1. `stop_hook_active` 为 true（已续跑过一次）→ 放行，**防无限循环**
2. 进行中日志**不是恰好 1 个** → 不催（0 个无处可写；多个无法判定该写哪份）
3. 该日志**今日已更新过**（头部 `最后更新` 是今天）→ 不催
4. **本项目今天已经催过一次** → 不催（用户裁定：**一天只拦一次**）
   - 戳存在 `~/.claude/hooks/.stop-stamps/<日志路径 hash>`，内容是日期
   - 按**日志文件**记戳 → 多项目各自独立、换日自动失效
   - **即使上次催完没真去改，当天也不再催**（闸门 3 只看日志本身，闸门 4 才是频率闸）
   - 自动清理 7 天前的旧戳

**PreCompact**：过滤非用户真实输入（`<local-command-*>`、`<command-name>`、
`<system-reminder>`、上下文续接摘要），只保留真实提问；单条截断 200 字；
`.precompact/` 保留最近 20 份自动轮转。

## 自动写日志：机器攒事实、模型补语义（用户裁定 2026-07-26）

用户想"做完一个完整任务就自动记一条"。**但"任务完成"是语义判断，机器读不到**——
Stop hook 每轮都触发，分不清"交付了模块"和"回答了小问题"。
**全自动写入（方案 C）已在 A 包被否决**：机器不懂哪些事值得记，产出是流水账，
会淹没裁决与误报理由——那恰是日志最贵的内容。

**故切法是**：`journal-facts.sh`（PostToolUse）只采集 **4 类机器可靠判定的硬事实**——

| 类别 | 采集条件 |
|---|---|
| 测试结果 | 命令含 `pytest`/`test`，**分别**提取 passed/failed/error/skipped（见下方教训） |
| PR / commit | 输出含 GitHub PR 链接，或 `git commit` 的 short SHA |
| 行数复核 | 命令含 `--numstat`，汇总净新增 |
| Codex 审查 | 命令含 `codex exec`，记模型档与 effort |

**极度节制**：普通命令（`ls`、`grep`…）零留痕；草稿满 200 行即停止追加；
只在项目有"进行中"日志时才攒。Stop 催更新时把草稿一并交给模型，
**明确要求"挑值得记的、补上语义，不要照抄"**。

### 教训：解析测试输出别假设 passed/failed 顺序

初版正则写 `(\d+) passed(?:, (\d+) failed)?`，而 **pytest 有失败时输出
`1 failed, 2 passed`（failed 在前）** → 只抓到 `2 passed`、漏掉 failed，
**把失败的运行记成绿灯**。已改为分别提取 + `⚠️未全绿` 标记。已登记 MISTAKES E005。

## 频率：一天一次（用户裁定 2026-07-26）

用户原话是"每一个项目可以每一天更新一次，比如晚上1点钟更新一次"。
**已确认其意图是"别每次会话都拦，一天一次就够"**，而非无人值守的凌晨定时任务——
后者需要 launchd + `claude -p`，且无人监督下写出的日志质量无从校验。
故只调 Stop 的频率闸，不引入定时任务。

## 已知边界

- **Stop 只在恰好 1 个进行中日志时催** —— 并行多任务时不催，这是有意的（不猜）
- **`.precompact/` 是机器摘要，不是任务日志** —— 它只存用户消息序列供恢复参考，
  不替代按 §四·五 规范手写的日志
- **PreCompact 在压缩未实际发生时也会触发**（实测 "Not enough messages to compact"
  时 hook 已执行）→ 可能产生无用摘要，靠轮转限制
- 单次 `claude -p` 的 transcript 尚未落盘，`.precompact` 无内容；真实交互式会话天然满足

## 回滚

```bash
cp ~/.claude/settings.json.bak-20260726-210608 ~/.claude/settings.json
```
或用 `python3` 删掉 `hooks` 里的 `SessionStart`/`Stop`/`PreCompact` 三键（保留 `PreToolUse`）。
