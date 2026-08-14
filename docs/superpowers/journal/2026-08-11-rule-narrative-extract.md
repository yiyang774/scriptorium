# journal · 规则文件叙事清理(CLAUDE.md + ops/)

<!-- 头部状态快照(每次覆写,5 字段;事件流下方"只追加、绝不改写历史") -->

- **进行到**: rev-5 微修完成;L3 round-4 有条件 GO(审查者明说无需 round-5);L0 已就地收口裁定
- **下一步**:
  1. 机械核验(grep 强制词 / rg 行号)
  2. PR-GATE 单独问用户(不推定)
  3. 推送
- **未决问题**: 无(Q1-Q6 已拍板;rev-5 全按 round-4 "收口条件"清单)
- **关键路径文件**(rev-3 冻结态实际行数):
  - spec: `~/.claude/docs/superpowers/specs/2026-08-11-rule-narrative-extract.md`(100 行)
  - plan: `~/.claude/docs/superpowers/plans/2026-08-11-rule-narrative-extract.md`(103 行,rev-3/rev-4 已修 guard 指针 E010/E011 → E014/E015 + E012 案例误分类)
  - CLAUDE.md: 224 行(已抽 17+ 处叙事)
  - ops/enforcement.md: 182 行(217→182)
  - ops/plan-gate.md: 141 行(155→141)
  - ops/project-layout.md: 137 行(150→137)
  - ops/empirical-flow.md: 429 行(440→429)
  - ops/preflight.md: 117 行(137→117 全文重写)
  - ops/journal.md: 38 行(46→38)
  - ops/codegraph.md: 38 行(44→38)
  - ops/journal-templates.md: 104 行(219→104 压成 line-count.md 指针)
  - MISTAKES.md: 270 行,13 条 active(E001-E011 + E014-E015;E012/E013 已按 Q6 移 memory,tombstone 保留)
  - memory `codex-report-secondhand-must-verify.md`: 26 行(rev-2 新建)
  - memory `convention-mistaken-for-evidence.md`: 31 行(已存,原 E012 内容)
  - memory 索引 MEMORY.md: 加了新条目
  - L3 round-1 out: `~/.claude/.plangate/l3-2026-08-11-narrative/out.txt`(103 行,NO-GO 5 项方向性)
  - L3 round-2 out: `~/.claude/.plangate/l3-2026-08-11-narrative-round2/out.txt`(93 行,NO-GO 2 项方向性)
  - L3 round-3 out: `~/.claude/.plangate/l3-2026-08-11-narrative-round3/out.txt`(58 行,NO-GO 4 项方向性,无致命)
  - L3 round-4 out: `~/.claude/.plangate/l3-2026-08-11-narrative-round4/out.txt`(59 行,**有条件 GO**,rev-5 微修已闭环)
- **已定裁决**(每条含结论+理由):
  - **规则纯净优先(用户 Q1)**: ops/CLAUDE.md 只留"是什么/怎么做/门槛";叙事全抽走
  - **归宿分工两处(用户 Q4)**: 复用型教训→ MISTAKES;一次性(用户裁定、A/B 数据、老实测)→ 本 journal 附录
  - **不留反向指针(用户 Q3 隐含)**: 抽走后不写"详见 journal:LXXX",指针也是污染
  - **不改规则强制性**: 只搬叙事、不动"必须/禁止"等门槛语义
  - **豁免 §2 第 1 步 brainstorming + writing-plans skill + Plan-Gate 前置**(用户 Q5 明示,§2.2 三件事全做齐):
    - ①声明(在会话)✓
    - ②本 journal 留痕 ✓
    - ③落地后【扩展 L3 xhigh】兜底(简报覆盖 Plan-Gate 原四维 + 落地正确性 + 跨文件一致性)
  - **已知 E009 代价**: 上次同款路径 4 轮 L3 + rev-1→rev-4 + 3 项未修元文档漂移;用户明知仍选此路径
  - **PR-GATE 不推定**: 到时单独问用户,不能沿用上次授权

---

## 事件流(只追加、绝不改写历史)

### 事件 1 · 2026-08-11 用户提议 + interview-me 意图对齐 + Q1-Q5 五轮拍板

- **用户裁定**(§14 七类必记事件之一)
- 用户原话(权威意图源,逐字):
  1. (起头) "你检查一下ops文件夹里面的几个md文件,为啥还在里面写日志啊,这不是增加输入的token吗"
  2. (Q1 优先偏好) "我更在意 (b),叙事归教训档,尤其是用户裁定不应该放在日志吗,写在这里干嘛"
  3. (Q2 老裁定归宿) "走 (a),找不到原 journal 就归拢到本次"
  4. (Q3 保留震慑) "震慑不重要,规则纯净优先"
  5. (Q4 教训归宿) "两处分工:复用型教训抽 MISTAKES(预计 4-6 条)"
  6. (Q5 豁免深度) AskUserQuestion 选 B "全跳(含 Plan-Gate 前置),走扩展 L3 兜底"
  7. (加速语) "Yes,我觉得这种改文本的任务就直接改吧"——L0 用 AskUserQuestion 澄清豁免范围到 Q5 上句 B
- interview-me restate + explicit yes(见本文件 Outcome/User/Why now/Success/Constraint/Out of scope)
- L0 澄清动作:AskUserQuestion 问明"直接改"是走 §2.2 豁免路径还是保留 Plan-Gate,防静默豁免(呼应上次 interview-me 任务事件 4)
- 证据指针:本次对话主线;interview-me skill 已 invoke;5 轮 AskUserQuestion 交互记录

<!-- 后续事件流位于附录 A 之后(rev-1 建档时把附录夹在事件之间的排序,rev-3 保留历史顺序不重排) -->

---

## 附录 A · 从规则文件抽出的一次性叙事(用户裁定 + A/B 数据 + 老实测)

<!-- 收拢所有从 ops/ + CLAUDE.md 抽出的一次性叙事,按抽出时的原位置和日期排 -->

<!-- 附录 A.1: CLAUDE.md 抽出条目(rev-1 记录) -->
<!-- 追加到 ~/.claude/docs/superpowers/journal/2026-08-11-rule-narrative-extract.md 的"附录 A" -->

<!-- 抽自 CLAUDE.md,按原位置 + 原日期排 -->

### CLAUDE.md · L65(preflight §2.3 提示)· 74 条历史错误统计

**原文**:每条检查都对应一次真实踩过的坑,且**已实测能报警**(本机跑就逮出坏解释器与 bash 3.2)。**跳过的代价是实测过的**:74 条历史错误里 16 条是"跑挂了才发现",其中 `/tmp` 填满只跑成 550/800 局、BLAS 超订 49 分钟零产出、漏设 flag 致双模型 OOM、GPU 容器无 EGL 整条路线堵死——全是查一条命令就能避免的。

### CLAUDE.md · L99(§3 铁律 3 [DELEGATION-BAND] 补注)· 2026-08-05 自检禁令扫描实测

**原文**:自检为汇报会逐字写出禁词,留在交付物里会让全文扫描命中一片、检查形同虚设——2026-08-05 实测。

### CLAUDE.md · L108(§3 铁律 4 空输出注)· 会话内连撞四次

**原文**:实测同一场会话内连撞四次(`find` 超大目录被中断而 stderr 为空、macOS 没有 `timeout` 致 `|| VAR=""` 吞掉错误、`wc -c` 数字节被当字符、多层引号嵌套写坏使断言假失败)——**每次都据此下了错误结论**。(注:4 例已归 MISTAKES E001-E004,此处只记"同一场会话四撞"这个总数据)

### CLAUDE.md · L116(§3 铁律 5 [PRIMARY-SOURCE])· 2026-07-27 WebFetch 网络策略实测

**原文**:实测(2026-07-27,本机 Claude 侧):`WebFetch` 对 `anthropic.com` / `claude.com` / `github.com` / `philschmid.de` **全部被网络策略挡下**;codex 侧 `CAN_FETCH` 正常。

### CLAUDE.md · L122(§3 铁律 5 取回后必须核对)· 一次取材推翻三处引用

**原文**:实测一次取材推翻了三处引用(把已弃用的旧算法当现行、把带警告的混合均值当普适结论、把别处的条款安到另一节上)。

### CLAUDE.md · L140(§3 铁律 11 两轮上限)· 2026-08-07 连跑五轮

**原文**:2026-08-07 实测教训:实测曾连跑五轮,后两轮多在讨论检查器本身,属 `[OWNERSHIP]` 的"被持续异议无限否决"。

### CLAUDE.md · L141(§3 铁律 11 简化说明)· 2026-08-05 用户裁定 Plan-Gate 简化

**原文**:2026-08-05 用户裁定简化:原为"方向关 3 视角互盲 panel + 拆解关单审"共 4 个 ultra 进程、两段式接力,**判定过严、成本过高**,改为上述单进程四维单审。**异构性不变**(仍是 Codex 对 L0 的异构 frontier 审查),变的只是并发度与关卡数。

### CLAUDE.md · L163(§4 合适数量)· 2026-08-05 Plan-Gate 固定 1 个 sol ultra 单审

**原文**:Plan-Gate 固定 1 个 sol ultra 单审(2026-08-05 简化)。

### CLAUDE.md · L164(§4 子代理类型指针)· L3 拆多路实测有效

**原文**:见 `~/.claude/ops/plan-gate.md`(agent 类型对照 + 拆路实测效果)。

### CLAUDE.md · L165(§4 执行档 luna max)· 2026-08-07 用户裁定

**原文**:codex 推理强度:luna 一律 max(执行与 L2 快审同档,2026-08-07 用户裁定)。

### CLAUDE.md · L167(§4 独立审查关卡的原则式定义)· 已实测漏过两次

**原文**:此处不枚举,枚举必漏——已实测漏过两次。

### CLAUDE.md · L174-177(§5 承诺闸 + .guard-off)· 2026-08-05 新增承诺闸 / 2026-08-07 .guard-off 忘删

**原文 1**(承诺闸来由):承诺闸(2026-08-05 新增):治的是"说了要做、然后结束回合"——实测踩过:声明"这条豁免我会记进 journal 留痕"后直接收尾,留痕没做,靠下一轮自查才补上。

**原文 2**(.guard-off 忘删):⚠️ 实测(2026-08-07):忘删 `.guard-off` 导致整套 guard 静默失效,自测里 13 项"应拦"用例全返回 0 才发现。(具体触发已归 MISTAKES E015)

### CLAUDE.md · L193(§6 hook 兜底时间)· 2026-07-26 落地

**原文**:会话边界(启动/结束/压缩)已有 hook 兜底(`~/.claude/hooks/`,2026-07-26 落地并实测)。

### CLAUDE.md · L207(§8 命令实测踩坑)

**原文**:参数顺序、沙箱档位、非 git 目录的 `--skip-git-repo-check`、heredoc 与 `</dev/null` 互斥,全是实测踩出来的;写错会静默失效或被护栏挡下。

### CLAUDE.md · L210(§8 Plan-Gate 简化 + 退役)· 2026-08-05

**原文**:Plan-Gate 形态已于 2026-08-05 简化为「1 个 sol ultra、subagent 形式、四维单审、spec+plan 同审」——`ops/plan-gate.md` 里的三视角互盲 shell 脚本与 `plan-gate-direction` 图化版**均已退役,不得再发起**。

<!-- 附录 A.2: ops/ 抽出条目(rev-2 记录) -->

### ops/enforcement.md · L51-65 · 引号感知的两次误拦来由

**原文摘要**: 上线当天连撞两次误拦:① 整串子串匹配 `case "$CMD" in *"gh pr merge"*)` 让测试脚本里的字面量被拦(被测数据 ≠ 被执行命令);② `sed` 按 `;&&||` 无引号语义分段,`P='{"cmd":"cd /tmp && gh pr merge 9"}'` 里的 `&&` 被切开,后半段以 `gh pr merge` 开头仍误拦。改为 `guard-split.py` 引号感知分段 + 段首匹配。**方法论已入 MISTAKES E014**。

### ops/enforcement.md · L67-79 · 急停实测陷阱

**原文摘要**: `export GUARD_OFF=1 && <被拦命令>` 无效——钩子在命令执行**之前**跑,环境变量还没生效。改用文件式 `touch ~/.claude/.guard-off`。**忘删致 guard 静默失效,selftest 13 项"应拦"全返回 0 才发现**。**方法论已入 MISTAKES E015**。

### ops/enforcement.md · L138-141 · 承诺闸来由(2026-08-05 新增)

**原文摘要**: 声明"这条豁免我会记进 journal 留痕"后直接收尾、留痕没做,靠下一轮自查才补上。与证据闸同源:**打算做和已经做在生成时主观确信度完全相同**,中间没有"我还没做"的信号。据此 2026-08-05 加了承诺闸(见 `ops/enforcement.md §5`)。

### ops/enforcement.md · L154-162 · preflight-l2-reminder.sh 静默失效 + 通用规则

**原文摘要**: `settings.json` 里 `preflight-l2-reminder.sh` 原写 `$CLAUDE_PROJECT_DIR/.claude/hooks/...`,但该脚本实际在 `~/.claude/hooks/`。在 `motivation-figure`、`paperI_motivation` 等项目下路径不存在 → hook 静默失效。已改绝对路径 + 通用规则(用户级 hook 必须写绝对路径)。

### ops/enforcement.md · L179-201 · 命令反例误拦裁定(2026-08-05 用户裁定选 B)

**原文摘要**: heredoc 写文档时,正文引用一条反例命令,被 🔴 拦截 2 拦下(分段器切段后半以 `codex exec` 开头,判为"审查调用缺 `-s read-only`")。**用户 2026-08-05 裁定选 B: 改文档写法,不改 guard**(护栏零削弱)。理由:"是示例不是命令"要读意图,guard 只能看字符串;误拦代价是换写法,漏拦代价是审查者带写权限跑起来——宁可误拦。

### ops/plan-gate.md · L28-40 · A/B 对照表(2026-08-05,同脚本 luna low)

**摘要**: 10 行本地日志脚本, A/B 对照带不带威胁模型段。**A(不带)6 问题,4 是威胁模型错配噪音;B(带)3 问题全真,还多逮 1 个 A 漏掉的换行伪造多行日志 bug**。注意力不被理论风险占用,真问题看得更清。

### ops/plan-gate.md · L46 · L3 双路互盲(2026-08-05 Paper I 正文)

**原文数据**: 两路各 30 条意见,独立逮到同一条致命项(定理条件写错)互为佐证;其余基本不重叠——一路抓测试集污染与预注册泄漏,另一路抓算术矛盾与维度对不上。

### ops/plan-gate.md · L74 · 时点分两条路(2026-08-07)

**原文**: 2026-08-07 起 Plan-Gate 时点分两条路: 标准流水线派活前必过;实证流拿到实验数据、L0 写出 spec/plan 后过(第 ⑧ 步)。

### ops/plan-gate.md · L83 · 形态简化(2026-08-05 用户裁定)

**原文**: 2026-08-05 用户裁定简化为"1 个 sol ultra + subagent + 四维单审 + spec+plan 同审";此前旧脚本(三视角互盲 shell + `plan-gate-direction` 图化版)均已退役。

### ops/plan-gate.md · L144 · guard 交付案例(2026-08-05)

**原文**: L3 曾把"字符串匹配可被有意规避"列为阻断项,而该脚本定位本就是"防手滑、不防有意规避",已在文档写明——属威胁模型错配。据此定"审查简报必带【环境与威胁模型】段"。

### ops/plan-gate.md · L51 · luna max 定案(2026-08-07 用户裁定)

**原文**: 2026-08-07 用户裁定 luna 一律 `max`,不再分 low/medium/high。理由: 省档带来的时间收益不值得拿产出质量换。

### ops/project-layout.md · L6 · 目录规范动因(2026-08-05)

**原文**: `motivation-figure` 同时存在 `output/` 与 `outputs/`;`paperI_motivation` 实验数据散在 `exp_data/` `pilot_data/` `_diag_ck5/` `alfworld_data/` `archive/` `deliverables/` 六处,`__pycache__`、`keys.local.txt` 躺在根目录。查一次结果要翻六个地方——本规范就是为消除这个。

### ops/project-layout.md · L119-124 · 首次体检实测(2026-08-06)

**原文**: 60 条笔记查出 **11 项**问题——5 个悬空链接(3 个是 `paperi` vs `paperI` 大小写不一致,macOS 不区分大小写所以一直没被发现)、7 条 frontmatter `name` 与文件名不符、索引漏列 3 条、1 条 description 只写"B3"两个字。**全部是肉眼扫不出来的结构性问题**,这就是要有脚本的原因。

### ops/project-layout.md · L134-140 · 记忆三层重构实测(2026-08-07)

**原文**: 全局原有 61 条,其中 **52% 是 paperI 的实验细节**(如"#129 阶段 1 已完成、7 个 commit 未 push"),每次会话都占索引位置却与当前任务无关。下沉 29 条到 paperI、9 条到 innovation-hunt 后,**全局 61→22 条、索引 64→34 行**。同一发现地(paperI)不同笔记性质可能完全不同:`blas-oversubscription-trap` 属跨项目教训留全局,`paperi-b3-129-stage1` 只对该项目有意义下沉。

### ops/empirical-flow.md · L386-388 · CLAUDE.md 重构五个漏洞

**原文**: CLAUDE.md 那次 L3 一轮逮到 **5 个真漏洞**(Plan-Gate 过审后改动无重审判据、L3 改完不重审、PR head 变化不重审、guard 急停无约束、Gate 适用范围不一致)——**全是在成品里才显形的**,四轮 Plan-Gate 一个都没发现。

### ops/empirical-flow.md · L6-15 · 前置 Plan-Gate 反例(2026-08-03)

**原文**: CLAUDE.md 重构一次跑了四轮 Plan-Gate 共 64 条意见,r1 真问题、r2-r4 大部分是"修 r1 引入越界"→"修 r2 删改不同步"→"修 r3 新引入"——**后三轮过半是审查自己诱发的**。同一份文件 L3 终审一轮 5 真漏洞,因为它审的是**成品**。2026-08-07 用户裁定: Plan-Gate 未取消,只是移到第 ⑧ 步——"新方案的产出还是需要过 Plan-Gate,不能仅仅听 codex sol ultra"。

### ops/preflight.md · L27-117(各 `> 踩过` 段) · 74 条 replay 里的 10 条 preflight 覆盖坑

**一行事实摘要**(编号是历史事故号):#57 坏 anaconda3.8 → sklearn 报错;#58 macOS bash 3.2 无 `declare -A`;#55 `pgrep -f` 匹配自身;#41 `/tmp` 被 fast_downward 填满 800→550 局;#43 208 核开 20 worker BLAS 49 分零产出;#42 41 层张量驻留 GPU 失联 4h;#39 漏 `B2_LOAD_MODEL` 双模型 OOM;#74 AutoDL 无 EGL 渲染堵死;#36 漏 `chat_template.jinja` Gemma crash;#56 SSH 重试触发限流被误归因。

### ops/codegraph.md · L28-32 · paperI_motivation 实测(2026-08-05)

**原文**: `impact cluster_bootstrap` 报 **68 个受影响符号**,其中 **36 个所在文件从头到尾没出现过该符号名**——grep 永远找不到,且这 36 个里 **33 个是测试**。对症的事故: `delta_c_bootstrap` 双重 bootstrap 把置信区间压窄 **28 倍**。全仓开销: **4,930 节点 / 12,423 边、索引耗时 1.3 秒、产物 16 MB**。

### ops/journal.md · L24-31 · 便宜模型做纪要连续三次失败(2026-08-07)

**原文**: 原设计把 transcript 喂 Haiku 提炼六类事件。但 transcript 满是 guard 提示、AskUserQuestion 之类"指令样"文本,Haiku 反复误以为那是给自己的任务——改提示词、从源头过滤噪声都没根治。**改机械抽取后: 88 秒 → 0.1 秒,零污染,100% 可复现**。更一般教训:"忘了去记"靠 hook 解决(不依赖记忆);"记得不准"靠机械抽取解决(不依赖理解)。

### ops/journal-templates.md · L99-219 · 行数复核完整实现(rev-1 阶段就地保留)

**原文**: journal-templates.md 从 L99 到 L219 保存了完整的 `snap()` 实现、非 git 目录快照方案、7 类已发现漏计情形对照表(git diff 工作区/临时 index 空起手/`git add -A` 不加 --force/LFS clean filter/子模块/其他 clean filter 来源/符号链接指向计量根之外)、兜底判据、归类规则、已知残余风险。**rev-2 已压成一行 `line-count.md` 指针**;原实现完整版仍在 `~/.claude/ops/line-count.md`(唯一事实源)。

### 事件 2 · 2026-08-11 rev-1 交付 + 扩展 L3 round-1 启动

- **派活 + 交付**(§14 七类必记事件)
- **派谁**: L0 自己(§3 非代码文档不套行数带)
- **rev-1 修法**(初次抽 CLAUDE.md + 5 个 ops 文件叙事):
  - CLAUDE.md 232 → 224 行(17+ 处叙事段大幅压缩)
  - ops/enforcement.md 217 → 188(-29,删引号感知误拦来由 + 急停实测陷阱 + 承诺闸来由 + 顺带修复的 bug + 命令反例误拦裁定)
  - ops/plan-gate.md 155 → 141(-14,删 A/B 对照表 + Paper I 双路 + guard 交付案例)
  - ops/project-layout.md 150 → 137(-13,删 motivation-figure 动因 + 首次体检 60→11 + paperI 前缀对照)
  - ops/empirical-flow.md 440 → 432(-8,删 2026-08-03 CLAUDE.md 重构 64 条案例)
  - ops/preflight.md 137 → 137(2 处小改:scipy 实测日期 + pgrep 实测确认)
  - MISTAKES 9 → 15 条(新建 E010-E015 收拢复用型教训)
  - 新建 spec/plan/本 journal(附录 A 收拢 13 条 CLAUDE.md 抽出的一次性叙事)
- **L3 round-1 启动**:
  - 简报: `~/.claude/.plangate/l3-2026-08-11-narrative/brief.txt`
  - 后台任务 `bqip4zey2`(bash → codex xhigh),exit 0
- **证据指针**: git diff CLAUDE.md ops/*.md;3 新文件路径见头部快照

### 事件 3 · 2026-08-11 L3 round-1 判决: NO-GO(5 项方向性,审查者明确"不是漂移信号")

- **L3 审查**(§14 七类必记事件),第 1 轮
- **按 L3 自身分级**: 5 项方向性 + 若干非致命
- **逐项分诊**:
  - #1 维度①: **抽得不够狠**——preflight/empirical-flow/enforcement/project-layout 仍留大量叙事(74/10/64 数据、五个漏洞旧案、三次错误结论、paperI 个案) → **rev-2 深清**
  - #2 维度③: **journal-templates.md L99-220 重复整套 line-count 实现**(~120 行,每次建 journal 都读入),而 CLAUDE 已把唯一事实源指向 line-count.md → **rev-2 压成一行指针**
  - #3 维度⑤: **反向指针错**——CLAUDE 豁免代价见 E010 实际 E009;plan-gate 两处威胁模型错配见 E012 实际 E012 是"约定的回声" → **rev-2 修**
  - #4 维度④: **journal 头部快照仍写"待补"**,断片重读诱导重复工作 → **rev-2 刷**
  - #5 维度③: **把有界案例压成泛化事实**("多数目标域名"其实原证据只 4 个) → **rev-2 回退到规则本身**
  - 非致命 #a: MISTAKES 触发场景装了完整叙事,工具会逐字注入子代理 → rev-2 部分压缩
  - 非致命 #b: E011/E015 日期为 XX-XX 占位符 → rev-2 修
  - 非致命 #c: E009/E010 重叠 → rev-2 保留(轻度)
  - 非致命 #d: 附录未收 ops 部分 → rev-2 未完成(留 rev-3 或不做)
  - **维度⑥ 归宿冲突**: E012/E013 是跨项目方法论,按现规则应归 memory 非 MISTAKES → **需用户拍板 Q6**
- **证据指针**: `~/.claude/.plangate/l3-2026-08-11-narrative/out.txt`(103 行)

### 事件 4 · 2026-08-11 用户 Q6 拍板 + rev-2 修法交付

- **用户裁定**(§14 七类必记事件),第 6 轮拍板
- L0 用 AskUserQuestion 就 E012/E013 归宿问用户(A 严按规则移 memory / B 修改归宿定义放宽 MISTAKES / C 两处都放)
  - **用户选**: **A · 严按规则移到 memory**(MISTAKES 只留 E010/E011/E014/E015 本项目特有)
- **rev-2 修法交付**(修 L3 round-1 5 项 + Q6 拍板):
  - 深清 preflight.md 全文重写(137 → 117):删十段"踩过"故事,操作规则保留
  - 深清 empirical-flow L386(五个漏洞旧案压成一句话)
  - 深清 enforcement L85(三次错误结论压成"共同点判据")
  - 深清 project-layout L128(paperI 个案匿名化)
  - 深清 ops/journal.md L15-31(会话事实抽取叙事压成规则)
  - 深清 codegraph.md(去掉具体项目名和数字)
  - **journal-templates.md L99-220 → 一行指针**(219 → 104,-115)
  - 修反向指针:CLAUDE L56 "见 E010" → "见 E009";plan-gate 两处 "见 E012" 删除
  - 回退过度泛化:CLAUDE L110 "多数目标域名" → "常被网络策略挡下"
  - 修 MISTAKES 日期:E011 → 2026-06-23;E015 → 2026-08-07
  - **删 MISTAKES E012/E013**(移 memory);MEMORY.md 索引加新条目
  - **新建 memory** `codex-report-secondhand-must-verify.md`(原 E013 内容)
  - 压缩 MISTAKES E010/E011/E014/E015 触发场景(减少 `bin/mistakes` 注入 token)
  - CLAUDE 里对应指针改为"方法论详见 memory `<name>`"
- **累计交付**(rev-1 + rev-2):
  - CLAUDE.md + ops/* 从 1826 → 1596 行(-230,-13%)
  - 单行 token 密度显著下降(叙事段被压)
  - MISTAKES 13 条(E001-E011 + E014-E015;E012/E013 移 memory 留洞)
  - memory 新增 1 条 + MEMORY.md 索引更新
- **L3 round-2 启动**:
  - 简报: `~/.claude/.plangate/l3-2026-08-11-narrative-round2/brief.txt`(冻结态终审)
  - 后台任务(下条 Bash 发起)

### 事件 5 · 2026-08-11 L3 round-2 判决 + rev-3 修法交付

- **L3 审查 + 派活+交付**(§14 七类必记事件)
- **L3 round-2 判决**: NO-GO 2 项方向性(审查者明说"不需扩大清理范围,完成两项后做窄复核即可"——即将收敛)
  - 维度①: 附录 A 未收 ops 部分 → **需补严格 Q2/Q4 执行**
  - 维度④: journal 头部未真正刷新("待建/待清"字样);plan 里 guard 教训指针 E010/E011/E012 与最终 E014/E015/memory 不符
  - 非致命 #a: MISTAKES 迁移说明写 `ops/journal.md §35` 但实际归宿规则在 L28 → 改稳定标题指针
  - 非致命 #b: MISTAKES tombstone 应加"经用户 Q6 明示例外" → 已加
- **rev-3 修法**(全是审查者明说的局部修复):
  - 补附录 A.2:ops 一次性叙事 15+ 条(enforcement 5 + plan-gate 5 + project-layout 3 + empirical-flow 2 + preflight 事故列表 + codegraph + journal + journal-templates)
  - 覆写 journal 头部快照到 rev-3 真实状态(所有文件真实行数、L3 round-1/2 结论指针)
  - 清占位符"事件 2 待补/事件 3+ 待补"(rev-1 建档时误留)
  - plan 更新 guard 教训指针:E010/E011/E012 → E014/E015(rev-2 归宿修正后的实际映射)
  - MISTAKES tombstone 用稳定标题指针("§35" → "「项目错误档 / 收什么」") + 加"经用户 Q6 明示的一次性错层迁移例外"
- **rev-3 未做**:审查者明说"不应继续扩大到逐句清理 fable5.md、pr-merge.md 或重写 line-count.md,那已是漂移信号"——本轮**不做**
- **累计交付**(rev-1 + rev-2 + rev-3):
  - CLAUDE.md + ops/* 从 1826 → 1596 行(-230,-13%)
  - MISTAKES 13 条 active(E001-E011 + E014-E015);memory 新增 1 条 + MEMORY.md 索引更新
  - 附录 A 完整归档 CLAUDE 15 条 + ops 15+ 条一次性叙事
- **L3 round-3 窄复核启动**(下条 Bash 发起)

### 事件 6 · 2026-08-14 L3 round-3 判决 + rev-4 修法交付

- **L3 审查 + 派活+交付**(§14 七类必记事件)
- **L3 round-3 判决**: NO-GO 4 项方向性,无致命(审查者明说"未发现重复漂移,均可局部修复,做一次同范围窄复核即可"——即将 GO)
  - 维度②: 附录 A.2 过细(101 行 9K)——A/B 表和 preflight 十条整段重发,不符合"简短列表"
  - 维度④: journal 头部下一步仍写"补 ops 附录"但已完成;spec/plan/memory 无实际行数;MISTAKES 268→270;事件流"事件 5+/事件 6 待补"占位符
  - 维度④: plan L40 新称 guard 案例"不是威胁模型错配",与附录冲突;plan 无 E012→memory 映射
  - 维度⑤: 附录行号 4 处错(enforcement L154-158 应 L160-162;project-layout L131-134 应 L134-140;journal-templates L99-220 应 L99-219;preflight 缺 file:line)
  - 非致命: 附录 L137 新增 "2026-XX-XX" 占位符不是原文
- **rev-4 修法**(全按审查者"仅需清单"局部修复):
  - 压短附录 A.2:A/B 对照表 12 行→1 行摘要;preflight 十条事故→1 行编号列表
  - 修附录 4 处行号 + 删 "2026-XX-XX" 占位符
  - journal 头部真正刷新:改"下一步"为"起 L3 round-4";加 spec/plan/memory 实际行数;MISTAKES 268→270;加 L3 round-3 out 指针
  - 清占位符"事件 5+ 待补"和"事件 6 待补"
  - plan 修 guard 案例分类:改回"是威胁模型错配"(round-3 指出与附录冲突);加"E012→memory 已修" 说明
  - MISTAKES tombstone 已在 rev-3 用稳定标题指针("§35" → "「项目错误档 / 收什么」") + 加"经用户 Q6 明示例外" —— round-3 通过
- **L3 round-4 窄复核启动**(下条 Bash 发起,同 rev-3 范围)

### 事件 7 · 2026-08-14 L3 round-4 有条件 GO + rev-5 微修 + L0 就地收口裁定

- **L3 审查 + L0 裁定**(§14 七类必记事件)
- **L3 round-4 判决**: **有条件 GO** —— 无致命项;仅几处"round-3 清单机械残留",审查者明说"完成后**无需扩大审查范围或再开完整 round-5**,做一次机械核验即可"
- **通过项(round-4 明写)**:
  - A/B 对照压成一行摘要 ✓
  - preflight 十条压成编号列表 ✓
  - "下一步"改为启动 L3 round-4 ✓
  - spec 100 / plan 103 / memory 26+31 / MISTAKES 270 与实测一致 ✓
  - round-3 out 指针存在 ✓
  - plan guard 案例已恢复"是威胁模型错配" ✓
  - E012/E013→memory 映射已写明 ✓
  - MISTAKES tombstone 稳定标题指针可由 ops/journal.md L27 定位 ✓
  - 未漂移到 fable5.md/pr-merge.md/line-count.md ✓
- **rev-5 微修**(全按 round-4 "收口条件"清单):
  - 附录 CLAUDE.md L65 标题删 "2026-XX-XX" 占位符
  - 附录 journal-templates 正文"L99 到 L220" → "L99 到 L219"
  - 附录 enforcement 标题 "L160-162" → "L154-162"(覆盖完整两段)
  - 附录 preflight 标题 "L27-115" → "L27-117"(#56 SSH 事故在 L116-117)
  - 清占位注释 "事件 6 追加在 rev-4 修法完成后"(已过期)
  - 清占位符 "事件 7 在 rev-4 GO + 收口 + 推送后补"(rev-4 新加,应删)
- **L0 就地收口裁定**(§2.2 精神):
  - L3 已到 round-4;审查者明说"无需再开 round-5"
  - rev-5 微修全是审查者点出的机械残留(非新问题、非漂移、非致命)
  - 按 §2.2 "两轮上限精神是防死盯不放,新真问题继续修属合规"——本次前几轮均逮真问题,rev-5 微修是最后清尾,不再开 round-5
  - L0 决定:rev-5 完成后**机械核验通过即收口**,不再起 L3
  - 若用户对此裁定有异议,可要求起 round-5(未询问,按 §2.2 L0 就地裁定并留痕即可)
- **累计代价**(rev-1 → rev-5):
  - 4 轮 L3 xhigh(round-1 5 项、round-2 2 项、round-3 4 项、round-4 有条件 GO)
  - CLAUDE + ops 总行数 1826 → 1596(-230,-13%)
  - MISTAKES 从 9 条 → 13 条 active + 1 tombstone;memory 新增 1 条
  - 新建 spec/plan/journal(rev-5 微修后总 ~700 行元文档)
  - 呼应 MISTAKES E009 已知代价(用户明知选此路径)
- **下一步**: 机械核验 → PR-GATE **单独问用户** → 推送

<!-- 事件 8 在推送落地后补 -->
