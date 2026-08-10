#!/usr/bin/env bash
# PreToolUse 硬拦（🔴 级）。规范见 ~/.claude/ops/enforcement.md
#
# 只拦【真正不可逆 / 违反只读硬约束】的两类，其余一律放行：
#   1. gh pr merge / push 到默认分支      —— 违反 [PR-GATE]，且不可逆
#   2. codex 审查调用缺 -s read-only      —— 违反 [GRANT-PERMISSIONS] 的审查只读例外
#
# 设计纪律：
# - 宁可漏拦不可误拦。任何解析不确定 → 放行。
# - 拦截时用 exit 2（官方语义：PreToolUse 下 exit 2 = 阻止工具调用），stderr 给出可操作的替代方案。
# - 本脚本【不】声称能防有意规避（字符串匹配总有绕法）；它防的是"顺手就做了"。
set -uo pipefail

. "$HOME/.claude/hooks/guard-lib.sh" 2>/dev/null || exit 0
guard_disabled && exit 0

IN=$(cat 2>/dev/null) || exit 0
[ -n "$IN" ] || exit 0

TOOL=$(guard_field "$IN" tool_name)

SID=$(guard_field "$IN" session_id)
GDIR=$(guard_dir "$SID")

# ── 全量动作记账（供 🟡 承诺闸判定）────────────────────────────
# 必须在下面的 Bash 提前退出【之前】记：承诺闸问的是"本轮有没有真动手"，
# Edit / Write / Task 等非 Bash 工具同样算动手，漏记会把"改完文件才作的承诺"误拦。
# ⚠️ 但【只读工具不算动手】：Read/Grep/Glob 查了一圈然后说"我会改" —— 那正是本闸要拦的。
# 记在 PreToolUse 而非 PostToolUse 是有意的取舍：宁可把"试了但失败"算作已动手（漏拦），
# 也不让承诺闸因工具失败而误拦（本闸拦的是结束回合，误拦代价高于漏拦）。
case "$TOOL" in
  Read|Grep|Glob|WebFetch|WebSearch|TodoWrite|NotebookRead) : ;;
  *) guard_note_action "$GDIR" "$TOOL" ;;
esac

[ "$TOOL" = "Bash" ] || exit 0

CMD=$(guard_field2 "$IN" tool_input command)
[ -n "$CMD" ] || exit 0

# 记录检索/计数类命令作为"证据"，供 guard-stop.sh 判定
case "$CMD" in
  *grep*|*rg\ *|*wc\ -l*|*"wc -l"*|*find\ *|*ls\ *|*diff*|*numstat*|*shasum*|*sha256*|\
  *pytest*|*"npm test"*|*jq\ *|*awk*|*python3\ -c*|*node\ --check*|*bash\ -n*|*cat\ *|*sed\ -n*)
    guard_note_evidence "$GDIR" "$(printf '%s' "$CMD" | head -c 200)"
    ;;
esac

# ── 拦截 1：PR 直接合并 / 推默认分支 ──────────────────────────
# 注意：只拦 merge 与 push 到 main/master，不拦 pr create / pr view / 普通分支 push
#
# ⚠️ 必须按【命令段】判定，不能用整串子串匹配（2026-08-05 实测误拦自己）：
#    测试脚本里出现 "gh pr merge" 这个【字符串】时被误拦——它是被测数据不是被执行的命令。
#    故先按 shell 分隔符（; && || | 换行）切段，再要求该段【去掉前导空白后以该动作开头】。
#    残余风险：`eval`、变量拼接、heredoc 内的命令仍绕得过——本层不防有意规避（见 ops/enforcement.md §3）。
blocked_merge=0
_scan_segments() {
  # 引号感知分段，见 guard-split.py（独立成文件：内联 python 需三层引号嵌套，实测写坏过）
  printf '%s' "$1" | python3 "$HOME/.claude/hooks/guard-split.py" 2>/dev/null
}
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  case "$seg" in
    "gh pr merge"*) blocked_merge=1; break ;;
    "git push"*)
      case "$seg" in
        *" main"*|*" master"*|*":main"*|*":master"*) blocked_merge=1; break ;;
      esac
      ;;
  esac
done <<EOF
$(_scan_segments "$CMD")
EOF
if [ "$blocked_merge" = "1" ]; then
  {
    echo "🔴 [PR-GATE] 拦截：GitHub 改动一律只开 PR、绝不直接合并 / 推默认分支。"
    echo "   命令：$(printf '%s' "$CMD" | head -c 160)"
    echo
    echo "   正确路径："
    echo "     1) gh pr create ...                     # 只开 PR"
    echo "     2) Read ~/.claude/ops/pr-merge.md       # 三闸：head/base OID 绑定 + 工作区纯净"
    echo "     3) 派 codex gpt-5.6-sol xhigh -s read-only 对抗式审该 PR 的 head SHA"
    echo "     4) 逐条分诊、留痕，异议澄清或修掉后，由用户拍板是否合并"
    echo
    echo "   确需合并请【用户本人】执行，或先 export GUARD_OFF=1 并说明理由。"
  } >&2
  guard_log_trigger pretool PR-GATE "$SID" "$CMD"
  exit 2
fi

# ── 拦截 2：审查调用缺 -s read-only ───────────────────────────
# 仅当命令确实是"审查"用途（含 review 子命令，或 prompt 里出现审查关键词）才检查
# 同拦截 1：按命令段判定，避免测试脚本里嵌了 "codex exec ... review" 字面量被误拦
# ⚠️ 只读判定必须【逐段独立验证】：旧版在 segment 里判 is_review、却回到整串 $CMD 找
# -s read-only，于是 `echo "-s read-only" ; codex exec ... review` 能骗过闸门（fail-OPEN）。
# 2026-08-05 Plan-Gate 提出、实测复现（该命令旧版返回 0）后修复。
is_review=0 bad_seg=""
while IFS= read -r seg; do
  [ -n "$seg" ] || continue
  case "$seg" in
    "codex exec"*)
      case "$seg" in
        *" review"*|*对抗式审*|*"对抗式终检"*|*"Plan-Gate"*|*快审*)
          is_review=1
          # 只读标志必须出现在【这一段】里，别处出现不算
          case "$seg" in
            *"-s read-only"*|*"--sandbox read-only"*) : ;;
            *) bad_seg="$seg"; break ;;
          esac
          ;;
      esac
      ;;
  esac
done <<EOF
$(_scan_segments "$CMD")
EOF
if [ "$is_review" = "1" ]; then
  case "$bad_seg" in
    "") : ;;
    *)
      {
        echo "🔴 [GRANT-PERMISSIONS] 拦截：审查关卡必须显式带 -s read-only。"
        echo "   命令：$(printf '%s' "$CMD" | head -c 160)"
        echo
        echo "   理由：审查者动手改自己要审的东西即失去审查意义。"
        echo "   裸 review 不写沙箱档位则无法判定是否满足只读硬约束，视为【无效发起】。"
        echo "   修法：在 review 子命令【之前】加 -s read-only（参数顺序是实测定下的）。"
      } >&2
      guard_log_trigger pretool READONLY "$SID" "$CMD"
      exit 2
      ;;
  esac
fi

exit 0
