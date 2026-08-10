#!/usr/bin/env python3
"""从 transcript JSONL 机械抽取会话事实，生成任务日志草稿。

**纯结构化抽取，不调任何模型。**

2026-08-07 实测教训：原设计是把 transcript 喂给 Haiku 做纪要，**连续三次被污染**——
transcript 里满是 guard 提示、AskUserQuestion 之类"指令样"文本，纪要模型反复误以为
那是给自己的任务（改提示词、从源头过滤噪声都没根治）。
**把充满指令的文本喂给模型、让它"别把这些当指令"，本身就是不稳的设计。**

改为机械抽取：只提取结构上确定的东西——零模型成本、零污染、100% 可复现、秒级完成。
"为什么这么定"的语义提炼仍归 L0，那本来就不该外包。

抽什么：
  1. 用户消息（裁定在这里）
  2. AskUserQuestion 的问题 + 用户实际选择
  3. 派活：Agent 调用的 model / description
  4. codex 调用：模型档 + effort + 沙箱档
  5. git commit / PR 操作

用法:
  scribe-extract.py <transcript.jsonl>                    # 输出到 stdout
  scribe-extract.py <transcript.jsonl> --journal <目录>    # 追加到 .facts-<日期>.md
"""
import datetime
import json
import os
import re
import sys

# guard/hook 打给模型看的提示——是流程噪声，不是会话事实
NOISE = re.compile(
    r"\[无需证据|EVIDENCE-FIRST\]|\] 拦截|你报了具体数量|没有证据支撑的说法|"
    r"请三选一后再结束本轮|GUARD_OFF|\.guard-off|task-notification|system-reminder"
)


def blocks(content):
    return content if isinstance(content, list) else []


def extract(path):
    events = []

    def add(kind, text):
        t = " ".join(str(text).split())
        if t and not NOISE.search(t):
            events.append((kind, t))

    with open(path, encoding="utf-8") as fh:
        for line in fh:
            line = line.strip()
            if not line:
                continue
            try:
                d = json.loads(line)
            except json.JSONDecodeError:
                continue
            msg = d.get("message") or {}
            role = msg.get("role") or ""
            content = msg.get("content", "")

            if role == "user":
                if isinstance(content, str):
                    if content.strip():
                        add("用户", content[:400])
                else:
                    for b in blocks(content):
                        if not isinstance(b, dict):
                            continue
                        if b.get("type") == "text":
                            add("用户", b.get("text", "")[:400])
                        elif b.get("type") == "tool_result":
                            c = b.get("content")
                            s = c if isinstance(c, str) else " ".join(
                                x.get("text", "") for x in blocks(c) if isinstance(x, dict))
                            if "have been answered" in s:
                                for q, a in re.findall(r'"([^"]{6,120})"="([^"]{1,80})"', s):
                                    add("裁定", f"{q} → **{a}**")

            elif role == "assistant":
                for b in blocks(content):
                    if not isinstance(b, dict) or b.get("type") != "tool_use":
                        continue
                    name = b.get("name", "")
                    inp = b.get("input", {}) or {}
                    if name in ("Agent", "Task"):
                        add("派活", f"{inp.get('model', '?')} ← {inp.get('description', '')}")
                    elif name == "Bash":
                        cmd = inp.get("command", "") or ""
                        if "codex exec" in cmd:
                            m = re.search(r"-m\s+(\S+)", cmd)
                            e = re.search(r'model_reasoning_effort="?(\w+)', cmd)
                            ro = "read-only" if "-s read-only" in cmd else "写权限"
                            add("codex", f"{m.group(1) if m else '?'}"
                                         f"{' ' + e.group(1) if e else ''} [{ro}]")
                        elif re.search(r"\bgit commit\b", cmd):
                            mm = re.search(r'-m\s+["\']([^"\']{4,90})', cmd)
                            add("提交", mm.group(1) if mm else "git commit")
                        elif "gh pr create" in cmd:
                            add("PR", "gh pr create")
    return events


def main():
    if len(sys.argv) < 2:
        print(__doc__, file=sys.stderr)
        return 2
    path = sys.argv[1]
    if not os.path.isfile(path):
        print(f"✗ 找不到 transcript: {path}", file=sys.stderr)
        return 2

    jdir = None
    if "--journal" in sys.argv:
        i = sys.argv.index("--journal")
        if i + 1 < len(sys.argv):
            jdir = sys.argv[i + 1]

    try:
        events = extract(path)
    except OSError as e:
        print(f"✗ 读取失败: {e}", file=sys.stderr)
        return 2
    if not events:
        return 1

    out, prev = [], None
    for kind, txt in events:
        key = (kind, txt[:60])
        if key != prev:
            out.append(f"- **[{kind}]** {txt}")
            prev = key

    body = "\n".join(out)
    header = (f"\n## 会话事实草稿 · {datetime.datetime.now():%Y-%m-%d %H:%M}\n"
              f"> 机械抽取，非模型生成。**L0 据此补写「为什么这么定」再进事件流**；\n"
              f"> 本草稿不是日志，用完可删。共 {len(out)} 条。\n\n")

    if jdir and os.path.isdir(jdir):
        p = os.path.join(jdir, f".facts-{datetime.date.today()}.md")
        with open(p, "a", encoding="utf-8") as g:
            g.write(header + body + "\n")
        print(f"✅ {p}（{len(out)} 条）")
    else:
        sys.stdout.write(header + body + "\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
