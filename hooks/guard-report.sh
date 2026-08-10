#!/usr/bin/env bash
# guard 观察期报告。用法: ~/.claude/hooks/guard-report.sh [天数，默认 7]
#
# 观察期要回答的问题（用数据，不靠印象）：
#   1. 拦了几次？各类型分别几次？
#   2. 拦截频率是否高到烦人？
#   3. 哪些是误拦？—— 这条机器判不了，需人工标注（见下）
#
# 误拦标注：在 ~/.claude/.guard/false-positives.txt 里每行写一个时间戳前缀，
# 例如 "2026-08-05 09:1"，本报告会统计匹配到的条数作为误拦数。
set -uo pipefail
G="$HOME/.claude/.guard"
LOG="$G/triggers.tsv"
DAYS="${1:-7}"

[ -f "$LOG" ] || { echo "尚无触发记录（$LOG 不存在）——guard 装上后还没拦过任何东西。"; exit 0; }

TOTAL=$(grep -c '' "$LOG" 2>/dev/null || echo 0)
echo "═══ guard 触发报告（全部 $TOTAL 条）═══"
echo

echo "── 按类型 ──"
awk -F'\t' '{c[$2"/"$3]++} END {for (k in c) printf "  %-22s %d\n", k, c[k]}' "$LOG" | sort -k2 -rn

echo
echo "── 按日 ──"
awk -F'\t' '{split($1,d," "); c[d[1]]++} END {for (k in c) printf "  %s  %d\n", k, c[k]}' "$LOG" | sort | tail -"$DAYS"

echo
echo "── 最近 10 条 ──"
tail -10 "$LOG" | awk -F'\t' '{printf "  %s  [%s/%s]  %s\n", $1, $2, $3, substr($5,1,70)}'

FP="$G/false-positives.txt"
echo
if [ -s "$FP" ]; then
  n=0
  while IFS= read -r pat; do
    [ -n "$pat" ] || continue
    m=$(grep -c "^$pat" "$LOG" 2>/dev/null || echo 0)
    n=$((n + m))
  done < "$FP"
  echo "── 误拦（人工标注 $(grep -c '' "$FP") 条模式，匹配 $n 次）──"
  if [ "$TOTAL" -gt 0 ]; then
    echo "  误拦率: $n / $TOTAL"
  fi
else
  echo "── 误拦 ──"
  echo "  未标注。若遇误拦，把该次的时间戳前缀写进 $FP"
  echo "  例: echo '2026-08-05 09:1' >> $FP"
fi

echo
echo "── 判读参考 ──"
echo "  · 日均 >5 次 → 可能过于骚扰，考虑收窄正则"
echo "  · 误拦率 >20% → 判定逻辑需要修，别硬扛"
echo "  · 全程 0 次 → 要么规则没被触发（好），要么钩子没生效（查 settings.json）"
