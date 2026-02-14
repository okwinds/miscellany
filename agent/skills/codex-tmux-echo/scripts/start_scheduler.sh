#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
start_scheduler.sh [options]

Purpose:
  Start a scheduler Codex agent in a tmux session. The scheduler is instructed
  to treat incoming messages as tasks and to coordinate with workers via
  codex-tmux-echo backchannel reports.

Options:
  --socket system|auto|isolated|PATH   (default: system)
  --session NAME                      (default: scheduler)
  --workdir DIR                       (default: current dir)
  --cmd STRING                        (default: codex --no-alt-screen)

Notes:
  - This script does not attach; use: tmux attach -t <session>
EOF
}

SOCKET_MODE="system"
SESSION="scheduler"
WORKDIR="$(pwd)"
CMDSTR="codex --no-alt-screen"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --socket) SOCKET_MODE="$2"; shift 2;;
    --session) SESSION="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    --cmd) CMDSTR="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "[start_scheduler] unknown arg: $1" >&2; exit 2;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUXCTL="$SCRIPT_DIR/tmuxctl.sh"

INSTRUCTIONS=$'你是“调度侧 Codex”。目标：高效协同多个 worker。\n'
INSTRUCTIONS+=$'\n[输入规则]\n'
INSTRUCTIONS+=$'1) 用户发来的自然语言=一个任务。你需要拆分、派发给 worker（通过 shell 命令调用 codex-tmux-echo 的 dispatch.sh）。\n'
INSTRUCTIONS+=$'2) 如果收到以 "ECHO-REPORT:" 开头的消息：这是 worker 回传结果。你必须只总结/记录，不要再派发（避免递归）。\n'
INSTRUCTIONS+=$'\n[执行约束]\n'
INSTRUCTIONS+=$'1) 不要创建/操作 tmux（除了通过 codex-tmux-echo 脚本）。\n'
INSTRUCTIONS+=$'2) 不要跑无关 bootstrap/探索；除非用户明确要求。\n'
INSTRUCTIONS+=$'\n[派发方式]\n'
INSTRUCTIONS+=$'对每个任务，运行：\n'
INSTRUCTIONS+="bash \"$SCRIPT_DIR/dispatch.sh\" --socket system --scheduler \"$SESSION\" --task-stdin <<'TASK'\n"
INSTRUCTIONS+=$'<把任务原文贴在这里>\n'
INSTRUCTIONS+=$'TASK\n'
INSTRUCTIONS+=$'\n'

bash "$TMUXCTL" --socket "$SOCKET_MODE" --session "$SESSION" new --dir "$WORKDIR" --cmd "$CMDSTR" --kill-existing

# Send the scheduler operating instructions as the first message and submit.
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" send --text "$INSTRUCTIONS" --keys "Tab"

echo "[start_scheduler] started: $SESSION (socket=$SOCKET_MODE)"
echo "To attach: tmux attach -t \"$SESSION\""
