#!/usr/bin/env bash
# 注入本项目"进行中"任务日志清单。只输出文件名+日期，不注入正文。
# 实测依据：SessionStart 的 stdout 会进入模型上下文；$CLAUDE_PROJECT_DIR 即项目根。
set -u
J="${CLAUDE_PROJECT_DIR:-$PWD}/docs/superpowers/journal"
[ -d "$J" ] || exit 0                      # 未启用日志的项目：静默跳过

n=0; out=""
for f in "$J"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md; do
  [ -f "$f" ] || continue                  # 无匹配时 glob 原样返回
  [ -L "$f" ] && continue                  # 跳过 symlink
  b=$(basename "$f")
  case "$b" in *.md) ;; *) continue;; esac
  # 只取头部 30 行里 状态：进行中
  head -30 "$f" | grep -q '^状态：进行中' || continue
  d=$(head -30 "$f" | grep -m1 '^最后更新：' | sed 's/^最后更新：[[:space:]]*//')
  case "$d" in [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;; *) d="日期未知";; esac
  n=$((n+1))
  [ $n -le 10 ] && out="${out}  - ${b%.md}（最后更新 ${d}）
"
done

[ $n -eq 0 ] && exit 0                     # 无进行中任务：不出声
printf '[任务日志] 本项目进行中的任务：\n%s' "$out"
[ $n -gt 10 ] && printf '  （另有 %d 个较早任务未列出）\n' $((n-10))
printf '需要时读取 docs/superpowers/journal/<文件名>.md（本清单只列文件名，不含内容）\n'
exit 0
