#!/usr/bin/env bash
# 会话结束前，若本项目有唯一进行中日志且今日未催过，用 exit 2 + stderr 要求模型更新日志。
# 注：不判断"本次会话是否有实质动作"——那是语义判断，机器做不到（同 A 包否决方案 C 的理由）。
#     实测模型在无实质进展时会如实记录"本次无代码改动"，不会虚构交付；频率由第 4 道闸兜住。
# 实测依据：Stop hook 的 exit 2 + stderr 会让模型续跑并执行指示；exit 0 则完全无效。
#           stop_hook_active 第二次为 true，用作防循环闸。
set -u
IN=$(cat)

# 防循环：已续跑过一次就放行（实测 stop_hook_active: false → true）
case "$IN" in *'"stop_hook_active":true'*) exit 0;; esac

J="${CLAUDE_PROJECT_DIR:-$PWD}/docs/superpowers/journal"

# 先从 transcript 机械抽取本次会话事实，补进 facts 草稿（纯脚本、不调模型、~0.1s）
# 2026-08-07 加：原本 facts 只有 PostToolUse 采到的硬事实（commit/行数/codex 调用），
# 缺"用户裁定了什么"——那是最该记又最容易凭记忆记错的。scribe-extract 从 transcript
# 直接抽 AskUserQuestion 的问答对，机械可靠。
TP=$(printf '%s' "$IN" | python3 -c "import json,sys; print(json.load(sys.stdin).get('transcript_path') or '')" 2>/dev/null)
if [ -n "$TP" ] && [ -f "$TP" ] && [ -d "$J" ]; then
  python3 "$HOME/.claude/hooks/scribe-extract.py" "$TP" --journal "$J" >/dev/null 2>&1 || true
fi

[ -d "$J" ] || exit 0

# 找唯一的进行中日志；0 个或多个都不催（多个时无法判定该写哪份）
cur=""; n=0
for f in "$J"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md; do
  [ -f "$f" ] || continue; [ -L "$f" ] && continue
  head -30 "$f" | grep -q '^状态：进行中' || continue
  n=$((n+1)); cur="$f"
done
[ "$n" = 1 ] || exit 0

today=$(date +%Y-%m-%d)

# 闸门1：日志今日已更新过 → 不催
head -30 "$cur" | grep -q "^最后更新：$today" && exit 0

# 闸门2：本项目今天已经催过一次 → 不催（无论上次催完有没有真去改）
#   戳按【项目+日志文件】记，故多项目各自独立、换日自动失效
# HOME 未设置时不能崩（set -u 会直接退出，破坏 fail-safe）——L2 must-fix
stampdir="${HOME:-${TMPDIR:-/tmp}}/.claude/hooks/.stop-stamps"
mkdir -p "$stampdir" 2>/dev/null || exit 0
# shasum 未必存在，给 sha1sum / cksum 兜底，避免 key 退化为空 —— L2 nit
key=$(printf '%s' "$cur" | { shasum 2>/dev/null || sha1sum 2>/dev/null || cksum; } | tr -d ' -' | cut -c1-16)
[ -n "$key" ] || exit 0
stamp="$stampdir/$key"
[ "$(cat "$stamp" 2>/dev/null)" = "$today" ] && exit 0
printf '%s' "$today" > "$stamp" 2>/dev/null || true

# 顺手清理 7 天前的旧戳，避免无限堆积
find "$stampdir" -type f -mtime +7 -delete 2>/dev/null || true

rel="docs/superpowers/journal/$(basename "$cur")"
facts="$J/.facts-$today.md"
{
printf '[任务日志] %s 今日尚未更新。请在结束前完成两件事（若本次会话确无实质进展，可只更新"最后更新"日期）：\n' "$rel"
printf '  1. 覆写头部快照：进行到 / 下一步 / 未决问题 / 关键路径文件 / 已定裁决，并把「最后更新」改为 %s\n' "$today"
printf '  2. 在事件流【末尾追加】本次会话的必记事件（用户裁定 / Plan-Gate 收口 / 派活 / 交付结果 / L2·L3 审查 / 阻塞 / 交付合并），带证据指针\n'
printf '绝不改写既有事件行——只追加。\n'
if [ -s "$facts" ]; then
  printf '\n以下是本日 hook 自动采集的【硬事实】，供你提炼——挑值得记的写进事件流并补上语义\n'
  printf '（谁裁定了什么、审查意见如何处置、为何这么做）；不值得记的直接忽略，不要照抄：\n'
  head -60 "$facts"
  printf '（草稿位置 %s，写完可删）\n' ".facts-$today.md"
fi
} >&2
exit 2
