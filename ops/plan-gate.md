# 调用速查（从 CLAUDE.md §8 外置）

> 本文件由 CLAUDE.md 按需引用。**要跑 Plan-Gate / L3 / 派 codex 子代理前，先读本文件**（**L2 的调用形式与判定不在本文件**——见 `~/.claude/ops/l2.md`），
> 不要凭记忆拼命令——这些命令的参数顺序与沙箱档位都是实测定下来的，写错会静默失效或被护栏挡下。


> Codex 运行须知（已实测）：网络 / 鉴权在 Claude 沙箱内即可 headless 跑通（`approval=never`、`-s read-only` 无需审批）；**非 git 目录必须加 `--skip-git-repo-check`**，否则被 codex 护栏挡下；arg 形式可追加 `</dev/null` 免 stdin 等待。

### 🔻 威胁模型声明（**每份 codex 简报都必须带**，逐字复制）

codex 默认按"面向公网的多租户生产系统"设威胁模型，与本机实际环境严重不符，会产出三类噪音：
报一堆不适用的隐患、把理论风险判成阻断级、写个小脚本也堆满防御代码。
`~/.codex/AGENTS.md` 已声明"判为子代理时让位于调用方简报"，故**在简报里写死威胁模型即可覆盖**。

```
【环境与威胁模型】本机单人单用户开发环境，产物不对外提供服务、无多租户、无不可信输入源；
攻击者模型仅限"我自己手滑"，不含恶意第三方。据此：
- 只报**在本环境实际可达**的问题（会真的丢数据、跑错结果、静默失效的）；
- 不报理论风险（命令注入、TOCTOU、权限提升、供应链等）——除非能给出本环境下的具体触发路径；
- 严重度按**实际影响**定，不因"理论上可被绕过"升级为阻断级；
- 写代码时不做过度防御：输入校验、转义、权限检查只在真会出错处加，不预防性铺满。
若你认为某条安全问题确实适用，请**先说明它在本环境下如何被触发**，再给严重度。
```

**例外（此时不要带上面这段，或明确说明产物会对外）**：产物将部署上线 / 对外提供服务 /
处理他人数据 / 进公共仓库 —— 那时真实威胁模型变了，安全审查照常。

**为什么带这段有效**：不带此段时,codex 会按公网多租户模型报大量理论风险(命令注入、TOCTOU、权限提升等),噪音吞没真问题;带此段后 codex 显式写"不报命令注入等,本环境无实际攻击路径",注意力不被占用,真问题反而看得更清。

### 子代理类型与并发形态（从 CLAUDE.md §4 外置）

- **合适用途**（按任务挑类型）：只读搜索 / 摸代码库 → `Explore`（配 sonnet/haiku）；通用执行 / 改代码 → `general-purpose`（sonnet）或 codex 快档；**Plan-Gate 计划审 / L3 终检 → 只用 Codex `gpt-5.6-sol`**（`codex exec -m gpt-5.6-sol -c model_reasoning_effort="ultra"`(Plan-Gate)／`"xhigh"`(终检)，确认走 gpt-5.6-sol）；**L2 快审 → 见 `ops/l2.md`**；写测试 → `test-engineer`（sonnet）；**架构僵局咨询 Fable5 顾问 → 只读工具，见`[FABLE-ADVISOR]`**。
- **L3 终检可按正交视角拆多路并发（建议，非硬要求）**：大体量 / 高风险产出（如整篇论文、跨文件重构）可拆 2–3 路互盲跑，各路简报只给**一个专攻面**（如"主张强度与诚实" vs "数字一致性与纪律"），别给同一份泛泛简报。两路会**独立逮到同一条致命项**互为佐证,其余基本不重叠——不同视角抓不同类型的问题。体量小就单路，别仪式化拆分。

### L1 · 执行（L0 主循环挑档：codex `gpt-5.6-luna` 主力 / Sonnet 深度 / Haiku 轻量）

> ⚠️ 简报里**必带**上方【环境与威胁模型】段——否则 codex 会写出预防性铺满的过度防御代码。
> **推理档：luna 一律 `max`**——执行与 L2 快审同档，不再分 low/medium/high(省档带来的时间收益不值得拿产出质量换)。

- **Codex `gpt-5.6-luna` = 默认主力**（写 / 改代码,含大批量）：
- **Sonnet（需深度理解 / 强耦合）· Haiku（轻量机械）**（`Agent` 工具）：`subagent_type: "general-purpose"`（只读搜索用 `Explore`）；`model: "sonnet"` 或 `"haiku"`；prompt = 自包含简报。并行：一条消息发多个 `Agent` 调用。
```bash
codex exec --skip-git-repo-check -m gpt-5.6-luna -c model_reasoning_effort="max" -s workspace-write -C <工作目录> "<自包含简报>" </dev/null   # 写/改代码
codex exec --skip-git-repo-check -m gpt-5.6-luna -c model_reasoning_effort="max" -s workspace-write -C <工作目录> "<简报>" </dev/null   # 同上（max 为 luna 的统一档）
# 给足权限别卡：跨目录加 --add-dir <dir>；无人值守 / 全自动批量加 --dangerously-bypass-approvals-and-sandbox
# 长简报走 heredoc（⚠️ 走 heredoc 就别再加 </dev/null，二者互斥，否则 stdin 被清空报 No prompt provided）：
codex exec --skip-git-repo-check -m gpt-5.6-luna -c model_reasoning_effort="max" -s workspace-write -C <工作目录> - <<'EOF'
<多行简报>
EOF
```

### Fable 5 · Plan-Gate 架构顾问

> 触发条件与只读细则**见 `~/.claude/ops/fable5.md`（唯一事实源）**，此处不重述——避免两份文档漂移。



### Plan-Gate · 计划对抗审(只读,见 §2.2 / `[PLAN-GATE]`)

> **时点分两条路**：**标准流水线**——派活前必过；
> **实证流**——拿到实验数据、L0 写出 spec/plan 后过（`ops/empirical-flow.md` 第 ⑧ 步），
> 且其 **① 共享测量代码与 ③ 候选原型**属窄例外（探测可以先派，交付不能先派；
> 两类各有标签与范围，见 `ops/empirical-flow.md` §2③ 对照表）。
> 两条路的形态、四维、三闸完全相同，只是发起时机不同。

> ⚠️ 审查简报里**必带**上方【环境与威胁模型】段——否则"过度设计"视角会把
> "没做输入校验 / 没防注入"当成方向性缺陷报上来，而本机环境根本不适用该威胁模型。

> **形态**:**1 个 Codex `gpt-5.6-sol` + `ultra` + `-s read-only`,以 subagent 形式发起,有罪推定单审,spec 与 plan 同审,一次覆盖四维**。
>
> 🚫 **已退役,不得再发起**:① 旧 shell 版"关卡①方向关 3 视角互盲并发 + 关卡②拆解关"两段式脚本;② `plan-gate-direction` 图化版(路径 `~/.claude/workflows/plan-gate-direction.js` 与同名 skill——**该文件已删除,此处仅为退役登记,引用不存在是正常的**)。
> 退役理由:**判定过严、成本过高**(4 个 ultra 进程 + 两段人工接力),且图化版遗留三项未修的 fail-open / 目录竞争待办。**skill 列表里若仍出现 `plan-gate-direction`,视为历史残留,不要调用。**
>
> **四个维度(写进同一份简报,要求逐维给结论)**:
> ① **需求误解** —— 真实意图是否被理解错?把 A 当成 B 没有?
> ② **过度设计** —— 违 YAGNI?有没有更简解?在解决并不存在的问题?
> ③ **更优解 / 隐藏假设** —— 有无被忽略的更优路径?有无未言明的危险假设?方向性遗漏?
> ④ **拆解质量** —— 任务切分有无遗漏、依赖顺序是否正确、每条验收标准能否证伪、有无子任务实际做不了。
>
> **spec 与 plan 同审**:二者一并喂给同一进程。**若 plan 尚未产出,则只审 spec,plan 成文后补审一次**——不得以"稍后一起审"为由跳过。
>
> **简报自包含**:Codex 无本会话记忆,须把 spec / plan **全文**连同任务背景塞进简报;只返回"致命 / 方向性问题清单(每条含理由 + 定位 + 所属维度)",无则只回"无致命项"。
>
> **以下四条是实测踩出来的,新形态照旧适用**:① **prompt 走 stdin**(不用 argv,避免长 spec 触发 `ARG_MAX`);② **独立空目录 `-C`**,输入文件放目录外;③ **`set -Eeuo pipefail` + 三闸校验**,文件缺失 / 为空 / 末行非哨兵 / 去哨兵后正文为空,一律 **fail closed** 阻断,绝不把空审当"无致命项"放行;④ **留痕落项目持久目录**(非 `/tmp`)。
>
> ⚠️ **subagent 形态的已知边界(继承自图化版待办①)**:承载节点是 Claude subagent,它需要 `Bash` 才能调 codex,故**外层节点本身未受"审查者只读"的工具层约束**;`-s read-only` 只约束内层 codex 进程。**缓解**:简报明令该节点"不做任何审查判断,只负责组装命令与如实回传",且不给它写目标文件的任务。
> ⚠️ **并 fix 图化版待办②的 fail-open**:**L0 不得只信 subagent 自报的结论**——必须**由 L0 亲自**确认 `out.txt` 真实存在、末行严格等于哨兵、去哨兵后正文非空。子代理自报 `integrityOk` 属零级证据(`[EVIDENCE-FIRST]`),顶不了这三闸。

```bash
#!/usr/bin/env bash
# 由 subagent 在其 Bash 里执行;L0 事后亲自校验 out.txt(见上方 fail-open 说明)
set -Eeuo pipefail
# ===== 前置:留痕目录落项目内(非 /tmp,可追溯);GATE 由 L0 显式指定,勿用时间戳自动生成 =====
# GATE='<项目>/.plangate/<run-id>'   # ⚠️ 显式传入,规避旧图化版的同秒目录竞争问题
mkdir -p "$GATE/in" "$GATE/gate"
# 把 spec 全文写入 $GATE/in/spec.txt;plan 全文写入 $GATE/in/plan.txt(无 plan 则本轮只审 spec)
SENTINEL='<<<PLANGATE_COMPLETE>>>'   # 完整性哨兵:防流式输出中途截断的"半截 out.txt"被非空校验放行
GUARD="你是对抗式审查者,有罪推定。逐个维度给结论,每条问题标注【致命/方向性】或【非致命建议】,并给出定位。
**必须输出四个固定标题,一个不能少**;某维无问题也要显式写“无致命项”,不接受笼统一句带过:
## 维度①需求误解     —— 以上面的【用户原始要求】为准,spec 有没有把 A 当成 B
## 维度②过度设计      —— 违 YAGNI?有更简解?在解决并不存在的问题?
## 维度③更优解/隐藏假设 —— 被忽略的更优路径?未言明的危险假设?
## 维度④拆解质量      —— 切分遗漏/依赖顺序/验收标准可证伪性/有无子任务做不了
全部结论输出完毕后,把 $SENTINEL 单独打印在最后一行。"
[[ -s "$GATE/in/request.txt" ]] || { echo "✗ request.txt 缺失/为空,阻断(没有用户原话就判不出需求误解)"; exit 1; }
[[ -s "$GATE/in/intent.txt" ]] || { echo "✗ intent.txt 缺失/为空,阻断(interview-me 后用户确认的意图/裁定是权威解释源,缺则会按初始原话误判需求)"; exit 1; }
[[ -s "$GATE/in/spec.txt" ]] || { echo "✗ spec.txt 缺失/为空,阻断"; exit 1; }
PLAN_TXT=""; [[ -s "$GATE/in/plan.txt" ]] && PLAN_TXT="$(cat "$GATE/in/plan.txt")"
printf '%s\n\n=== 用户初始原话(轨迹起点)===\n%s\n\n=== 用户确认的最终意图/裁定(权威解释源;interview-me 后固化)===\n%s\n\n=== spec ===\n%s\n\n=== plan ===\n%s\n\n注:两处冲突时以【用户确认的最终意图/裁定】为准;初始原话仅用于核查演变是否有依据。\n' \
  "$GUARD" "$(cat "$GATE/in/request.txt")" "$(cat "$GATE/in/intent.txt")" "$(cat "$GATE/in/spec.txt")" \
  "${PLAN_TXT:-(plan 尚未产出,本轮只审 spec;plan 成文后须补审)}" \
| codex exec --skip-git-repo-check -m gpt-5.6-sol -c model_reasoning_effort="ultra" -s read-only \
    -C "$GATE/gate" -o "$GATE/gate/out.txt" -
# 三闸(均为实测坐实的 fail-open,缺一不可):① 非空 ② 末行严格等于哨兵 ③ 去哨兵后正文仍非空
{ [[ -s "$GATE/gate/out.txt" ]] && [[ "$(tail -n1 "$GATE/gate/out.txt")" == "$SENTINEL" ]] \
  && [[ $(grep -vF "$SENTINEL" "$GATE/gate/out.txt" | grep -c '[^[:space:]]') -ge 1 ]]; } \
  || { echo "✗ 输出为空 / 末行非哨兵(疑截断)/ 去哨兵后正文为空,阻断"; exit 1; }
# 第四闸:四维标题必须齐全——防"一句笼统的无致命项"蒙混过关(单审无冗余,语义 fail-open 更危险)
for d in 维度① 维度② 维度③ 维度④; do
  grep -qF "$d" "$GATE/gate/out.txt" || { echo "✗ 输出缺 $d 的结论,判定不完整,阻断"; exit 1; }
done
echo "→ Plan-Gate 完成,L0 主循环逐条分诊"
# L0 把每条意见的 disposition(采纳/误报/已澄清)+ 理由追加写入 $GATE/disposition.md 留痕
```


### L3 · Codex 终检（只读，**落地后** —— 区别于上面审 spec/plan 的 Plan-Gate）

> ⚠️ 审查 prompt 里**必带**上方【环境与威胁模型】段——否则理论风险会被判成 P1/No-Go，淹没真问题。
> 案例:L3 曾把"字符串匹配可被有意规避"列为阻断项,
> 而该脚本的定位本就是"防手滑、不防有意规避"，已在文档写明——属威胁模型错配。
> ⚠️ L3/Plan-Gate **必须确认走 `gpt-5.6-sol`**——裸 `codex exec review` 依赖默认模型，有漂移风险；**一律用显式 `-m gpt-5.6-sol -c model_reasoning_effort=<档>` 形式，不接受"确认默认模型"这条放行路径**（默认会漂移，且无法锁推理档）。**推理档按时点分，不可混用：Plan-Gate（审 spec/plan，时点见上）用 `ultra`；L3（落地后终检）用 `xhigh`。** **且一律显式带 `-s read-only`**（`[GRANT-PERMISSIONS]` 的审查只读例外）。**L3 永不用 Claude**（那是 L2 的口子，frontier 终检雷打不动 Codex）。
```bash
# 代码审查（codex 内建审查流水线，须在 git 仓库内；模型与推理档已在命令中显式锁定）
# ⚠️ 必须显式 -s read-only：审查者不得改自己要审的东西（`[GRANT-PERMISSIONS]` 的只读例外）
codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only review --uncommitted    # 审未提交改动
codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only review --base main      # 对比基线分支
# 代码 / 内容通用对抗式终检（非 git 目录加 --skip-git-repo-check；落地后终检用 xhigh 省成本，ultra 只留 Plan-Gate）
codex exec --skip-git-repo-check -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only \
  "对抗式审查 <路径 / diff>：找正确性、安全、边界、遗漏问题，默认有罪推定" </dev/null
```
