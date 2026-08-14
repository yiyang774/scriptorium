# 跑之前查一下（preflight 清单）

> **这是一张清单,不是方法、不是图、不做强制。** 每条对应真实踩过的坑,查一条命令就能避免。审查漏斗(L2/L3)与 TDD 管的问题不在本清单内。
>
> **按需查,不是每条都跑。** 先看这次任务用到什么,只查适用项,其余记 N/A。全查一遍反而制造摩擦——那正是这张表想避免的东西。

## 用法

```
本次任务用到:□ Python  □ bash 脚本  □ GPU  □ 大内存/多进程  □ 远程机器  □ 下载模型
                ↓ 只查勾中的那几组
```

---

## A. 用 Python(任何跑测试/脚本的任务)

**A1 · 解释器是不是你以为的那个**
```bash
which python && python -c "import scipy.linalg, sklearn; print('ok')"
```
不通过就换 `.venv/bin/python`。

⚠️ **必须 import 子模块,不能只 import 顶层。** 例:`import scipy` 通过,`import scipy.linalg` 才炸(`_fblas` 循环导入)——**只查顶层会给出假绿,正好漏掉这条要防的坑。**

## B. 写 bash 脚本

**B1 · shell 版本够不够**
```bash
bash -c 'declare -A _t 2>/dev/null && echo "关联数组可用" || echo "⚠ bash ${BASH_VERSINFO[0]} 不支持关联数组"'
```
> macOS 自带 bash 3.2 不支持 `declare -A`——脚本用到必须先测。

**B2 · `pgrep -f` 会不会匹配到自己**
```bash
pgrep -f "[m]y_script.py"     # 括号写法:模式本身匹配不到自己的命令行
```
不要用 `pgrep -f "x" | grep -v "^$$\$"` —— `$$` 是**当前 shell** 的 PID,跟 `pgrep` 子进程无关,过滤形同虚设。

## C. 要跑大东西(全量实验、长任务)

**C1 · 磁盘余量够不够(含 TMPDIR)**
```bash
df -h . "${TMPDIR:-/tmp}"
```
预估产物大小 × 2 作下限。`/tmp` 常挂在小根盘上,被临时文件填满会静默截断结果。

**C2 · 并行度 × 每进程线程 ≤ 核数**
```bash
# 按你这套栈实际生效的线程变量取值(MKL/OPENBLAS/NUMEXPR 可能各自独立生效)
CORES=$(nproc 2>/dev/null || sysctl -n hw.ncpu); WORKERS=20
THREADS=${OMP_NUM_THREADS:-${MKL_NUM_THREADS:-${OPENBLAS_NUM_THREADS:-1}}}
[ $((WORKERS * THREADS)) -le "$CORES" ] \
  && echo "ok ($WORKERS×$THREADS ≤ $CORES)" \
  || echo "⚠ 超订:$WORKERS×$THREADS > $CORES 核"
```
BLAS 超订会让每 worker 分不到整数核,总吞吐反而崩(**详见 memory `blas-oversubscription-trap`**)。大矩阵任务应单进程 + 满线程 BLAS。

**C3 · 峰值内存 = 单元大小 × 并发数(按最坏算)**
```bash
# 例:41 层 × 每层张量字节数,与可用内存比
python -c "
peak = 41 * 4096 * 2048 * 4        # 层数 × 维度 × 字节
print(f'峰值估算 {peak/2**30:.1f} GiB')"
free -g 2>/dev/null || vm_stat | head -3
```
估出来接近可用量就分批,别一次性驻留(否则叠加页缓存会让机器失联)。

**C4 · 关键环境变量设了没**
```bash
: "${B2_LOAD_MODEL:?未设——会导致重复加载模型}"   # 换成你这次的 flag 名
```
漏设常见后果:两个 stage 各自加载一份模型 → CUDA OOM。

## D. 用 GPU

**D1 · 需要的是哪种能力(compute ≠ graphics)**
```bash
python -c "import torch; print('CUDA', torch.cuda.is_available())"
# 若需渲染,另测 EGL/Vulkan——CUDA 可用不代表能渲染
```
云容器常只暴露 CUDA compute 而没有 EGL/Vulkan(**详见 memory `gpu-container-no-graphics-rendering`**);渲染路线要另测。

## E. 下载模型

**E1 · 关键文件下全了没**
```bash
MODEL_DIR="/path/to/model"
for f in config.json tokenizer_config.json chat_template.jinja; do
  [ -f "$MODEL_DIR/$f" ] && echo "ok  $f" || echo "⚠ 缺 $f"
done
```
`allow_patterns` 漏一个模板文件足以让整个模型加载失败。

## F. 连远程机器

**F1 · 失败先分清是限流还是别的**
```bash
ssh -o ConnectTimeout=10 <host> true 2>&1 | tail -2
# 见到 "Too many authentication failures" / "Connection reset" → 是限流,退避等待
# 见到 "Connection timed out" → 才是网络/负载
```
连续失败时**先停手等几分钟**,别立刻重试(重试本身会加深限流)。

---

## 这张表管不了什么(诚实边界)

本清单只覆盖"跑之前查一条命令就能避免"这一类。**逻辑/口径/实现 bug、模型行为(须实跑才知)——不属于本清单**,分别归 L2/L3 审查漏斗 + TDD 覆盖 + 探针阶段小样本试跑。

**不属于本清单的典型**:`extract_task_type` 只认 train 路径(该由测试覆盖 valid split)、聚合键与记录粒度不符、bootstrap 用错谱——这些是逻辑 bug,查环境查不出来。

## 维护

- 新增一条 = 必须能指出**一次真实事故**,且**能用一条命令或明确判据查出**
- 某条长期不触发 = 删掉,别攒
- 环境变了(换机器/换框架)某些条目会失效,随事故更新
