#!/usr/bin/env bash
# guard 系列公共库。被 guard-pretool.sh / guard-stop.sh source。
# 规范见 ~/.claude/ops/enforcement.md
#
# 设计原则：
# - 本库任何函数都不得自己 exit（除非显式命名为 *_or_die），由调用方决定放行/阻断
# - 解析失败一律【放行】——guard 是护栏不是安检门，宁可漏拦不可卡死正常工作
# - 只用 bash 3.2 + 系统自带工具（本机 bash 3.2，无关联数组，见 ops/preflight.md B1）

GUARD_ROOT="${HOME}/.claude/.guard"

# 全局急停：任一为真即整套 guard 失效
guard_disabled() {
  [ "${GUARD_OFF:-}" = "1" ] && return 0
  [ -f "$HOME/.claude/.guard-off" ] && return 0
  return 1
}

# 从 stdin JSON 取顶层字符串字段。无 jq 时退化为 grep（够用：这些字段都是简单标量）
guard_field() {
  local json="$1" key="$2"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg k "$key" '.[$k] // empty' 2>/dev/null
  else
    printf '%s' "$json" \
      | grep -oE "\"$key\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 | sed -E 's/.*:[[:space:]]*"(.*)"/\1/'
  fi
}

# 取嵌套字段，如 tool_input.command
guard_field2() {
  local json="$1" a="$2" b="$3"
  if command -v jq >/dev/null 2>&1; then
    printf '%s' "$json" | jq -r --arg a "$a" --arg b "$b" '.[$a][$b] // empty' 2>/dev/null
  else
    printf '%s' "$json" | tr ',' '\n' \
      | grep -oE "\"$b\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 | sed -E 's/.*:[[:space:]]*"(.*)"/\1/'
  fi
}

# 本会话的证据台账目录
guard_dir() {
  local sid="${1:-nosession}"
  # session_id 可能含斜杠以外的怪字符，做一次白名单过滤
  sid=$(printf '%s' "$sid" | tr -cd 'A-Za-z0-9._-')
  [ -n "$sid" ] || sid=nosession
  printf '%s/%s' "$GUARD_ROOT" "$sid"
}

# 记一条证据（本轮跑过的检索/计数类命令）
guard_note_evidence() {
  local dir="$1" what="$2"
  mkdir -p "$dir" 2>/dev/null || return 0
  printf '%s\n' "$what" >> "$dir/evidence.log" 2>/dev/null || true
}

# 本轮是否有过证据。turn 边界：Stop 钩子触发后清空
guard_has_evidence() {
  local dir="$1"
  [ -s "$dir/evidence.log" ]
}

guard_clear_evidence() {
  local dir="$1"
  rm -f "$dir/evidence.log" 2>/dev/null || true
}

# ── 动作台账（承诺闸用）：记本轮调过的【任何】工具，不限检索类 ──
# 与 evidence.log 分开：证据闸问"有没有查"，承诺闸问"有没有做"。
guard_note_action() {
  local dir="$1" what="$2"
  mkdir -p "$dir" 2>/dev/null || return 0
  printf '%s\n' "$what" >> "$dir/action.log" 2>/dev/null || true
}

guard_has_action() {
  local dir="$1"
  [ -s "$dir/action.log" ]
}

guard_clear_action() {
  local dir="$1"
  rm -f "$dir/action.log" 2>/dev/null || true
}

# 清理 7 天前的会话台账，避免无限堆积
guard_gc() {
  [ -d "$GUARD_ROOT" ] || return 0
  # ⚠️ -mindepth 1 不可省：不加时 find 会把 $GUARD_ROOT 自己也列进来（深度 0），
  # 根目录满 7 天即被整棵 rm -rf，连"只追加"的 triggers.tsv 一起没。
  # 2026-08-05 Plan-Gate 提出、实测复现（find 确实列出根目录本身）后修复。
  find "$GUARD_ROOT" -mindepth 1 -maxdepth 1 -type d -mtime +7 -exec rm -rf {} + 2>/dev/null || true
}

# ── 触发记账（观察期用）─────────────────────────────────────
# 每次拦截追加一行 TSV 到 ~/.claude/.guard/triggers.tsv：
#   时间  钩子  类型  会话  摘要
# 目的：观察期结束时能用数据回答"拦了几次、哪类最多、误拦几次"，
# 而不是凭印象。摘要截断到 120 字符，不留敏感全文。
# 【只追加、绝不改写】——与任务日志同源的原则。
guard_log_trigger() {
  local hook="$1" kind="$2" sid="$3" note="$4"
  mkdir -p "$GUARD_ROOT" 2>/dev/null || return 0
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$(date '+%Y-%m-%d %H:%M:%S')" "$hook" "$kind" "${sid:-?}" \
    "$(printf '%s' "$note" | tr '\t\n' '  ' | head -c 120)" \
    >> "$GUARD_ROOT/triggers.tsv" 2>/dev/null || true
}
