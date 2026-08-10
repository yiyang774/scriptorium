#!/bin/bash
# PreToolUse 提醒：跑东西前提示 preflight；派完写代码的活提示 L2。
#
# 设计取舍（实测依据）：
#   - 只提醒、不阻断。2026-07-28 实测：PreToolUse 的字符串匹配有 5 种绕过写法，
#     挡不住有意规避；而 preflight/L2 低执行率的根因是【忘了】不是【故意绕】。
#   - 每种提醒每会话只发一次，避免噪音把有用信息淹掉。
set -uo pipefail

# 会话内去重：用会话目录（跨调用稳定），退化时用当日
SID="${CLAUDE_SESSION_ID:-$(date +%Y%m%d)}"
STATE="${TMPDIR:-/tmp}/.claude-reminder-${SID}"
input=$(cat)
cmd=$(printf '%s' "$input" | python3 -c '
import sys, json
try:
    d = json.load(sys.stdin)
    ti = d.get("tool_input", {}) or {}
    print(ti.get("command", "") or ti.get("prompt", "")[:400])
except Exception:
    pass
' 2>/dev/null) || exit 0

fired() { [ -f "$STATE.$1" ]; }
mark()  { : > "$STATE.$1"; }

# ① 要真跑东西 → preflight
case "$cmd" in
  *pytest*|*"python -m"*|*"python3 "*.py*|*ssh\ *|*nvidia-smi*|*huggingface*|*"torch."*)
    fired preflight || {
      mark preflight
      echo "▶ preflight：本次要真跑东西。先 Read ~/.claude/ops/preflight.md，按需查（只查用得上的组）。" >&2
      echo "  实测靶区：74 条历史错误里 16 条是「跑挂了才发现」——/tmp 填满、BLAS 超订、漏设 flag 致 OOM、GPU 无 EGL。" >&2
    }
    ;;
esac

# ② 刚派完写代码的活 → L2
case "$cmd" in
  *"codex exec"*workspace-write*|*"-s workspace-write"*)
    fired l2 || {
      mark l2
      echo "▶ L2：这次委派会产出代码。落地后别手拼审查命令——跑 ~/.claude/bin/l2 --author codex（本次作者是 Codex）。" >&2
      echo "  它自动选跨家族档、拼好 -o 留痕（那是「有效发起」的证据要件），手工 8 步压到 2 步。" >&2
    }
    ;;
esac

exit 0
