#!/usr/bin/env bash
# 压缩前把会话摘要自主写入 journal/.precompact/，不依赖模型配合。
# 实测依据：PreCompact 的 exit 2 只阻断压缩、不驱动模型；但 hook 可自读 transcript_path。
set -u
IN=$(cat)
J="${CLAUDE_PROJECT_DIR:-$PWD}/docs/superpowers/journal"
[ -d "$J" ] || exit 0

python3 - "$IN" "$J" <<'PY' 2>/dev/null
import json,sys,os,datetime
try:
    d=json.loads(sys.argv[1]); J=sys.argv[2]
    tp=d.get('transcript_path') or ''
    if not (tp and os.path.exists(tp)): sys.exit(0)
    ents=[]
    with open(tp) as f:
        for ln in f:
            try: ents.append(json.loads(ln))
            except Exception: pass
    if not ents: sys.exit(0)
    def txt(e):
        m=e.get('message') or {}
        c=m.get('content')
        if isinstance(c,str): return c
        if isinstance(c,list):
            return ' '.join(b.get('text','') for b in c if isinstance(b,dict) and b.get('type')=='text')
        return ''
    def is_noise(u):
        # 过滤非用户真实输入：斜杠命令、本地命令产物、上下文续接摘要、系统提醒
        for pat in ('<local-command-caveat>','<command-name>','<command-message>',
                    '<local-command-stdout>','<local-command-stderr>',
                    '<system-reminder>','This session is being continued from',
                    'Caveat: The messages below were generated'):
            if u.lstrip().startswith(pat) or pat in u[:200]: return True
        return False
    users=[txt(e) for e in ents if e.get('type')=='user']
    users=[u.strip() for u in users if u.strip() and not is_noise(u)]
    out=os.path.join(J,'.precompact'); os.makedirs(out,exist_ok=True)
    sid=(d.get('session_id') or 'unknown')[:8]
    ts=datetime.datetime.now().strftime('%Y-%m-%d-%H%M%S')
    p=os.path.join(out,f'{ts}-{sid}.md')
    with open(p,'w') as g:
        g.write(f"# 压缩前快照（{d.get('trigger','?')} 触发）\n\n")
        g.write(f"- session: {d.get('session_id')}\n- transcript: {tp}\n")
        g.write(f"- 条目数: {len(ents)}｜用户消息: {len(users)}\n\n## 用户消息序列（截断至 200 字）\n\n")
        for i,u in enumerate(users,1):
            g.write(f"{i}. {u[:200]}\n")
    # 保留最近 20 份
    fs=sorted(f for f in os.listdir(out) if f.endswith('.md'))
    for f in fs[:-20]: os.remove(os.path.join(out,f))
except Exception: pass
PY
exit 0
