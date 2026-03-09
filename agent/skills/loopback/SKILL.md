---
name: loopback
version: 0.1.1
description: "Loopback 迭代开发循环 - 基于 Ralph Loop 思想实现的 Codex 版本。用于创建自引用的迭代开发循环，让 AI 在多次迭代中逐步改进代码，直到任务完成。Use when: (1) 需要多次迭代改进的任务, (2) 复杂功能需要分步实现, (3) 需要自我修正的代码生成, (4) 迭代优化已有代码."
---

# Loopback 迭代开发循环

## 快速开始（推荐）

1) 直接启动（默认会进入“向导模式”）

```
/loopback "修复 X。完成后输出 <promise>DONE</promise>。" --completion-promise "DONE" --max-iterations 10
```

说明：
- 如果当前环境支持交互式输入，`/loopback` 会默认进入向导：先展示全局步骤，再一步步帮你完善参数与契约
- 如果当前环境不支持交互式输入，`/loopback` 会输出步骤概览，并在缺少关键契约时直接失败（避免跑飞）
- 如需跳过向导：加 `--no-wizard`

2) 不确定怎么传参：先看参数说明（不会创建状态文件、不会启动循环）

```
/loopback --guide
```

3) 参数看起来没问题：先用 `--dry-run` 预演（不会创建状态文件、不会启动循环）

```
/loopback "修复 X。完成后输出 <promise>DONE</promise>。" --completion-promise "DONE" --max-iterations 10 --dry-run
```

4) 正式启动

```
/loopback "修复 X。完成后输出 <promise>DONE</promise>。" --completion-promise "DONE" --max-iterations 10
```

## 什么是 Loopback？

Loopback 是一个基于 Ralph Loop 思想的迭代开发方法论，适配到 Codex CLI 环境。

**核心概念：**

```bash
while true; do
  # 从 .codex/loopback.local.md 读取同一条 PROMPT
  # 运行 Codex 一轮（例如：codex exec）
  # 检查停止条件（max-iterations / completion-promise / cancel）
  if is_complete; then break; fi
done
```

同样的提示词被反复发送给 Codex。Codex 通过以下方式"看到"自己的先前工作：
- 文件系统中的修改文件
- git 历史记录
- 之前生成的代码

⚠️ 注意：Codex CLI 本身不会“自动重复同一条 prompt”。Loopback 通过状态文件
`.codex/loopback.local.md` 持久化上下文，再由 driver 脚本反复调用 `codex exec` 来实现循环。

**每次迭代：**
1. Codex 接收**相同**的提示词
2. 在任务上工作，修改文件
3. 尝试完成
4. 检查完成条件
5. 如果未完成，进入下一次迭代
6. 看到之前的工作，逐步改进
7. 直到完成或达到最大迭代次数

## 命令

### /loopback <PROMPT> [OPTIONS]

在当前 Codex 会话中启动 Loopback 循环。

**用法：**
```
/loopback "重构缓存层" --max-iterations 20
/loopback "添加测试" --completion-promise "TESTS COMPLETE"
/loopback "修复认证 bug" --dry-run
```

**选项：**
- `--max-iterations <n>` - 最大迭代次数（默认：无限）
- `--completion-promise <text>` - 完成承诺短语（当该短语出现时停止）
- `--guide` - 输出轻量参数说明（不启动循环）
- `--wizard` - 强制启用向导流程（默认已启用；有些环境会自动降级为非交互预检）
- `--no-wizard` - 跳过默认向导（直接按原始参数运行）
- `--allow-infinite` - 允许缺少停止契约（危险：可能无限运行；不推荐）
- `--dry-run` - 仅显示计划，不执行
- `--no-run` - 仅创建状态文件，不启动 driver（用于手动运行 wrapper/调试）
- `--reuse-session` - 复用同一个 Codex session（默认，更像 Ralph Loop 的“同一对话”迭代）
- `--fresh-session` - 每轮启动新 Codex session（更隔离，但更不“自引用对话”）

### /cancel-loop

取消活动的 Loopback 循环。

**用法：**
```
/cancel-loop
```

注意：不要把取消命令当成 prompt 传给 `/loopback`（例如 `/loopback /cancel-loop`）。取消应使用 `/cancel-loop`，或手动删除 `.codex/loopback.local.md`。

## 完成承诺

为了标记任务完成，Codex 必须输出一个 `<promise>` 标签：

```
<promise>TASK COMPLETE</promise>
```

Loopback 会查找这个特定的标签。如果没有它（或 `--max-iterations`），Loopback 会无限运行。

### 建议的“契约写法”（让 loop 更容易收敛）

强烈建议在 PROMPT 里把“完成标准”写得像可验证的契约，而不是一句“做完就说 DONE”。例如：

```
目标：修复认证 bug。
验收：
- `pytest -q` 全绿
- 复现步骤 A 不再报错
完成后输出：<promise>DONE</promise>
若未完成：说明阻塞点 + 下一步要做什么 + 哪些验证已完成/未完成（不要输出 promise）
```

### 最佳实践：默认要求“停止契约”

为了避免无限跑飞（尤其在非交互环境），Loopback 默认会要求你至少提供一个停止条件（满足其一即可）：
- `--completion-promise 'DONE'`
- `--max-iterations 10`

如果你确实要允许无限循环（不推荐），需要显式声明：
- `--allow-infinite`

实现细节：driver 会将每一轮输出写入 `.codex/loopback.outputs/iteration-N.log`，并在该输出中检测
是否出现 `<promise>COMPLETION_PROMISE</promise>`。

更稳健的实现：在 `--reuse-session` 模式下，driver 会使用 `codex exec --json`/`codex exec resume --json`，
从 JSON 事件 `thread.started.thread_id` 获取 `session_id`，避免依赖本地 session 文件名/日期推断。

另外：driver 会在“当前目录不是 git repo”时自动为 `codex exec` 添加 `--skip-git-repo-check`，这样你可以在
类似 `~/Documents/GitHub` 这种“仓库集合目录”里直接跑用例（仍然建议在目标仓库根目录运行以提升速度/减少上下文噪音）。

## 自引用机制

"循环"不意味着 Codex 与自己对话。它的意思是：
- 相同的提示词重复
- Codex 的工作在文件中持久化
- 每次迭代看到之前的尝试
- 逐步构建向目标迈进

## 示例

### 交互式 Bug 修复

```
/loopback "修复 auth.ts 中的令牌刷新逻辑。当所有测试通过时输出 <promise>FIXED</promise>。" --completion-promise "FIXED" --max-iterations 10
```

你会看到 Loopback：
- 尝试修复
- 运行测试
- 看到失败
- 迭代解决方案
- 在当前会话中

## 何时使用 Loopback

**适用于：**
- 定义明确、成功标准清晰的目标
- 需要迭代和改进的任务
- 带有自我修正的迭代开发
- 全新项目

**不适用于：**
- 需要人工判断或设计决策的任务
- 一次性操作
- 成功标准不明确的目标
- 调试生产问题（改用针对性调试）

## 与 Ralph Loop 的区别

| 特性 | Ralph Loop (Claude Code) | Loopback (Codex) |
|------|-------------------------|------------------|
| 环境 | Claude Code CLI | Codex CLI |
| 迭代机制 | stop hook | 文件状态检查 |
| 状态存储 | `.claude/ralph-loop.local.md` | `.codex/loopback.local.md` |
| 命令 | `/ralph-loop`, `/cancel-ralph` | `/loopback`, `/cancel-loop` |
| 工作原理 | 拦截退出信号 | 检查完成条件 |

## 工作原理

### 初始化

当运行 `/loopback` 命令时：
1. 创建 `.codex/loopback.local.md` 状态文件
2. 设置初始迭代计数为 1
3. 记录最大迭代次数和完成承诺
4. 保存原始提示词

### 迭代过程

driver 每次迭代会：
1. 读取 `.codex/loopback.local.md`
2. 运行 `codex exec`（同一条 PROMPT）
3. 将输出写入 `.codex/loopback.outputs/iteration-N.log`
4. 检查停止条件：
   - 是否达到 `--max-iterations`
   - 是否在输出中检测到 `<promise>COMPLETION_PROMISE</promise>`
   - 状态文件是否被 `/cancel-loop` 删除（视为取消）
5. 若未满足停止条件：递增 `iteration` 并进入下一轮

### 清理

当运行 `/cancel-loop` 时：
1. 检查 `.codex/loopback.local.md` 是否存在
2. 如果存在，读取当前迭代数
3. 删除状态文件
4. 报告取消状态和迭代数
