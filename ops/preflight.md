# 跑之前查一下（preflight 清单）

> **这是一张清单，不是方法、不是图、不做强制。** 每条都对应一次真实踩过的坑。
> 依据：74 条历史错误的 replay 分析（`.plangate/replay/replay.md`），
> 其中 10 条属"跑之前查一条命令就能避免"。其余 64 条归审查漏斗（L2/L3）与 TDD 管，本清单不碰。
>
> **按需查，不是每条都跑。** 先看这次任务用到什么，只查适用项，其余记 N/A。
> 全查一遍反而制造摩擦——那正是这张表想避免的东西。

## 用法

```
本次任务用到：□ Python  □ bash 脚本  □ GPU  □ 大内存/多进程  □ 远程机器  □ 下载模型
                ↓ 只查勾中的那几组
```

---

## A. 用 Python（任何跑测试/脚本的任务）

**A1 · 解释器是不是你以为的那个**
```bash
which python && python -c "import scipy.linalg, sklearn; print('ok')"
```
不通过就换 `.venv/bin/python`。

⚠️ **必须 import 子模块，不能只 import 顶层。** 本机实测（2026-07-28）：
`import scipy` 通过，`import scipy.linalg` 才炸（`_fblas` 循环导入）——
**只查顶层会给出假绿，正好漏掉这条要防的坑。**
> 踩过：裸 `python` 指向坏的 anaconda3.8，纯逻辑测试照过、碰 sklearn 的在 collection 阶段就报错，
> 同一组测试一次绿一次 10 errors。〔#57〕

## B. 写 bash 脚本

**B1 · shell 版本够不够**
```bash
bash -c 'declare -A _t 2>/dev/null && echo "关联数组可用" || echo "⚠ bash ${BASH_VERSINFO[0]} 不支持关联数组"'
```
> 踩过：Plan-Gate 脚本用 `declare -A`，在 macOS bash 3.2 上**直接崩溃**。〔#58〕

**B2 · `pgrep -f` 会不会匹配到自己**
```bash
pgrep -f "[m]y_script.py"     # 括号写法：模式本身匹配不到自己的命令行
```
不要用 `pgrep -f "x" | grep -v "^$$\$"` —— `$$` 是**当前 shell** 的 PID，
跟 `pgrep` 子进程无关，过滤形同虚设（L2 逮到，2026-07-28 实测确认）。
> 踩过：`pgrep -f` 匹配到 SSH 自身的命令行，**反复误报远程进程仍在运行**。〔#55〕

## C. 要跑大东西（全量实验、长任务）

**C1 · 磁盘余量够不够（含 TMPDIR）**
```bash
df -h . "${TMPDIR:-/tmp}"
```
预估产物大小 × 2 作下限。
> 踩过：`/tmp` 在小根盘上被 fast_downward 填满，**800 局只跑成 550 局**。〔#41〕

**C2 · 并行度 × 每进程线程 ≤ 核数**
```bash
# 按你这套栈实际生效的线程变量取值（MKL/OPENBLAS/NUMEXPR 可能各自独立生效）
CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu); WORKERS=20
THREADS=${OMP_NUM_THREADS:-${MKL_NUM_THREADS:-${OPENBLAS_NUM_THREADS:-1}}}
[ $((WORKERS * THREADS)) -le "$CORES" ] \
  && echo "ok ($WORKERS×$THREADS ≤ $CORES)" \
  || echo "⚠ 超订：$WORKERS×$THREADS > $CORES 核"
```
> 踩过：208 核上开 20 个 BLAS worker（每个分到 1.25 核），**49 分钟零产出**。
> 大矩阵任务应单进程 + 满线程 BLAS。〔#43〕

**C3 · 峰值内存 = 单元大小 × 并发数（按最坏算）**
```bash
# 例：41 层 × 每层张量字节数，与可用内存比
python -c "
peak = 41 * 4096 * 2048 * 4        # 层数 × 维度 × 字节
print(f'峰值估算 {peak/2**30:.1f} GiB')"
free -g 2>/dev/null || vm_stat | head -3
```
估出来接近可用量就分批，别一次性驻留。
> 踩过：41 层张量一次性驻留 + 叠加页缓存，**GPU box 失联约 4 小时**。〔#42〕

**C4 · 关键环境变量设了没**
```bash
: "${B2_LOAD_MODEL:?未设——会导致重复加载模型}"   # 换成你这次的 flag 名
```
> 踩过：启动漏了 `B2_LOAD_MODEL=1`，M1/M0 **各加载一份模型 → CUDA OOM**。〔#39〕

## D. 用 GPU

**D1 · 需要的是哪种能力（compute ≠ graphics）**
```bash
python -c "import torch; print('CUDA', torch.cuda.is_available())"
# 若需渲染，另测 EGL/Vulkan——CUDA 可用不代表能渲染
```
> 踩过：AutoDL 容器只暴露 CUDA compute，**没有 EGL/Vulkan**，
> `eglInitialize` 全部失败 → THOR/ALFRED 生成新颖任务的路线**整条堵死**（root 也改不了）。〔#74〕

## E. 下载模型

**E1 · 关键文件下全了没**
```bash
MODEL_DIR="/path/to/model"
for f in config.json tokenizer_config.json chat_template.jinja; do
  [ -f "$MODEL_DIR/$f" ] && echo "ok  $f" || echo "⚠ 缺 $f"
done
```
> 踩过：`allow_patterns` 漏掉 `chat_template.jinja`，**Gemma 全部 crash**。〔#36〕

## F. 连远程机器

**F1 · 失败先分清是限流还是别的**
```bash
ssh -o ConnectTimeout=10 <host> true 2>&1 | tail -2
# 见到 "Too many authentication failures" / "Connection reset" → 是限流，退避等待
# 见到 "Connection timed out" → 才是网络/负载
```
连续失败时**先停手等几分钟**，别立刻重试（重试本身会加深限流）。
> 踩过：SSH 连续重试**触发限流**，却被错误归因成实例负载或网络故障，白折腾很久。〔#56〕

---

## 这张表管不了什么（诚实边界）

replay 的 74 条错误里，本清单只覆盖 10 条（13.5%）。剩下的：

| 类别 | 条数 | 谁管 |
|---|---:|---|
| 逻辑/口径/实现类 | 63 | L2 跨家族快审 + L3 终检（**已逮到其中 45 条**）、TDD |
| 模型行为类（须实跑才知） | 1 | 探针阶段的小样本试跑 |

**不属于本清单的典型**：`extract_task_type` 只认 train 路径（该由测试覆盖 valid split）、
聚合键与记录粒度不符、bootstrap 用错谱——这些是逻辑 bug，查环境查不出来。

## 维护

- 新增一条 = 必须能指出**一次真实事故**，且**能用一条命令或明确判据查出**
- 某条长期不触发 = 删掉，别攒
- 环境变了（换机器/换框架）某些条目会失效，随事故更新
