#!/usr/bin/env bash
# A包验收矩阵 —— 可执行部分先在【样例夹具】上验证判定逻辑本身是否成立
set -uo pipefail
PASS=0; FAIL=0
ck(){ if [ "$2" = "$3" ]; then echo "  ✅ $1 (=$2)"; PASS=$((PASS+1)); else echo "  ❌ $1 期望=$3 实际=$2"; FAIL=$((FAIL+1)); fi; }

echo "=== B1: git 行数复核（含 ignored-tracked）==="
T=$(mktemp -d); (cd "$T" && git init -q . && git config user.email t@t && git config user.name t
mkdir -p src; echo legacy > src/legacy.py; echo main > src/main.py; git add -A; git commit -qm i
echo "src/legacy.py" > .gitignore; git add .gitignore; git commit -qm g) >/dev/null 2>&1
snap(){ local i; i=$(mktemp)||return 1; rm -f "$i"
  if git rev-parse --verify -q HEAD >/dev/null; then GIT_INDEX_FILE="$i" git read-tree HEAD||return 1; fi
  GIT_INDEX_FILE="$i" git add -A||return 1; GIT_INDEX_FILE="$i" git write-tree||return 1; }
cd "$T"; BEFORE=$(snap)
python3 -c "open('src/legacy.py','a').write('\n'.join(f's{i}' for i in range(50))+'\n')"
python3 -c "open('brand_new.py','w').write('\n'.join(f'n{i}' for i in range(30))+'\n')"
python3 -c "open('src/main.py','a').write('\n'.join(f'a{i}' for i in range(5))+'\n')"
AFTER=$(snap)
NET=$(git diff --numstat "$BEFORE" "$AFTER" | awk '{a+=$1;d+=$2} END{print a-d}')
ck "B1 净新增" "$NET" "85"
ck "B1 暂存区未污染" "$(git status --porcelain | grep -c '^??')" "1"

echo "=== B2: 非 git 复核 ==="
T2=$(mktemp -d); mkdir -p "$T2/proj"; ROOT="$T2/proj"
printf 'l1\nl2\n' > "$ROOT/existing.py"
SNAP=$(mktemp -d); cp -a "$ROOT"/. "$SNAP/before"
python3 -c "open('$ROOT/brand_new.py','w').write('\n'.join(f'n{i}' for i in range(30))+'\n')"
python3 -c "
l=open('$ROOT/existing.py').read().splitlines()[:-1]+[f'a{i}' for i in range(5)]
open('$ROOT/existing.py','w').write('\n'.join(l)+'\n')"
OUT=$(git diff --no-index --numstat "$SNAP/before" "$ROOT" 2>/dev/null); rc=$?
ck "B2 返回码(有差异应为1)" "$rc" "1"
ck "B2 净新增" "$(echo "$OUT" | awk '{a+=$1;d+=$2} END{print a-d}')" "34"

echo "=== B3: 三档判定唯一性 ==="
tier(){ if [ "$1" -le 400 ]; then echo A; elif [ "$1" -le 600 ]; then echo B; else echo C; fi; }
ck "B3 400"  "$(tier 400)" "A"; ck "B3 401" "$(tier 401)" "B"
ck "B3 600"  "$(tier 600)" "B"; ck "B3 601" "$(tier 601)" "C"

echo "=== B4: 错误档 active 筛选（用 SPEC 真实格式：**有效性**：active）==="
M=$(mktemp)
cat > "$M" <<'EOF'
## [E001] 2026-07-26 · 坑一
- **有效性**：active
- **触发场景**：场景一
## [E002] 2026-07-26 · 坑二
- **有效性**：superseded-by-E003
- **触发场景**：场景二
## [E003] 2026-07-26 · 坑三
- **有效性**：obsolete
- **触发场景**：场景三
EOF
N=$(awk '/^## \[E/{id=$0; act=0} /^\- \*\*有效性\*\*：active$/{act=1; print id} ' "$M" | wc -l | tr -d ' ')
ck "B4 active 条目数" "$N" "1"
echo
echo "==== 合计 PASS=$PASS FAIL=$FAIL ===="
[ "$FAIL" -eq 0 ]
