# codex-tmux-echo

用 tmux 稳定驱动交互式 CLI：创建 session、发送按键、等待输出，并支持 worker 回传结果到 controller pane（backchannel）。

## ⚠️ 安全提示（必读）

本 skill 使用 `tmux send-keys` 往 pane 里“打字/按键”。如果 target 选错，可能在错误窗口里执行命令（风险很高）。

- 推荐默认 `--report-mode auto`（Codex controller 自动提交；非 Codex 默认只注入草稿）。
- 除非你明确指定了 `--scheduler-target` 并确认目标 pane，否则不要使用 `--report-submit keys` + `Enter`。
- 避免在 controller pane 里展示 secrets；脚本可能会 `capture-pane` 做探测/等待。

## 包含内容

- `SKILL.md`
- `scripts/`

## 安装

> 安装 skill 的本质是：让你的工具能扫描到这个目录里的 `SKILL.md`。

### 方式 A：复制安装（推荐，不使用软链接）

在仓库根目录执行：

```bash
SKILLS_DIR=~/.claude/skills
mkdir -p "$SKILLS_DIR"
cp -R "$(pwd)/agent/skills/codex-tmux-echo" "$SKILLS_DIR/codex-tmux-echo"
```

### 方式 B：软链接安装（开发同步用）

```bash
SKILLS_DIR=~/.claude/skills
mkdir -p "$SKILLS_DIR"
ln -s "$(pwd)/agent/skills/codex-tmux-echo" "$SKILLS_DIR/codex-tmux-echo"
```

### 方式 C：OpenSkills（从 Git 安装）

```bash
# 建议 Node.js 18+；npx 无需预装 openskills
npx openskills install https://github.com/okwinds/miscellany --global
```

然后按 skill 名称 `codex-tmux-echo` 选择/启用（仓库内路径：`agent/skills/codex-tmux-echo`）。

安装后建议重启你的 agent 会话，让它重新扫描 skills。

## 使用

### 1) 离线自测（不联网）

```bash
bash scripts/selftest.sh
```

### 2) 一句话派发（推荐：你只写自然语言任务）

> 适用于：调度侧 Codex 永远运行在 system tmux 里（你在同一个 tmux pane 里执行派发命令）。

1) 启动调度侧 Codex：

```bash
bash scripts/start_scheduler.sh --socket system --session scheduler --workdir /Users/okwinds/Files/工作/opensource
tmux attach -t scheduler
```

2) 直接派发自然语言任务（worker 完成后会回传一条消息到 scheduler，并触发 scheduler 立即处理）：

```bash
bash scripts/codex-tmux-echo 'hello，你好呀'
```

### 2.1) 回传模式（Draft vs Send）

```bash
# 默认：auto（Codex controller 自动提交；非 Codex 默认只注入草稿）
bash scripts/codex-tmux-echo '总结一下当前目录'

# 仅注入草稿（不自动发送）
bash scripts/codex-tmux-echo --report-mode draft '只汇报状态，不要打断输入'

# 强制提交为对话消息（仅当 controller 被识别为 Codex）
bash scripts/codex-tmux-echo --report-mode send '把结论发给调度侧继续处理'
```

> `dispatch.sh` 会自动识别调度侧 controller pane，因此通常不需要你提供 scheduler 的 session 名称。

### 3) 通用 runner（不默认 yolo/full-auto）

```bash
bash scripts/interactive_runner.sh \
  --session tmtest \
  --workdir /Users/okwinds/Files/工作/opensource \
  --cmd 'codex --dangerously-bypass-approvals-and-sandbox --no-alt-screen' \
  --prompt 'hello，你好呀。请在完成后回传 DONE。' \
  --wait-pattern 'DONE' \
  --timeout 120
```

### 4) 监控/排障

```bash
tmux attach -t tmtest
tmux capture-pane -p -J -t tmtest -S -200
```
