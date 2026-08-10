#!/usr/bin/env bash
# guard 系列自测。改 guard-*.sh 后必须跑；加新拦截规则时必须补用例。
# 用法: ~/.claude/hooks/guard-selftest.sh   （退出码 0=全过，1=有失败）
set -uo pipefail
H="$HOME/.claude/hooks"
PASS=0; FAIL=0
SID="selftest-$$"
GD="$HOME/.claude/.guard/$SID"

ck() { # $1=用例名 $2=实际rc $3=期望rc
  if [ "$2" = "$3" ]; then printf '  ✅ %s\n' "$1"; PASS=$((PASS+1))
  else printf '  ❌ %s  期望rc=%s 实际rc=%s\n' "$1" "$3" "$2"; FAIL=$((FAIL+1)); fi
}
pre() { printf '{"tool_name":"Bash","session_id":"%s","tool_input":{"command":%s}}' "$SID" "$1" \
        | "$H/guard-pretool.sh" >/dev/null 2>&1; echo $?; }
stop() { printf '{"session_id":"%s","stop_hook_active":%s,"last_assistant_message":%s}' "$SID" "${2:-false}" "$1" \
        | "$H/guard-stop.sh" >/dev/null 2>&1; echo $?; }
reset() { rm -rf "$GD"; }

echo "═══ 语法 ═══"
for f in guard-lib.sh guard-pretool.sh guard-stop.sh guard-selftest.sh; do
  bash -n "$H/$f" 2>/dev/null && { printf '  ✅ %s\n' "$f"; PASS=$((PASS+1)); } \
    || { printf '  ❌ %s 语法错\n' "$f"; FAIL=$((FAIL+1)); }
done

echo "═══ 🔴 PreToolUse：应拦 ═══"
reset; ck "gh pr merge"            "$(pre '"gh pr merge 12 --squash"')" 2
reset; ck "git push origin main"   "$(pre '"git push origin main"')" 2
reset; ck "git push HEAD:master"   "$(pre '"git push origin HEAD:master"')" 2
reset; ck "review 缺 read-only"    "$(pre '"codex exec -m gpt-5.6-sol review --base main"')" 2
reset; ck "对抗式审 缺 read-only"  "$(pre '"codex exec -m gpt-5.6-sol 对抗式审查这个 diff"')" 2

echo "═══ 🔴 PreToolUse：应放行（防误拦）═══"
reset; ck "gh pr create"           "$(pre '"gh pr create --title x --body y"')" 0
reset; ck "gh pr view"             "$(pre '"gh pr view 12 --json headRefOid"')" 0
reset; ck "push 普通分支"          "$(pre '"git push origin feature-x"')" 0
reset; ck "review 带 read-only"    "$(pre '"codex exec -m gpt-5.6-sol -s read-only review --base main"')" 0
reset; ck "codex 非审查用途"       "$(pre '"codex exec -m gpt-5.6-luna -s workspace-write 写个函数"')" 0
reset; ck "普通 grep"              "$(pre '"grep -rn foo src/"')" 0
reset; ck "git commit"             "$(pre '"git commit -m fix"')" 0
# ↓ 回归：2026-08-05 实测误拦——命令里【包含】被测字符串，但并非真要执行该动作
reset; ck "回归·echo 含 pr merge"  "$(pre '"echo \"测试 gh pr merge 拦截\" > t.txt"')" 0
reset; ck "回归·printf 含 pr merge" "$(pre '"printf \"gh pr merge 9\" | ./guard-pretool.sh"')" 0
reset; ck "回归·注释含 push main"  "$(pre '"grep -n \"git push origin main\" hooks/guard-pretool.sh"')" 0
reset; ck "回归·测试含 review"     "$(pre '"echo \"codex exec -m x review\" | ./t.sh"')" 0
# ↓ 但真在复合命令里执行仍须拦
reset; ck "复合命令中真的 merge"   "$(pre '"cd /tmp && gh pr merge 9 --squash"')" 2
reset; ck "分号后真的 push main"   "$(pre '"git add -A; git push origin main"')" 2

echo "═══ 🟡 Stop：应拦（无证据的量词断言）═══"
reset; ck "计数-共N处"    "$(stop '"核对完毕，共 21 处编号漂移。"')" 2
reset; ck "计数-N条"      "$(stop '"逮出 3 条 must-fix。"')" 2
reset; ck "全称"          "$(stop '"所有引用均已修复完成。"')" 2
reset; ck "否定"          "$(stop '"没有任何残留。"')" 2
reset; ck "验收比"        "$(stop '"11/11 通过。"')" 2

echo "═══ 🟡 Stop：应放行（防误拦）═══"
reset; ck "纯对话"        "$(stop '"这个方向我同意，先聊清需求。"')" 0
reset; ck "无量词"        "$(stop '"我改了几个文件，见上面的 diff。"')" 0
reset; ck "逃生阀"        "$(stop '"共 5 处。[无需证据: 引用用户上文数字]"')" 0
reset; ck "防循环"        "$(stop '"共 21 处全部通过"' true)" 0
reset; ck "空消息"        "$(stop '""')" 0
reset; ck "代码块内数字"  "$(stop '"结果如下：\n```\n共 21 处\n```\n请查看。"')" 0

echo "═══ 🟡 Stop 承诺闸：应拦（承诺 + 本轮无任何工具调用）═══"
reset; ck "我会…记"        "$(stop '"这条豁免我会记进 journal 留痕。"')" 2
reset; ck "我将…改"        "$(stop '"我将把这个改到 spec 里。"')" 2
reset; ck "稍后补"         "$(stop '"好的，稍后补一份终检报告。"')" 2

echo "═══ 🟡 Stop 承诺闸：应放行（防误拦）═══"
# 有动作即放行——含非 Bash 工具（Edit/Write），故记账点必须在 pretool 的 Bash 早退之前
reset; mkdir -p "$GD"; echo Edit > "$GD/action.log"
ck "承诺但已动手"          "$(stop '"这条豁免我会记进 journal 留痕。"')" 0
reset; ck "改写成待办"     "$(stop '"待办：journal 留痕，本轮未做。"')" 0
reset; ck "承诺+逃生阀"    "$(stop '"我会等你确认再动手。[无需证据: 需用户裁定]"')" 0
reset; ck "承诺闸不误伤纯对话" "$(stop '"分析完毕，你觉得呢？"')" 0
# 记账点回归：Edit 这类非 Bash 工具必须被 pretool 记进 action.log
reset; printf '{"tool_name":"Edit","session_id":"%s","tool_input":{"file_path":"/tmp/x"}}' "$SID" \
  | "$H/guard-pretool.sh" >/dev/null 2>&1
ck "Edit 也记账→放行"      "$(stop '"我会把它写进 spec。"')" 0

echo "═══ 回归：2026-08-05 Plan-Gate 逮出的四个真 bug ═══"
# ① guard_gc 曾把 GUARD_ROOT 自己列进删除名单（-maxdepth 1 含深度 0）
rm -rf /tmp/.gcselftest; mkdir -p /tmp/.gcselftest/sess1; touch /tmp/.gcselftest/triggers.tsv
touch -t 202001010000 /tmp/.gcselftest /tmp/.gcselftest/sess1 /tmp/.gcselftest/triggers.tsv
( GUARD_ROOT=/tmp/.gcselftest; . "$H/guard-lib.sh"; GUARD_ROOT=/tmp/.gcselftest guard_gc ) 2>/dev/null
[ -f /tmp/.gcselftest/triggers.tsv ] && { printf '  ✅ gc 不删根目录\n'; PASS=$((PASS+1)); } \
  || { printf '  ❌ gc 把 triggers.tsv 删了\n'; FAIL=$((FAIL+1)); }
rm -rf /tmp/.gcselftest
# ② 只读判定曾在整串 $CMD 里找 -s read-only，别处出现即可骗过
reset; ck "只读伪装绕过应拦"  "$(pre '"echo \"-s read-only\" ; codex exec -m gpt-5.6-sol review --base main"')" 2
reset; ck "逐段合规应放行"    "$(pre '"codex exec -m gpt-5.6-sol -s read-only review --base main"')" 0
# ③ 承诺闸正则误拦三例
reset; ck "「我会建议」不误拦" "$(stop '"我会建议保留现状。"')" 0
reset; ck "过去完成不误拦"     "$(stop '"我把修改写完了。"')" 0
reset; ck "「我来做个总结」不误拦" "$(stop '"我来做个总结：改动如上。"')" 0
# ④ 只读工具不算"动手"——查了一圈就承诺，仍该拦
reset; printf '{"tool_name":"Read","session_id":"%s","tool_input":{"file_path":"/tmp/x"}}' "$SID" \
  | "$H/guard-pretool.sh" >/dev/null 2>&1
ck "只读工具不算动手→仍拦"    "$(stop '"我会把它写进 spec。"')" 2

echo "═══ 文档写法：反例命令的误拦边界（2026-08-05 裁定 B：不削弱护栏）═══"
# 不在段首的 codex exec 字面量 → 不该触发（CLAUDE.md / hook 注释的常见写法）
reset; ck "行内引用不触发"  "$(pre '"cat > /tmp/f.md <<EOF\n派法 codex exec ... -o path 只提取原文\nEOF"')" 0
reset; ck "注释里的字面量"  "$(pre '"cat > /tmp/f.sh <<EOF\n# 避免嵌了 codex exec ... review 字面量被误拦\nEOF"')" 0
# 段首的仍必须拦——B 方案的前提是护栏一点不松
reset; ck "切到段首仍拦"    "$(pre '"echo x ; codex exec -m gpt-5.6-sol review --base main"')" 2

echo "═══ 闭环：跑过命令后应放行 ═══"
reset
pre '"grep -rc foo ops/"' >/dev/null
ck "有证据→放行"          "$(stop '"核对完毕，共 21 处。"')" 0
ck "台账已清空→再拦"      "$(stop '"又是共 8 处。"')" 2

echo "═══ 急停开关 ═══"
reset
rc=$(GUARD_OFF=1 bash -c "printf '{\"session_id\":\"$SID\",\"stop_hook_active\":false,\"last_assistant_message\":\"共 99 处全部通过\"}' | '$H/guard-stop.sh' >/dev/null 2>&1; echo \$?")
ck "GUARD_OFF=1"          "$rc" 0
touch "$HOME/.claude/.guard-off"
ck ".guard-off 文件"      "$(stop '"共 99 处。"')" 0
rm -f "$HOME/.claude/.guard-off"

reset
echo
echo "════ PASS=$PASS  FAIL=$FAIL ════"
[ "$FAIL" -eq 0 ]
