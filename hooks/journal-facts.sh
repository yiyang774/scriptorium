#!/usr/bin/env bash
# PostToolUse：把【硬事实】默默攒进草稿，供 Stop 时由模型提炼成日志事件。
# 极度节制：只收 4 类机器可靠判定的事实，绝不记流水账（否则裁决/误报理由会被淹没）。
set -u
IN=$(cat)
J="${CLAUDE_PROJECT_DIR:-$PWD}/docs/superpowers/journal"
[ -d "$J" ] || exit 0
# 只在有"进行中"日志时才攒（没建档的任务不攒）
found=0
for f in "$J"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]-*.md; do
  [ -f "$f" ] || continue; [ -L "$f" ] && continue
  head -30 "$f" | grep -q '^状态：进行中' && { found=1; break; }
done
[ "$found" = 1 ] || exit 0

python3 - "$IN" "$J" <<'PY' 2>/dev/null
import json,sys,os,re,datetime
try:
    d=json.loads(sys.argv[1]); J=sys.argv[2]
    tn=d.get('tool_name') or ''
    ti=d.get('tool_input') or {}
    tr=d.get('tool_response')
    out=[]

    if tn=='Bash':
        cmd=(ti.get('command') or '')[:400]
        so=(tr.get('stdout') or '') if isinstance(tr,dict) else ''
        se=(tr.get('stderr') or '') if isinstance(tr,dict) else ''
        blob=so+se
        # ① 测试结果：【分别】提取，不假设顺序
        #    pytest 有失败时输出 "1 failed, 2 passed"（failed 在前），
        #    若按 "passed, failed" 的顺序写正则，会只抓到 passed 而漏掉 failed = 虚报绿灯。
        if 'pytest' in cmd or 'test' in cmd.lower():
            pas=re.search(r'\b(\d+)\s+passed\b', blob)
            fai=re.search(r'\b(\d+)\s+failed\b', blob)
            err=re.search(r'\b(\d+)\s+error(?:s)?\b', blob)
            skp=re.search(r'\b(\d+)\s+skipped\b', blob)
            if pas or fai or err:
                parts=[]
                if pas: parts.append(f"{pas.group(1)} passed")
                if fai: parts.append(f"**{fai.group(1)} failed**")
                if err: parts.append(f"**{err.group(1)} error**")
                if skp: parts.append(f"{skp.group(1)} skipped")
                flag=" ⚠️未全绿" if (fai or err) else ""
                out.append("测试："+", ".join(parts)+flag)
        # ② PR / commit
        m=re.search(r'https://github\.com/\S+/pull/(\d+)', blob)
        if m: out.append(f"PR #{m.group(1)}：{m.group(0)}")
        if re.match(r'^\s*git\s+commit', cmd):
            m2=re.search(r'\[\S+\s+([0-9a-f]{7,40})\]', blob)
            if m2: out.append(f"commit {m2.group(1)}")
        # ③ 行数复核（numstat 汇总）
        if '--numstat' in cmd and blob.strip():
            tot=0; n=0
            for ln in blob.splitlines():
                p=ln.split('\t')
                if len(p)>=3 and p[0].isdigit() and p[1].isdigit():
                    tot+=int(p[0])-int(p[1]); n+=1
            if n: out.append(f"行数复核：{n} 个文件，净新增 {tot}")
        # ④ Codex 审查调用（Plan-Gate / L2 / L3）
        if 'codex exec' in cmd:
            mm=re.search(r'-m\s+(\S+)', cmd); ef=re.search(r'model_reasoning_effort="?(\w+)', cmd)
            out.append(f"Codex 审查：{mm.group(1) if mm else '?'}"+(f" effort={ef.group(1)}" if ef else ""))

    if not out: sys.exit(0)
    p=os.path.join(J,'.facts-'+datetime.date.today().isoformat()+'.md')
    ts=datetime.datetime.now().strftime('%H:%M')
    with open(p,'a') as g:
        for o in out: g.write(f"- [{ts}] {o}\n")
    # 草稿上限：超 200 行则停止追加（防流水账）
    with open(p) as g: lines=g.readlines()
    if len(lines)>200:
        with open(p,'w') as g: g.writelines(lines[:200]+["- [已达上限，停止攒事实]\n"])
except Exception: pass
PY
exit 0
