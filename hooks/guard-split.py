#!/usr/bin/env python3
"""把一条 shell 命令切成"实际会被执行的命令段"，每段一行输出到 stdout。

只在【引号外】的 ; | & 换行 处切分——引号内的分隔符属于数据，不是控制符。

由 guard-pretool.sh 调用。独立成文件而非内联，是因为内联 python 需要三层引号嵌套
（bash 单引号 → python 单引号 → 匹配用的引号字面量），2026-08-05 实测写坏过一次。

两次真实误拦促成本模块：
  ① 整串子串匹配        → 测试脚本里出现 "gh pr merge" 字面量即被误拦
  ② sed 分段（无引号语义）→ P='{"cmd":"cd /tmp && gh pr merge 9"}' 里的 && 被切开，
                            后半段恰以该动作开头 → 仍误拦

残余风险（本层不声称能防）：eval、变量拼接、heredoc 内的命令、base64 解码后执行。
guard 防的是"顺手就做了"，不是有意规避——见 ops/enforcement.md §三。
"""
import sys

SEPARATORS = ";\n|&"
QUOTES = "'\""


def split_segments(cmd):
    segs, cur = [], []
    quote = None
    escaped = False
    for ch in cmd:
        if escaped:
            cur.append(ch)
            escaped = False
            continue
        # 单引号内反斜杠不转义（POSIX 语义）
        if ch == "\\" and quote != "'":
            escaped = True
            cur.append(ch)
            continue
        if quote:
            cur.append(ch)
            if ch == quote:
                quote = None
            continue
        if ch in QUOTES:
            quote = ch
            cur.append(ch)
            continue
        if ch in SEPARATORS:
            segs.append("".join(cur))
            cur = []
            continue
        cur.append(ch)
    segs.append("".join(cur))
    return [s.strip() for s in segs if s.strip()]


def main():
    cmd = sys.stdin.read()
    for seg in split_segments(cmd):
        print(seg)


if __name__ == "__main__":
    main()
