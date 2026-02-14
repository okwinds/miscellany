---
name: codex-tmux-echo
version: 0.1.12
author: 肆〇柒/ForOhZen
description: 用 tmux 稳定驱动交互式 CLI：启动 session、发送按键、等待输出就绪，并支持 worker 向 controller pane 回传结果（backchannel）。
---

# codex-tmux-echo

## Overview

这个 skill 提供一套“通用的 tmux 交互编排工具链”，用于稳定控制任意交互式 CLI（Codex/Claude Code/REPL/TUI 等）：

- 可靠创建/复用 tmux session（避免 shell 初始化提示抢输入）
- 发送文本与按键序列（支持 `Tab`/`Enter`/`Escape+Enter` 等）
- 轮询抓取 pane 输出，等待 “ready / progress / done” 特征出现（避免靠 `sleep N` 猜时序）
- 支持 **backchannel 回传**：worker 完成后把摘要回传到 controller 的 pane（支持“仅注入草稿”与“自动提交为对话消息”两种模式）

> 注意：本 skill **不默认**为 Codex 附加 `--yolo` / `--full-auto` 等参数；是否开启由调用方传入 `--cmd` 决定。

## ⚠️ 风险提示（必读）

本 skill 的核心能力是 **`tmux send-keys`**：它可以把文本/按键“打到”任意 tmux pane。这个能力非常强，也意味着**一旦 target 选错，就可能在错误窗口里执行命令**。

请在使用前理解并接受以下风险与边界：

- **误投递风险（高）**：如果 controller/target 识别错了，回传或按键可能落到别的 pane（甚至是生产 shell）。
- **“按键=执行”风险（高）**：`--report-submit keys`（尤其带 `Enter`）可能直接触发 shell 执行；只有在你明确知道 controller 是什么、并且明确指定 `--scheduler-target` 时才建议使用。
- **显式覆盖更危险**：`--report-submit` 会覆盖 `--report-mode` 的安全策略；请把它当成“高级/危险开关”。
- **读取屏幕内容的隐私风险（中）**：脚本会 `capture-pane` 用于探测 Codex pane/等待输出；避免在 controller pane 里显示 secrets（token、私钥、敏感日志）。
- **worker `--cmd` 是任意命令（高）**：`dispatch.sh` 会在 worker session 里执行你传入的 `--cmd`（默认是 `codex --no-alt-screen`）。如果你传入了高权限/破坏性命令，风险由你承担。
- **风控仅是启发式（中）**：`risk-gate` 只做简单模式匹配，不是安全沙盒；它只能“提醒/挡第一道”，不能保证绝对安全。

### 推荐的安全使用方式（强烈建议）

1) **用专用 scheduler pane**：单独开一个 tmux session/window 专门跑调度侧 Codex，不要混用你日常的 shell pane。  
2) **优先使用默认回传策略**：`--report-mode auto`（Codex controller 自动发送；非 Codex 自动降级为仅注入草稿）。  
3) **需要更稳时，显式绑定 controller pane**：在 scheduler pane 内执行派发；或设置 `CODEX_TMUX_ECHO_CONTROLLER_TARGET`；或直接传 `--scheduler-target %<pane_id>`。  
4) **除非你明确知道自己在做什么，否则不要用**：`--report-submit keys --report-keys Enter`。

## Socket Strategy

`--socket auto`（默认）：

- 如果你当前就在 tmux 里（存在环境变量 `TMUX`）：复用当前 tmux server（这样 worker 才能回传到你的 pane）
- 如果不在 tmux：使用隔离 socket（默认路径在 `${TMPDIR:-/tmp}` 下），避免污染系统 tmux

## Scripts

- `scripts/tmuxctl.sh`：tmux 控制器（new/send/wait/capture/report/whoami）
- `scripts/interactive_runner.sh`：通用 runner（启动 worker → 发送 prompt → 自动提交 → 等待 done）
- `scripts/start_scheduler.sh`：一键启动“调度侧 Codex”（system tmux）
- `scripts/dispatch.sh`：一键派发自然语言任务到 worker，并回传到调度侧（对话式协同；支持自动识别 scheduler/controller pane）
- `scripts/codex-tmux-echo`：更短的 wrapper（直接把参数当成自然语言任务）
- `scripts/selftest.sh`：离线自测（不依赖网络/账号）

## Dependencies

- `tmux`
- `bash`
- `python3`（`wait` 子命令用 Python regex 匹配，规避 grep 差异）

## Command Reference

### 1) 离线自测（推荐先跑）

```bash
bash scripts/selftest.sh
```

### 2) 获取当前 controller pane（你在 tmux 内的场景）

```bash
bash scripts/tmuxctl.sh whoami
```

### 3) 启动一个干净 shell 并发送命令

```bash
SESSION=demo
bash scripts/tmuxctl.sh --session "$SESSION" new --dir "$(pwd)" --cmd "bash --noprofile --norc"
bash scripts/tmuxctl.sh --target "$SESSION" send --text 'echo READY' --keys 'Enter'
bash scripts/tmuxctl.sh --target "$SESSION" wait --pattern 'READY' --timeout 10
```

### 4) 通用 runner：tmux 里启动任意交互式 CLI 并发送 prompt

```bash
bash scripts/interactive_runner.sh \
  --session tmtest \
  --workdir /Users/okwinds/Files/工作/opensource \
  --cmd 'codex --dangerously-bypass-approvals-and-sandbox --no-alt-screen' \
  --prompt 'hello，你好呀。请在完成后回传 DONE。' \
  --wait-pattern 'DONE' \
  --timeout 120
```

### 4.1) 推荐工作流：自然语言派发（调度侧固定在 system tmux）

1) 启动调度侧 Codex：

```bash
bash scripts/start_scheduler.sh --socket system --session scheduler --workdir /Users/okwinds/Files/工作/opensource
tmux attach -t scheduler
```

2) 在调度侧 pane 里（或任何能定位到调度侧 pane 的地方）派发自然语言任务到 worker：

```bash
bash scripts/codex-tmux-echo 'hello，你好呀'
```

### 4.2) 让 skill “全局可用”（可选）

如果你的 Skill Runner 通过 `~/.claude/skills` 扫描 skills，可以在仓库根目录执行（复制安装，不使用软链接）：

```bash
SKILLS_DIR=~/.claude/skills
mkdir -p "$SKILLS_DIR"
cp -R "$(pwd)/agent/skills/codex-tmux-echo" "$SKILLS_DIR/codex-tmux-echo"
```

如果你还希望把派发命令变成一个全局 CLI（`codex-tmux-echo`），可以把 wrapper 复制到 PATH（例如 `~/.local/bin`）：

```bash
mkdir -p ~/.local/bin
cp -f "$SKILLS_DIR/codex-tmux-echo/scripts/codex-tmux-echo" ~/.local/bin/codex-tmux-echo
```

`dispatch.sh` 默认会自动识别调度侧 controller pane（优先使用 `TMUX_PANE` / `CODEX_TMUX_ECHO_CONTROLLER_TARGET`），因此 **通常不需要指定 session 名称**。

#### 4.1.2) 回传模式选择（Draft vs Send）

回传有两种常见语义：

- **Draft（仅注入到输入框/Pane，不自动发送）**：更适合“汇报/通知/需要人工确认”的任务，也不会打断调度侧正在编辑的草稿。
- **Send（提交为对话消息）**：更适合需要把结果纳入调度侧上下文、或需要两个 Codex 形成对话协作的场景（worker 回传后调度侧会立即开始处理）。

默认行为为 `--report-mode auto`：

- 如果 controller 被识别为 **Codex pane**：默认 **Send**（否则无法自动对话协作）。
- 如果 controller 不是 Codex：默认 **Draft**（避免把“按键=执行/发送”的假设带到通用 CLI，造成误执行）。

你可以显式指定：

```bash
# 强制仅注入草稿（不自动发送）
bash scripts/codex-tmux-echo --report-mode draft '...'

# 强制提交为对话消息（仅当 controller 是 Codex）
bash scripts/codex-tmux-echo --report-mode send '...'
```

回传文本会带上来源信息（便于调度侧二次对话定位来源）：

```text
ECHO-REPORT: from=<worker_session> | result=<ok|fail|blocked> | details=<one-line>
```

#### 4.1.1) 语义重写与风控（默认开启）

为避免把“调度层元指令”原封不动传给 worker（导致 worker 去“再启动一个 codex”），`dispatch.sh` 默认会：

- `--normalize auto`：尽量把“自然语言/元指令”改写成 worker 可直接执行的具体步骤，并在 prompt 中加入 `[我的理解]` 段落。
- `--risk auto`：遇到高风险操作（如 `sudo`、写系统目录、`rm -rf /` 等）会**先回传给调度者并阻断执行**。
  - 如调度者确认允许，可重新派发并加：`--risk allow`

### 5) worker 侧回传（backchannel：给调度侧 Codex 发消息并立即处理）

如果 runner 注入了下面这些环境变量：

- `CODEX_TMUX_ECHO_CONTROLLER_TARGET`
- `CODEX_TMUX_ECHO_HOME`

那么 worker 可以在任务结束时回传（推荐 `--submit codex`，会尝试提交并检测调度侧开始处理）：

```bash
"$CODEX_TMUX_ECHO_HOME/scripts/tmuxctl.sh" report \
  --to "$CODEX_TMUX_ECHO_CONTROLLER_TARGET" \
  --text 'DONE: ok' \
  --submit codex
```

如果你只想“写入+按键提交”（不等待检测），可以用 `--submit keys` + `--keys "Tab"`：

```bash
"$CODEX_TMUX_ECHO_HOME/scripts/tmuxctl.sh" report \
  --to "$CODEX_TMUX_ECHO_CONTROLLER_TARGET" \
  --text 'DONE: ok' \
  --submit keys \
  --keys "Tab"
```
