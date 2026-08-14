# codegraph：代码定位与影响面（从 CLAUDE.md §7 外置）

> **改共用函数 / 聚合函数前先读本文件。** 只在有 `.codegraph/` 的仓库适用。

## 前提

只在**已建索引**的仓库用；没有 `.codegraph/` 就当它不存在——**建不建索引是用户的决定，别擅自建**。

本机已接 MCP + `UserPromptSubmit` hook：代码类提问会**自动注入结构上下文**，不必主动想起。
写 spec / 改措辞 / 问口径这类非代码对话实测注入 **0 字符**，无成本。

## 命令

```bash
codegraph impact <symbol>          # 改它会波及什么、哪些测试会挂
codegraph callers <symbol>         # 谁调用了它
codegraph callees <symbol>         # 它调用了谁
codegraph explore "<问题或符号名>"  # 逐字源码 + 调用路径
```

⚠️ **`impact` / `callers` / `callees` 只有 CLI 有**——MCP 侧默认只暴露 `codegraph_explore`
一个工具（实测 `tools/list` 确认）。**别去找 `mcp__codegraph__impact`，它不存在，走 Bash。**

## 为什么改共用函数前必跑 impact

grep 和语义检索**结构上做不到**这件事,不是快慢之差:一个符号真实的调用图里,常有大量"从头到尾没出现过该符号名"的文件(动态派发、trait impl、wrapper 包装等),grep 永远找不到,其中不少是测试。改共用函数不跑 impact,常见后果是聚合链后置藏雷、常数单测测不出。

## 派子代理时

子代理没有本会话记忆,给路径没用,**把这句写进简报**:

> 本仓已建 codegraph 索引;改共用函数前先跑 `codegraph impact <symbol>`,看波及面与会挂的测试。

## 开销与卫生

索引开销参考:数千节点 / 万余边规模仓库,索引耗时数秒,产物十几 MB。

`.codegraph/` **必须进 `.gitignore`**——机器生成、体积不小,不进版本控制。
