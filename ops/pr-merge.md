# PR 终检与合并（从 CLAUDE.md `[PR-GATE]` 外置）

> **要开 PR、审 PR 或合并前，先读本文件**。SHA 绑定与工作区纯净三闸是实测定下来的——
> 只记 OID 证明不了本地审的就是它；审后追加 commit 或 base 推进都会让"已审过"失效。

9. **GitHub 改动一律"只开 PR、先过 Codex 终检、再定合不合"，绝不直接合。** 任何要进 GitHub 仓库的改动，只 `gh pr create` 开 PR，**绝不** `gh pr merge`／push 到 `main` 直接合并——前端、文档、自己开的分支，无一例外。开 PR 后**必须派 Codex 最强模型对抗式审这个 PR**，且**必须把审查对象锁到该 PR 的 head SHA 上**（只记 OID 不够——那证明不了本地审的就是它）：
   ```bash
   # 审前：锁定 head+base 两个 OID，并确认工作区纯净（三闸缺一即阻断）
   eval "$(gh pr view <n> --json headRefOid,baseRefOid -q '"HEAD_OID=\(.headRefOid) BASE_OID=\(.baseRefOid)"')"
   [ "$(git rev-parse HEAD)" = "$HEAD_OID" ]        || { echo "本地 HEAD ≠ PR head，阻断"; exit 1; }
   [ -z "$(git status --porcelain --untracked-files=all)" ] \
     || { echo "工作区不纯净（HEAD 对得上但文件已被改动），阻断"; exit 1; }
   git cat-file -e "$BASE_OID^{commit}" 2>/dev/null \
     || { echo "本地没有该 base commit，先 git fetch，阻断"; exit 1; }
   # ⚠️ review 的基线必须用 $BASE_OID 本身，不能用分支名——
   #    本地 <基线分支> 可能落后/指向别处，那样审的就不是 PR 的实际 diff，
   #    而候选文件记的却是远端 OID，改名 REVIEWED 后比对会错误通过。
   printf 'REVIEWED_HEAD_OID=%s\nREVIEWED_BASE_OID=%s\n' "$HEAD_OID" "$BASE_OID" \
     > "$(git rev-parse --git-path PR<n>_CANDIDATE)"     # 先写【候选】——审查尚未跑
   # ⚠️ 只有在 Codex 审查【成功返回、输出完整、且 L0 主循环完成逐条分诊】之后，才把
   #    PR<n>_CANDIDATE 重命名为 PR<n>_REVIEWED。审查没跑或失败时绝不留下 REVIEWED，
   #    否则合并前的 OID 比对会对着一个从未审过的对象通过（fail-open）。
   ```

### 审查 → 三闸校验 → 原子改名（缺一不可，全程可执行）

```bash
   SENTINEL='<<<PR_REVIEW_COMPLETE>>>'
   # 每轮一个【不可变唯一目录】——否则复审新 head 时，上一轮的 disposition 会把本轮放行
   RUN="$(git rev-parse --git-path "pr<n>/$HEAD_OID")"; mkdir -p "$RUN"
   OUT="$RUN/review.md"
   codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only \
     -o "$OUT" review --base "$BASE_OID" \
     "对抗式审此 PR，默认有罪推定。**完成全部输出后必须在最后一行原样单独打印：${SENTINEL}**"
   rc=$?
   # 三闸（与 Plan-Gate 同款；缺一即视为审查未完成，不得改名）
   { [ $rc -eq 0 ] && [ -s "$OUT" ] \
     && [ "$(tail -n1 "$OUT")" = "$SENTINEL" ] \
     && [ "$(grep -vF "$SENTINEL" "$OUT" | grep -c '[^[:space:]]')" -ge 1 ]; } \
     || { echo "审查未完成（rc=$rc / 空 / 末行非哨兵 / 去哨兵后正文为空），阻断"; exit 1; }

   # L0 主循环逐条分诊，写进【本轮】disposition；只认本轮的、且要有真正的正文
   DISP="$RUN/disposition.md"
   [ -s "$DISP" ] && [ "$(grep -c '[^[:space:]]' "$DISP")" -ge 1 ] \
     || { echo "本轮尚未逐条分诊（或只有空白），不得标记为已审"; exit 1; }

   # 原子晋升：先确认候选文件完好（否则 cat 失败也会生成缺字段的 REVIEWED），再绑定本轮哈希
   CAND="$(git rev-parse --git-path PR<n>_CANDIDATE)"
   REVIEWED="$(git rev-parse --git-path PR<n>_REVIEWED)"
   grep -q '^REVIEWED_HEAD_OID=' "$CAND" && grep -q '^REVIEWED_BASE_OID=' "$CAND" \
     || { echo "候选文件缺 OID 字段，阻断"; exit 1; }
   { cat "$CAND" || exit 1
     printf 'RUN_DIR=%s\nREVIEW_SHA256=%s\nDISPOSITION_SHA256=%s\n' "$RUN" \
       "$(shasum -a 256 "$OUT" | cut -d' ' -f1)" "$(shasum -a 256 "$DISP" | cut -d' ' -f1)"; } \
  > "$CAND.tmp" && mv -f "$CAND.tmp" "$REVIEWED" && rm -f "$CAND"
```
   # 更稳的替代：git worktree add /tmp/pr<n> "$HEAD_OID" 后在该隔离 worktree 内审（同样验纯净）
   **合并前必须与留痕逐一比对**：① 重新取远端 `headRefOid`/`baseRefOid`，**两者都要等于落盘的 `REVIEWED_*`**；② **`RUN_DIR` 下的 review.md / disposition.md 仍存在、非空，且 sha256 等于落盘值**（防留痕被后续审查覆盖）——
   head 变了是"审后又追加 commit"，**base 变了是"基线推进导致 diff 已不同"**，**任一变化即必须重新终检**。
   否则"已审过"审的是另一个 diff、等于没审（`codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only review --base "$BASE_OID"`，或 `codex exec -m gpt-5.6-sol -c model_reasoning_effort="xhigh" -s read-only "对抗式审 PR #<n>／此 diff，有罪推定"`）。L0 主循环读完 Codex 意见后**再拍板**：按意见修了就重新让 Codex 复审；只有 Codex 无异议（或异议已澄清／修掉）才允许 merge。L0 主循环自己绝不擅自直接合、也不在没过 Codex 审查时合。（呼应`[OWNERSHIP]`：终检是输入，go/no-go 由 L0 主循环拍，但"合并前必过 Codex 审"是硬门槛。）
