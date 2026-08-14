# ~/.claude 规则体系 · 错误档

> **派活前必扫**——跑 `~/.claude/bin/mistakes [关键词]` 直接产出可粘贴的简报片段。
>
> **本档收的是**：开发 / 维护这套规则体系（CLAUDE.md、ops/、hooks/、bin/）时踩的坑，
> 以及 **macOS + shell 环境下会静默给出错误结果**的通用陷阱。
> 跨项目的方法论教训归 `~/.claude/projects/-Users-macbookpro/memory/`；
> 具体研究项目的坑归各自项目的 MISTAKES.md。
>
> **只追加**：正文写下不删不改。认识变了写新条目，把旧条目 `有效性` 改为
> `superseded-by-E0NN`（只允许改 `有效性` 和 `处置` 两个状态字段）。**一条一错**。

---

> ## 🔴 E001–E004 是同一个母题的四种形态
>
> **命令没有真正跑成，但输出看起来像"结果就是空的"。**
> 四条全部发生在 2026-08-07 同一场会话内，每一条都让我据此下了错误结论。
>
> **通用判据（用之前先问）**：
> 1. 这条命令**失败时**会怎样？是报错，还是安静地给我一个空结果？
> 2. 我有没有用 `2>/dev/null` 把错误吞掉？
> 3. 空结果我能否**用另一种方式交叉验证**？（换命令、换范围、造一个已知一定存在的样本）
>
> **口诀：空输出不等于"没有"，它同样可能是"没跑成"。**

---

## [E001] 2026-08-07 · 全盘 `find $HOME` 会静默返回不完整结果

- **有效性**：active
- **处置**：已规避
- **触发场景**：想在整个 home 目录下找某类文件时（`find "$HOME" -name 'X'`），
  尤其是 `~/.claude` 这种含 `plugins/`（1096 文件）、`file-history/`（1082 文件）、
  `projects/`（2676 文件）的目录。
- **正确做法**：**不要全盘 find**。用下列任一：
  ① 限定到已知的候选目录逐个查；
  ② 加 `-maxdepth`（**实测：不限深度只找到 1 个，`-maxdepth 6` 反而找到 4 个**）；
  ③ 加 `-prune` 排除大目录：`find "$HOME" -path '*/plugins' -prune -o -name 'X' -print`；
  ④ 已知路径就直接 `[ -f "$path" ]` 验证，别搜。
  **拿到空结果时，必须用第二种方式交叉验证再下结论。**
- **后果**：我据此断言"MISTAKES.md 一个都没有、从未落地过"，
  而 paperI 实际早有一份 **366 行、16 条**的高质量错误档。整段诊断建立在错误前提上。
- **根因**：`find` 在超大目录里耗尽时间被中断，**stderr 为空**（不是权限问题），
  于是安静地返回了不完整结果。加了 `2>/dev/null` 后更是彻底无声。

---

## [E002] 2026-08-07 · macOS 没有 `timeout` 命令，脚本静默产出空

- **有效性**：active
- **处置**：已修复
- **触发场景**：在 shell 脚本里给命令加超时保护时（`timeout 180 <cmd>`）。
- **正确做法**：macOS 自带**没有** `timeout`（那是 GNU coreutils 的）。写法：
  ```bash
  if command -v gtimeout >/dev/null 2>&1; then TO="gtimeout 180"
  elif command -v timeout  >/dev/null 2>&1; then TO="timeout 180"
  else TO=""; fi
  RESP=$($TO some-command) || RESP=""
  ```
  **本机 `gtimeout` 也没装**（未装 brew coreutils），所以实际走的是空字符串分支。
- **后果**：`timeout 180 claude -p ... || RESP=""` 里，`timeout` 不存在 →
  `command not found` → `|| RESP=""` 把错误吞掉 → 脚本 0.25 秒返回、产出空草稿。
  我起初以为是模型调用失败，查了三层才找到真因。
- **根因**：`|| VAR=""` 这种"失败就置空"的写法，**把"命令不存在"和"命令返回空"
  混成了同一个结果**。写这类兜底前，先确认命令本身存在。

---

## [E003] 2026-08-07 · `wc -c` 数的是字节，中文场景下与字符数差 3 倍

- **有效性**：active
- **处置**：已修复
- **触发场景**：统计含中文的文本长度、校验是否超出字符预算时。
- **正确做法**：
  - 数**字符**用 `wc -m`（或 python `len(s)`）；
  - 数**字节**用 `wc -c`；
  - **跟"模型上下文预算"比较时一律用字符数**——脚本里的截断逻辑通常按字符。
  实测：`printf '共21处' | wc -c` = **8 字节**，而字符数是 **4**。
- **后果**：我用 `wc -c` 量抽取器输出，得 47319，判定"超出 24000 预算、截断逻辑有 bug"，
  于是去查了一轮不存在的 bug。实际输出是 **23903 字符，正好在预算内**。
  中文 UTF-8 一字符 3 字节，恰好造成约 2 倍的假象。
- **根因**：`wc -c` 的名字（c = character）具有误导性，它实际数的是 byte。
  凡是量"给模型看的文本有多长"，单位错了会得出完全相反的结论。

---

## [E004] 2026-08-07 · 多层引号嵌套写坏，命令变成另一个意思

- **有效性**：active
- **处置**：已规避
- **触发场景**：在 bash 里内联 python/其他语言，或在 `$( )` 里再套 `printf '...%s...'`
  且内容含引号时。尤其是**用脚本生成脚本**。
- **正确做法**：**三层引号是红线——到第三层就独立成文件**。
  - 内联 python 超过 5 行 → 写成 `.py` 文件再调用；
  - 复杂的 `printf` 拼接 → 用 heredoc（`<<'EOF'` 单引号版不做变量展开）；
  - 写完**先跑一次看输出**，别直接用在判定里。
- **后果**：两次实测：
  ① 用 python 往 shell 脚本里写内联 python，生成的文件里 python 字符串
     被 shell 提前吃掉（`if ch == "\\" and q != "'"` 变成语法错）；
  ② 验收断言里 `printf '{"transcript_path":"%s"}'` 多层嵌套后没正确展开，
     导致端到端测试**假失败**——功能其实是好的，我却去查了一轮不存在的问题。
- **根因**：每加一层引用，转义规则就叠加一次，人（和模型）对第三层的直觉都不可靠。
  **`guard-split.py` 就是因此独立成文件的**——那段引号感知分段逻辑内联时写坏过一次。

---

## [E005] 2026-08-07 · 把充满"指令样文本"的 transcript 喂给模型做纪要

- **有效性**：active
- **处置**：已修复（改为纯机械抽取）
- **触发场景**：想让便宜模型读会话记录、日志、审查输出等**本身含大量指令**的文本，
  提炼成结构化纪要时。
- **正确做法**：**先问这段文本里有没有"看起来像给模型的指令"的内容**
  （guard 提示、AskUserQuestion、给子代理的简报、prompt 模板）。有就别指望
  靠提示词让它"忽略"——**改成机械抽取**：正则 + JSON 解析提取结构确定的字段。
  语义提炼（"为什么这么定"）留给有完整上下文的 L0，不外包。
- **后果**：Haiku 纪要员**连续三次**输出的不是事件条目，而是在模仿片段里的
  guard 提示（回复 `[无需证据: …]`）。加提示词说明"你不是对话参与者"没用，
  从抽取阶段过滤 guard 噪声也没根治。改机械抽取后：**88 秒 → 0.13 秒、零污染、100% 可复现**。
- **根因**：把充满指令的文本喂给模型、再让它"别把这些当指令"，**本身就是不稳的设计**——
  模型分不清"这段是历史记录"和"这段是给我的任务"。
  更一般地：**"忘了去记"靠 hook 解决（不依赖记忆）；"记得不准"靠机械抽取解决（不依赖理解）。
  派便宜模型救不了前者**——派它的那一步同样会被忘。

---

## [E006] 2026-08-10 · `guard-pretool.sh` 的 `git push` 拦截被 `VAR=val <cmd>` 前缀绕过

- **有效性**：active
- **处置**：未修复（用户裁定备案但暂不补，以免同时挡掉自己后续同类工作；真正 push 必须**分成两个独立 Bash 工具调用**——**第一次调用只 `touch ~/.claude/.guard-off`；第二次调用做 `trap 'rm -f ~/.claude/.guard-off' EXIT; git push origin main`（或等价的 `git push origin main; rc=$?; rm -f ~/.claude/.guard-off; (exit $rc)`）**；push 完再单独用第三次调用 `ls -la ~/.claude/.guard-off 2>/dev/null` 核验已删。**不能塞在一个 Bash 调用里**——PreToolUse 在整条命令**执行前**跑，看不到还没跑的 `touch`，会解析出 `git push` 段直接命中前缀 glob 阻断（2026-08-10 L3 round-4 N1 实证）。**绝不用 `&&` 串** `touch && git push && rm`：即便侥幸拦不到，`git push` 失败（网络中断、远端拒绝、non-fast-forward、`-u` 上游没设等任何非零退出）后 `&&` 短路跳过 `rm`，`~/.claude/.guard-off` 静默残留，整套 guard 后续持续关闭。**两处 `.guard-off` 都必须写绝对路径 `~/.claude/.guard-off`**：`rm -f .guard-off` 是相对路径，从子目录跑只删当前目录空文件，全局急停文件同样残留）
- **触发场景**：在同一次调用里写 `GUARD_OFF=1 git push origin main`，期望
  ① `GUARD_OFF=1` 让 guard 放行（这条本身也是错的，见 `README.md:121-123` 与 `ops/enforcement.md:69-77` 的机制说明），
  ② 或者靠 guard 的 `git push` 匹配把 push 拦下并让我意识到没关成。
  实际两件事都没发生——guard 没拦、命令直接跑成。**本任务 5 次 push 全部命中**
  （5 个 SHA 见下方"诚实澄清"段；task journal 事件流里"关 guard 的方式：`GUARD_OFF=1 git push -u origin main`"
  是叙事错误，真机制是 `hooks/guard-pretool.sh` 的解析漏洞。原始 journal 在
  `~/.claude/projects/-Users-macbookpro/journal/2026-08-10-git-init-claude-rules.md`——
  该路径被本仓库顶层 `.gitignore` 的 `projects/` 排除，公开仓库读者无法沿此指针核验；
  必要事实已并入本条 E006 正文与"诚实澄清"段）。
- **正确做法**：
  - **push 必须拆成两个独立 Bash 调用 + 一个核验调用**（**同一 Bash 调用里塞 `touch;...;git push;...;rm` 会被 PreToolUse 在整条命令执行前拦下**——`touch` 还没跑、`.guard-off` 尚不存在，hook 解析出 `git push` 段直接命中 `"git push"*` 前缀 glob；2026-08-10 L3 round-4 N1 实证）：
    1) **第一次 Bash 调用**（只创建急停文件）：
       ```bash
       touch ~/.claude/.guard-off
       ```
    2) **第二次 Bash 调用**（trap-safe cleanup，绝不用 `&&` 短路）：
       ```bash
       trap 'rm -f ~/.claude/.guard-off' EXIT
       git push origin main
       ```
       或等价的显式退出码保留：
       ```bash
       git push origin main; rc=$?
       rm -f ~/.claude/.guard-off
       (exit $rc)
       ```
    3) **第三次 Bash 调用**（核验已删）：
       ```bash
       ls -la ~/.claude/.guard-off 2>/dev/null && echo "警告:急停文件残留" || echo "已清理"
       ```
    第二次调用**进入 hook 时** `.guard-off` 已存在（第一次调用创建的），文件档 hook 直接放行整条命令（`hooks/guard-pretool.sh:14-17`）；trap 保证无论 `git push` 是否成功，`rm` 都会跑。
    **旧写法 `touch … && git push … && rm -f …`（无论一段还是分段）已作废**：`&&` 短路特性下，只要 `git push`
    非零退出（网络中断、远端拒绝、non-fast-forward、`-u` 上游未设、SSH 断线……任一），后面的 `rm`
    就被跳过，`~/.claude/.guard-off` 静默残留，整套 guard 后续持续关闭——**cleanup 必须无条件跑，不能挂在 `&&` 上**。
    **两处 `.guard-off` 都必须写绝对路径 `~/.claude/.guard-off`**；`rm -f .guard-off` 是相对路径，
    从子目录跑就删不到全局急停文件，同样残留（见"处置"）。
  - **禁止**在同一次调用里写 `GUARD_OFF=1 <cmd>`——两种失败模式：
    (a) hook 在 export 生效前跑，变量对 hook 无效；
    (b) 即使变量能生效，hook 也识别不出"应拦"的意图，静默通过。
  - `GUARD_OFF=1` 只有在**启动 Claude Code 之前**由外部环境预导出才成立
    （`GUARD_OFF=1 claude ...`）——见 `ops/enforcement.md:69-77`。
- **根因**：`guard-pretool.sh` 用 `guard-split.py` 对整条命令做"引号感知分段"，
  然后逐段与 glob 模式**前缀匹配**（如 `"git push"*` / `"codex exec"*`）。**关键事实**：
  `guard-split.py` 只在**引号外**的 `;` / 换行 / `|` / `&` 处切分（见 `hooks/guard-split.py:19` 的
  `SEPARATORS = ";\n|&"`），**不按空格切 token**、**不剥前导 `VAR=val` 环境赋值**。
  于是 `GUARD_OFF=1 git push origin main` 保持为一整段字符串。当命令以 `VAR=val cmd ...` 开头时，
  这一整段的开头是赋值 `GUARD_OFF=1` 而不是主命令，任何"以主命令开头"的前缀 glob 都不命中 → 漏拦。
  与 hook 的语义意图相反：应该先剥掉前导 `VAR=val` 再看主命令，或改成"任意位置出现主命令"的检索。
- **影响面不止 `git push`**：**同一漏洞同时影响 review-gate**。`guard-pretool.sh:98-101`（另一段
  `while IFS= read -r seg` 分段循环）用 `"codex exec"*)` 前缀 glob 检查 codex 审查调用是否带
  `-s read-only`——任何写成 `VAR=val codex exec ...` 的调用都会以 `VAR=val` 起头、不匹配
  `"codex exec"*` 前缀，绕过 read-only 强制检查。故 E006 的机制描述适用于 `guard-pretool.sh` 里
  **所有前缀 glob 拦截**（git push / gh pr merge / codex exec review），不局限于 push 一处。
- **验证**：`echo "GUARD_OFF=1 git push origin main" | python3 hooks/guard-split.py`
  实测输出**一行**：
  ```
  GUARD_OFF=1 git push origin main
  ```
  当前 `case` 语句 `while IFS= read -r seg; do ... case "$seg" in "git push"*) ...` 只遍历到这一段
  （见 `hooks/guard-pretool.sh:61`），该段以 `GUARD_OFF=1` 起头，不匹配 `"git push"*` 前缀 → 漏拦。
  review-gate 那段（`hooks/guard-pretool.sh:98` 起的 `while IFS= read -r seg`）同理，
  以 `"codex exec"*` 匹配同样被 `VAR=val` 前缀绕开。
- **补的话怎么补**（备案，不当下动）：在 `guard-pretool.sh` 现有引号感知分段之后、`case` 之前，
  对每个 segment 剥掉**前导 assignment word**（一个或多个），再拿剥后串去匹配前缀 glob。
  **assignment 正则用 `[A-Za-z_][A-Za-z0-9_]*=`**（POSIX shell 允许小写变量名，之前草案的
  `[A-Z_][A-Z0-9_]*=` 会漏掉 `foo=1 git push ...` 这种小写赋值）。
  **不要**用整命令一次性 `grep -qE '(^|[[:space:];&|])git[[:space:]]+push([[:space:]]|$)'`——
  它会误命中 `echo x git push origin main` 与引号内含 `&& git push ...` 的字符串数据，
  正是 `ops/enforcement.md:51-61` 记录的历史误拦（2026-08-10 L3 round-4 N3 实证）。
  改完必跑 `hooks/guard-selftest.sh`；自测必须新增：① 小写赋值前缀绕过 ② 引号内 `git push` 字面量不误拦。
- **用户当下裁定**：先备案不补——补了会同时挡掉我自己 `.guard-off` 之外的 push 路径；
  近期 push 全部改用文件档急停；补不补等未来某次真正让我卡住时再定。
- **诚实澄清**：本任务前 5 次 push（`6fe15de` / `186767d` / `6ac946f` / `5697f18` / `4d9b5f9`）
  在 journal 事件流里被记为"`GUARD_OFF=1` 单次 env-var、零残留"，其实机制是这个 hook 漏洞。
  push 本身按用户授权是合法的，机制描述则是错的。此条留档以纠正记忆。

## [E007] 2026-08-11 · 规则文件涉及 skill 调用时,没读 skill 原文就写规则

- **有效性**:active
- **处置**:未修复(规则文件本身不需要工具修;等未来任务真触发时,派活前扫本条即可)
- **触发场景**:改 `CLAUDE.md` / `ops/empirical-flow.md` 等规则文件,内容涉及"调用某 skill"、"skill 的产出是什么"、"skill 的适用范围"时,凭记忆或推测写。本次 interview-me 规则任务连续三轮 L3 都逮出此类:round-1 #2(brainstorming 与 interview-me 顺序冲突,因未读 skill 契约),round-2 #2(interview-me 禁在非交互子代理上下文),round-3 #2(brainstorming 唯一后继 writing-plans 契约不允许替代 skill)。三轮都是同一根因。
- **正确做法**:改规则前,`Read` 涉及的每个 skill 的 `SKILL.md` 原文——特别看它的"When to use / When NOT" 段、"输出契约"段、"唯一后继"或"下一步"段。skill 路径通常在 `~/.claude/plugins/cache/<marketplace>/<pkg>/<ver>/skills/<name>/SKILL.md` 或 `~/.claude/plugins/marketplaces/<marketplace>/skills/<name>/SKILL.md`。**报告里凡引用 skill 契约的措辞,必须一手引自 SKILL.md 那一行,标出文件路径 + 行号**。这与 `[PRIMARY-SOURCE]`(codex 报告是二手,须回一手工件)是同一类要求:此处 SKILL.md 就是一手。
- **判据(简报里写这句)**:"改的规则里如果出现 skill 名字,先 Read 它的 SKILL.md"。

## [E008] 2026-08-11 · journal 追加位置没读 `ops/journal.md` 就沿用 hook 兜底位置

- **有效性**:active
- **处置**:已修复(本次任务的 journal 已迁到正规位置,旧位置留了历史指针;下次任务应从建档起就正规位置)
- **触发场景**:任务过程中要记 journal 事件,直接追加到 hook `journal-sessionstart.sh` 自动创建的 `projects/-<host>/journal/YYYY-MM-DD-<slug>.md`。**这是错的**——那个 hook 的兜底文件在**顶层 `.gitignore` 的 `projects/`** 里,留痕不入版本历史。ops/journal.md 明规:项目内 `docs/superpowers/journal/`,slug 与 spec/plan 对齐。2026-08-11 interview-me 规则任务 L3 round-1 #3 逮出。
- **正确做法**:命中 `ops/journal.md` §8 "何时建"的任一条 → **先 `Read ~/.claude/ops/journal.md`** → 按 §11 建到 `<项目>/docs/superpowers/journal/YYYY-MM-DD-<kebab-slug>.md`(slug 锚定任务,与 spec/plan 对齐,同一任务永远追加同一份)。若发现已错追加到旧位置:**旧位置只追加"位置纠错指针",建新位置**——只追加不改写历史(否则失去证据价值)。
- **判据(简报里写这句)**:"要记 journal 事件之前,先 `Read ~/.claude/ops/journal.md` 定位置"。

## [E009] 2026-08-11 · 用户明示豁免 Plan-Gate + 扩展 L3 兜底,承接效率显著低于 Plan-Gate 前置

- **有效性**:active
- **处置**:未修复(本条是策略性教训,不修 spec/plan/规则,写入 MISTAKES 供未来同类任务派活前扫)
- **触发场景**:规则文件变更类任务,用户明示豁免 Plan-Gate 走扩展 L3 兜底(CLAUDE.md §2.2 三件事的合规豁免路径)。本次 interview-me 任务实证代价:走扩展 L3 → 4 轮 L3(round-1 4 致命 / round-2 5 致命 / round-3 5 项必修 / round-4 5 项致命)+ 4 版 rev(rev-1 → rev-4);每轮都逮真问题、每次 rev 都引入下一轮的新问题。若走 Plan-Gate 前置,估计 1-2 轮 sol ultra 就能拦下大部分方向性/契约冲突/跨文件一致性问题。原因:落地后审的 sunk cost 更高、修法是补丁式、易漏跨文件镜像;Plan-Gate 前置审 spec/plan 时改动便宜、且四维单审天然覆盖跨文件一致性视角。
- **正确做法**:**规则文件变更、跨文件同步类任务默认走 Plan-Gate 前置,不走豁免**。若用户明示要豁免,L0 应主动提醒本条实测代价("上次同类走豁免用了 4 轮 L3、4 版 rev,而 Plan-Gate 前置估计 1-2 轮就能收")并请用户确认;豁免仍是用户权利,但应知情选择。豁免走后必须严格按 §2.2 三件事(声明 + journal 留痕 + 扩展 L3)全做齐。
- **判据(简报里写这句)**:"用户明示豁免 Plan-Gate 之前,先讲清 E009 实测代价"。
<!-- 抽自 CLAUDE.md + ops/,追加到 ~/.claude/docs/superpowers/journal/MISTAKES.md 末尾 -->

## [E010] 2026-08-05 · 用户明示豁免 Plan-Gate 后,spec 内部自相矛盾未被拦下

- **有效性**: active
- **处置**: 已规避(用户 2026-08-11 加入"豁免时必用扩展 L3 简报"规则,见 CLAUDE.md §2.2)
- **触发场景**: 用户明示豁免前置 Plan-Gate 走扩展 L3 兜底路径。
- **正确做法**: 扩展 L3 简报必须**把用户原话 + spec + plan + 产出一并喂入,明令覆盖 Plan-Gate 原四维(需求误解 / 过度设计 / 更优解 / 拆解质量)+ 落地正确性 + 跨文件一致性**。常规 L3 只覆盖正确性/安全/边界/跨文件,不必然重审方向性维度;不加这段简报,自相矛盾等问题会静默通过。**不得声称与前置审等价**。
- **判据(简报里写这句)**: "本次豁免 Plan-Gate,扩展 L3 简报必含用户原话 + 明令覆盖 Plan-Gate 原四维"。

## [E011] 2026-06-23 · L3 逐轮 12 轮全 GO,冻结态合并审才逮出 fail-open

- **有效性**: active
- **处置**: 已规避(规则已加"按 L3 意见改完后必须对最终态再跑一次终检",CLAUDE.md §2 收口节)
- **触发场景**: L3 逐轮修改 → 每轮 GO → 直接推送。
- **正确做法**: 按 L3 意见改完后,**必须对【最终态】再跑一次终检**。逐轮审的是"移动靶",每轮 GO 只对当轮那一版成立;修 A 引入 B 前几轮结构上看不见。只有"补证据"或"经核验判定为误报"可书面放行不重审;改了代码/文档内容一律重审。
- **判据(简报里写这句)**: "L3 修完不直接推,必对冻结态再跑一次终检"。

<!-- E012/E013 是跨项目方法论,按 CLAUDE.md §6「记忆三层」+ ops/journal.md「项目错误档 / 收什么」规则,已移到 memory:
     - `convention-mistaken-for-evidence.md` (原 E012 内容,memory 已存)
     - `codex-report-secondhand-must-verify.md` (原 E013 内容)
     不占本 MISTAKES 编号;E011 之后跳到 E014。
     ⚠️ 此次删除属**经用户 Q6 明示的一次性错层迁移例外**——本档头部"只追加"纪律仍然生效,除此之外不得删条 -->


## [E014] 2026-08-05 · guard 判定漏用引号感知分段,两次误拦

- **有效性**: active
- **处置**: 已修复(guard-split.py 引号感知分段 + 前缀 glob 匹配;判定逻辑改必同跑分段器单测)
- **触发场景**: 加/改 guard 拦截规则。
- **正确做法**: guard 判定用 `hooks/guard-split.py` 的**引号感知分段**(只在**引号外**的 `; \| & 换行` 处切),再要求该段**以目标动作开头**。**禁用整串子串匹配或按 `; & |` 无引号语义分段**——两者会分别误拦"测试脚本里的字面量"和"JSON 字符串内的分隔符"。改判定逻辑必同时跑分段器独立单测。
- **判据(简报里写这句)**: "改 guard 拦截规则前,读 hooks/guard-split.py 与它的单测,不用子串匹配"。

## [E015] 2026-08-07 · 忘删 `~/.claude/.guard-off` 致整套 guard 静默失效

- **有效性**: active
- **处置**: 已规避(CLAUDE.md §5 加"急停后立即恢复"约束 + selftest 大批 FAIL 时先查此文件)
- **触发场景**: 用文件式急停 `touch ~/.claude/.guard-off` 关 guard 后忘删。
- **正确做法**: 用完**立即** `rm -f ~/.claude/.guard-off`——不删则整套 guard 静默失效(`guard-selftest.sh` 全返回 0 才发现)。**selftest 大批 FAIL 时,先查这个文件在不在**再查判定逻辑。
- **判据(简报里写这句)**: "guard selftest 一堆 FAIL 或 guard 感觉失效 → 先 ls ~/.claude/.guard-off"。
