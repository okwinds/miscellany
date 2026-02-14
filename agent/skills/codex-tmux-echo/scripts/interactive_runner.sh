#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
interactive_runner.sh --session NAME --workdir DIR --cmd STRING --prompt TEXT [options]

This is a generic runner:
  - starts an interactive program inside a tmux session (command is provided by caller)
  - waits for readiness
  - sends a prompt and tries to submit (Tab -> Enter -> Escape+Enter)
  - waits for a done pattern

It does NOT add yolo/full-auto flags by default.

Options:
  --socket auto|isolated|system|PATH   (default: auto)
  --ready-pattern REGEX               (default: broad Codex/TUI prompts)
  --progress-pattern REGEX            (default: broad progress hints)
  --wait-pattern REGEX                (required)
  --timeout SECONDS                   (default: 120)
  --report-to TARGET|auto|none        (default: auto)
  --report-keys KEYS                 (optional; e.g. "Tab" to submit into Codex controller chat)
  --report-submit none|keys|codex     (default: codex)
  --prompt-template none|strict       (default: strict)
  --expect-report-pattern REGEX       (optional; waits on controller pane)
  --expect-report-timeout SECONDS     (default: 90)

Backchannel:
  If --report-to is not 'none', this script injects:
    CODEX_TMUX_ECHO_CONTROLLER_TARGET
    CODEX_TMUX_ECHO_HOME
  so the worker can report back by calling:
    "$CODEX_TMUX_ECHO_HOME/scripts/tmuxctl.sh" report --to "$CODEX_TMUX_ECHO_CONTROLLER_TARGET" --text "..."
EOF
}

SOCKET_MODE="auto"
SESSION=""
WORKDIR=""
CMDSTR=""
PROMPT=""

READY_PATTERN='OpenAI Codex|for shortcuts|tab to queue message|context left|Tip:'
PROGRESS_PATTERN='Working|Ran |Explored|Executing|Updated Plan|Checking|Troubleshooting|Use /skills'
WAIT_PATTERN=""
TIMEOUT="120"

REPORT_TO="auto"
REPORT_KEYS=""
REPORT_SUBMIT="codex"
PROMPT_TEMPLATE="strict"
EXPECT_REPORT_PATTERN=""
EXPECT_REPORT_TIMEOUT="90"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --socket) SOCKET_MODE="$2"; shift 2;;
    --session) SESSION="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    --cmd) CMDSTR="$2"; shift 2;;
    --prompt) PROMPT="$2"; shift 2;;
    --ready-pattern) READY_PATTERN="$2"; shift 2;;
    --progress-pattern) PROGRESS_PATTERN="$2"; shift 2;;
    --wait-pattern) WAIT_PATTERN="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    --report-to) REPORT_TO="$2"; shift 2;;
    --report-keys) REPORT_KEYS="$2"; shift 2;;
    --report-submit) REPORT_SUBMIT="$2"; shift 2;;
    --prompt-template) PROMPT_TEMPLATE="$2"; shift 2;;
    --expect-report-pattern) EXPECT_REPORT_PATTERN="$2"; shift 2;;
    --expect-report-timeout) EXPECT_REPORT_TIMEOUT="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "[interactive_runner] unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ -z "$SESSION" || -z "$WORKDIR" || -z "$CMDSTR" || -z "$PROMPT" || -z "$WAIT_PATTERN" ]]; then
  usage
  exit 2
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUXCTL="$SCRIPT_DIR/tmuxctl.sh"
SKILL_HOME="$(cd "$SCRIPT_DIR/.." && pwd)"

controller_target=""
if [[ "$REPORT_TO" == "auto" ]]; then
  if [[ -n "${TMUX:-}" ]]; then
    controller_target="${TMUX_PANE:-}"
    if [[ -z "$controller_target" ]]; then
      controller_target="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
    fi
  fi
elif [[ "$REPORT_TO" == "none" ]]; then
  controller_target=""
else
  controller_target="$REPORT_TO"
fi

env_args=()
if [[ -n "$controller_target" ]]; then
  env_args+=(--env "CODEX_TMUX_ECHO_CONTROLLER_TARGET=$controller_target")
  env_args+=(--env "CODEX_TMUX_ECHO_HOME=$SKILL_HOME")
  if [[ -n "$REPORT_KEYS" ]]; then
    env_args+=(--env "CODEX_TMUX_ECHO_REPORT_KEYS=$REPORT_KEYS")
  fi
  if [[ -n "$REPORT_SUBMIT" ]]; then
    env_args+=(--env "CODEX_TMUX_ECHO_REPORT_SUBMIT=$REPORT_SUBMIT")
  fi
fi

prompt_final="$PROMPT"
if [[ "$PROMPT_TEMPLATE" == "strict" && -n "$controller_target" ]]; then
  prompt_final=$'[约束]\n'
  prompt_final+=$'1) 不要创建/操作 tmux（不要新建 session/pane，不要 attach/detach）。\n'
  prompt_final+=$'2) 不要执行与任务无关的 bootstrap/探索；只完成用户 prompt 里描述的任务。\n\n'
  prompt_final+=$'[回传]\n'
  prompt_final+=$'任务结束后，请在 shell 中执行（不要执行其他命令；只执行这一条回传命令）：\n'
  prompt_final+="\"$SKILL_HOME/scripts/tmuxctl.sh\" report --to \"$controller_target\" --text \"DONE: 用一句话总结结果\" --submit \"$REPORT_SUBMIT\""
  if [[ "$REPORT_SUBMIT" == "keys" && -n "$REPORT_KEYS" ]]; then
    prompt_final+=" --keys \"$REPORT_KEYS\""
  fi
  prompt_final+=$'\n\n[用户任务]\n'
  prompt_final+="$PROMPT"
fi

echo "[interactive_runner] session=$SESSION workdir=$WORKDIR report_to=${controller_target:-none}"

bash "$TMUXCTL" --socket "$SOCKET_MODE" --session "$SESSION" new --dir "$WORKDIR" --cmd "$CMDSTR" --kill-existing "${env_args[@]}"

# If Codex prompts for "trust this directory", accept it (best-effort).
accept_trust_prompt() {
  local tries=6
  local i
  for ((i=0; i<tries; i++)); do
    if bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" capture --lines 200 | grep -E -q 'Do you trust the contents of this directory\\?|Press enter to continue'; then
      bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" send --text "" --keys "Enter"
      sleep 0.3
      continue
    fi
    break
  done
}

# Wait for TUI ready (best-effort)
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" wait --pattern "$READY_PATTERN" --timeout 20 --interval 0.2 --lines 400 --quiet || true
accept_trust_prompt || true
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" wait --pattern "$READY_PATTERN" --timeout 10 --interval 0.2 --lines 400 --quiet || true

# Send prompt (no implicit submit here)
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" send --text "$prompt_final"

# Submit strategy: Tab -> Enter -> Esc+Enter; detect progress using PROGRESS_PATTERN
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" send --text "" --keys "Tab"
if ! bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" wait --pattern "$PROGRESS_PATTERN" --timeout 10 --interval 0.2 --lines 500 --quiet; then
  bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" send --text "" --keys "Enter"
  if ! bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" wait --pattern "$PROGRESS_PATTERN" --timeout 3 --interval 0.2 --lines 500 --quiet; then
    bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" send --text "" --keys "Escape+Enter"
  fi
fi

# Wait for completion signal
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION" wait --pattern "$WAIT_PATTERN" --timeout "$TIMEOUT" --interval 1 --lines 1200 --count-increase 1

if [[ -n "$EXPECT_REPORT_PATTERN" ]]; then
  if [[ -z "$controller_target" ]]; then
    echo "[interactive_runner] --expect-report-pattern requires --report-to (or running inside tmux with --report-to auto)" >&2
    exit 2
  fi
  bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$controller_target" wait \
    --pattern "$EXPECT_REPORT_PATTERN" --timeout "$EXPECT_REPORT_TIMEOUT" --interval 0.5 --lines 600 --count-increase 1
fi

echo "[interactive_runner] done"
echo "To monitor:"
if [[ "$SOCKET_MODE" == "system" || ( "$SOCKET_MODE" == "auto" && -n "${TMUX:-}" ) ]]; then
  echo "  tmux attach -t \"$SESSION\""
  echo "  tmux capture-pane -p -J -t \"$SESSION\" -S -200"
else
  echo "  bash \"$TMUXCTL\" --socket \"$SOCKET_MODE\" --target \"$SESSION\" capture --lines 200"
fi
