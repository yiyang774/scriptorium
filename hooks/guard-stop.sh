#!/usr/bin/env bash
# Stop 证据闸（🟡 级）。规范见 ~/.claude/ops/enforcement.md
#
# 治什么：模型报出带【量词】的结论（"共 N 处""全部""没有任何"）却没跑过任何检索/计数命令
#         —— 那个数是【推断出来的】，不是【查出来的】。实测本会话犯过三次。
#
# 判定：本轮回复含量词断言 AND 本轮无证据命令 → exit 2 打回。
#
# 三层防误拦（任一生效即放行）：
#   1. stop_hook_active=true      —— 已经打回过一次，绝不二次拦（防死循环）
#   2. 回复含 [无需证据: 理由]     —— 显式逃生阀
#   3. GUARD_OFF=1 或 ~/.claude/.guard-off 存在 —— 全局急停
set -uo pipefail

. "$HOME/.claude/hooks/guard-lib.sh" 2>/dev/null || exit 0
guard_disabled && exit 0

IN=$(cat 2>/dev/null) || exit 0
[ -n "$IN" ] || exit 0

SID=$(guard_field "$IN" session_id)
GDIR=$(guard_dir "$SID")

# 防循环闸：官方语义 stop_hook_active 第二次为 true
# ⚠️ 必须在取到 GDIR 后再退，且退前清台账——否则 action/evidence 残留会串进下一轮
case "$IN" in *'"stop_hook_active":true'*|*'"stop_hook_active": true'*)
  guard_clear_evidence "$GDIR"; guard_clear_action "$GDIR"; exit 0;; esac
guard_gc

MSG=$(guard_field "$IN" last_assistant_message)
# 拿不到消息就放行——不猜
[ -n "$MSG" ] || { guard_clear_evidence "$GDIR"; guard_clear_action "$GDIR"; exit 0; }

# 逃生阀
case "$MSG" in *"[无需证据"*) guard_clear_evidence "$GDIR"; guard_clear_action "$GDIR"; exit 0;; esac

# 有证据 → 放行并清账，进入下一轮
# 剔除代码块与引用块（那里的数字往往是命令输出的复述，不是我的断言）
BODY=$(printf '%s' "$MSG" | awk '
  /^```/ { infence = !infence; next }
  infence { next }
  /^>/ { next }
  { print }
')

# ── 🟡 承诺闸：说了要做，然后就结束回合 ──────────────────────
# 判据与证据闸不同：证据闸问"有没有查"（检索类命令），承诺闸问"有没有做"（任何工具）。
# 实测来由：声明"这条豁免我会记进 journal 留痕"后直接收尾，留痕没做，靠下一轮自查才补上。
if ! guard_has_action "$GDIR"; then
  # ⚠️ 正则收窄经三次实测误拦修正（2026-08-05 Plan-Gate 提出并复现）：
  #   ① "我会建议保留现状"——"建议"里的"建"命中动词表 → 动词改用完整词并前置排除"建议"
  #   ② "我把修改写完了"——过去完成态 → 去掉"我把"；句尾带"了/过/完毕"一律不算承诺
  #   ③ "我来做个总结:…"——同回复内已履行 → 去掉"我来"，只收"我会/我将"这类明确未来时
  # 宁可漏拦不可误拦：本闸拦的是"结束回合"，误拦代价比证据闸更高。
  promise=$(printf '%s' "$BODY" \
    | grep -vE '(建议|了。|了$|过了|完毕|已经)' \
    | grep -oE '[^。；！\n]{0,30}(我(会|将)[^。；！\n]{0,24}(记录|记进|写进|写入|补上|补一份|补充|加进|改成|改到|做掉|跑一|提交|落地|留痕|更新|整理)|(稍后|接下来|随后|待会)[^。；！\n]{0,20}(我)?[^。；！\n]{0,10}(记录|记进|写进|补上|补一份|加进|改到|提交|更新))[^。；！\n]{0,20}' \
    | head -3)
  if [ -n "$promise" ]; then
    {
      echo "🟡 你说了『我会…』『稍后…』这类要做某事的话，但这一轮什么工具都没调用。"
      echo
      echo "   疑似空头承诺："
      printf '     · %s\n' "$promise"
      echo
      echo "   治的是"说了要做、然后结束回合"——实测踩过：声明"这条豁免我会记进"
      echo "   journal 留痕"后直接收尾，留痕没做，靠下一轮自查才补上。"
      echo
      echo "   请三选一后再结束本轮："
      echo "     A. 本轮就把它做掉（这是默认选项——能现在做就别写成承诺）"
      echo "     B. 改写成不含承诺的表述，如"待办：xxx，本轮未做""
      echo "     C. 确属下一轮才能做（依赖用户输入 / 外部结果）→ 写 [无需证据: 理由]"
    } >&2
    guard_log_trigger stop "承诺无动作" "$SID" "$(printf '%s' "$promise" | head -1)"
    guard_clear_action "$GDIR"
    exit 2
  fi
fi

# ── 🟡 证据闸：有证据就放行 ─────────────────────────────────
if guard_has_evidence "$GDIR"; then
  guard_clear_evidence "$GDIR"
  guard_clear_action "$GDIR"
  exit 0
fi

hit=""
# 计数型："共 21 处" "21 个文件" "3 条 must-fix"
printf '%s' "$BODY" | grep -qE '(共|计|总共|一共)[[:space:]]*[0-9]+[[:space:]]*[处个条项份行]' \
  && hit="报了具体数量"
[ -z "$hit" ] && printf '%s' "$BODY" | grep -qE '[0-9]+[[:space:]]*(处|个文件|条 must-fix|项全绿|项通过)' \
  && hit="报了具体数量"
# 全称型
[ -z "$hit" ] && printf '%s' "$BODY" | grep -qE '(全部|所有|一律|无一|均已|统统)[^。；\n]{0,12}(通过|正确|修复|完成|覆盖|一致|正常)' \
  && hit="说了『全部/所有』"
# 否定型（最危险：没查就说没有）
[ -z "$hit" ] && printf '%s' "$BODY" | grep -qE '(没有任何|均无|零残留|不存在任何|一处都没有|无残留|未发现任何)' \
  && hit="说了『没有/无』"
# 验收型
[ -z "$hit" ] && printf '%s' "$BODY" | grep -qE '[0-9]+/[0-9]+[[:space:]]*(通过|全绿|一致|过)' \
  && hit="报了 N/N 通过"

[ -n "$hit" ] || { guard_clear_evidence "$GDIR"; guard_clear_action "$GDIR"; exit 0; }

SAMPLE=$(printf '%s' "$BODY" \
  | grep -oE '[^。；\n]{0,40}((共|计)[[:space:]]*[0-9]+[[:space:]]*[处个条项份行]|全部[^。；\n]{0,12}(通过|正确|修复|完成)|没有任何[^。；\n]{0,12}|[0-9]+/[0-9]+[[:space:]]*(通过|全绿))[^。；\n]{0,20}' \
  | head -3)

{
  echo "🟡 [EVIDENCE-FIRST] 你${hit}，但这一轮没跑过任何检索或计数命令。"
  echo
  [ -n "$SAMPLE" ] && { echo "   没有证据支撑的说法："; printf '     · %s\n' "$SAMPLE"; echo; }
  echo "   这类数字若来自"看了几处推出规律"，而非机器计数，通常是错的。"
  echo "   本规则的来由是实测：同一会话里连续三次——口头报"5 处"实为 21 处；"
  echo "   "21+2=23" 实为 21；子代理报"grep 无输出"实为 grep 被 shell 挡下根本没跑。"
  echo
  echo "   请三选一后再结束本轮："
  echo "     A. 跑一条命令核实（grep -c / wc -l / diff --numstat / 测试命令），把输出贴出来"
  echo "     B. 把结论改成不带量词的表述（如"存在若干处，未逐一核实"）"
  echo "     C. 确属无需核实（纯对话、引用他人结论等），回复里写 [无需证据: 理由]"
} >&2
guard_log_trigger stop "$hit" "$SID" "$(printf '%s' "$SAMPLE" | head -1)"
exit 2
