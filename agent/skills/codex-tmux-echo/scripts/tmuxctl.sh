#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
tmuxctl.sh [--socket auto|isolated|system|PATH] [--session NAME] [--target TARGET] <command> [args...]

Socket strategy:
  auto     (default) if $TMUX is set -> system tmux; else -> isolated socket under ${TMPDIR:-/tmp}
  isolated always use isolated socket (tmux -S PATH ...)
  system   always use system tmux server (no -S)
  PATH     explicit socket path

Defaults:
  --session: tmux-echo
  --target:  <session> (active pane)

Commands:
  whoami
  new --dir DIR --cmd STRING [--env KEY=VAL ...] [--kill-existing]
  list
  kill
  send --text TEXT [--keys 'Tab,Enter,Escape+Enter,...']
  capture [--lines N]
  wait --pattern REGEX [--timeout S] [--interval S] [--lines N] [--quiet] [--count-increase N]
  report --to TARGET|auto --text TEXT [--enter] [--keys 'Tab,Enter,Escape+Enter,...'] [--submit none|keys|codex] [--clear-input on|off]
         [--progress-pattern REGEX] [--progress-timeout S] [--progress-lines N]

Examples:
  bash scripts/tmuxctl.sh whoami
  bash scripts/tmuxctl.sh --session demo new --dir "$(pwd)" --cmd "bash --noprofile --norc"
  bash scripts/tmuxctl.sh --target demo send --text "echo READY" --keys "Enter"
  bash scripts/tmuxctl.sh --target demo wait --pattern "READY" --timeout 10
EOF
}

SOCKET_MODE="auto"
SESSION="tmux-echo"
TARGET=""

if [[ $# -eq 0 ]]; then
  usage
  exit 2
fi

while [[ $# -gt 0 ]]; do
  case "$1" in
    --socket) SOCKET_MODE="$2"; shift 2;;
    --session) SESSION="$2"; shift 2;;
    --target) TARGET="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    --) shift; break;;
    *) break;;
  esac
done

cmd="${1:-}"
shift || true

if [[ -z "${TARGET}" ]]; then
  TARGET="${SESSION}"
fi

resolve_socket_mode() {
  local mode="$1"
  if [[ "$mode" == "auto" ]]; then
    if [[ -n "${TMUX:-}" ]]; then
      echo "system"
    else
      echo "isolated"
    fi
  else
    echo "$mode"
  fi
}

socket_mode_resolved="$(resolve_socket_mode "$SOCKET_MODE")"

socket_path_default_dir="${CODEX_TMUX_ECHO_SOCKET_DIR:-${TMPDIR:-/tmp}/codex-tmux-echo}"
socket_path_default="${CODEX_TMUX_ECHO_SOCKET:-$socket_path_default_dir/codex-tmux-echo.sock}"

tmux_cmd_prefix=()
case "$socket_mode_resolved" in
  system)
    tmux_cmd_prefix=(tmux)
    ;;
  isolated)
    mkdir -p "$(dirname "$socket_path_default")"
    tmux_cmd_prefix=(tmux -S "$socket_path_default")
    ;;
  /*)
    mkdir -p "$(dirname "$socket_mode_resolved")"
    tmux_cmd_prefix=(tmux -S "$socket_mode_resolved")
    ;;
  *)
    echo "[tmuxctl] invalid --socket: $SOCKET_MODE" >&2
    exit 2
    ;;
esac

tmuxS() {
  "${tmux_cmd_prefix[@]}" "$@"
}

whoami() {
  if [[ -n "${TMUX:-}" ]]; then
    local self session_name pane_id
    self="$(tmux display-message -p '#S:#I.#P' 2>/dev/null || true)"
    session_name="$(tmux display-message -p '#S' 2>/dev/null || true)"
    pane_id="${TMUX_PANE:-}"
    if [[ -z "$pane_id" ]]; then
      pane_id="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
    fi
    echo "in_tmux=1"
    echo "self_target=${self:-unknown}"
    echo "self_session=${session_name:-unknown}"
    echo "self_pane_id=${pane_id:-unknown}"
  else
    echo "in_tmux=0"
    echo "self_target=unknown"
    echo "self_session=unknown"
    echo "self_pane_id=unknown"
  fi

  echo "socket_mode=${socket_mode_resolved}"
  if [[ "${tmux_cmd_prefix[*]}" == "tmux -S "* ]]; then
    echo "socket_path=${tmux_cmd_prefix[2]}"
  else
    echo "socket_path=(system)"
  fi
}

parse_key_seq() {
  local seq="${1:-}"
  seq="${seq// /}"
  IFS=',' read -r -a parts <<< "$seq"
  for part in "${parts[@]}"; do
    case "$part" in
      "" ) continue ;;
      Tab|Enter|Escape|Space) tmuxS send-keys -t "$TARGET" "$part" ;;
      Escape+Enter) tmuxS send-keys -t "$TARGET" Escape Enter ;;
      C-c|C-d|C-u|C-z) tmuxS send-keys -t "$TARGET" "$part" ;;
      *)
        echo "[tmuxctl] unknown key token: $part" >&2
        return 2
        ;;
    esac
  done
}

count_matches() {
  local pattern="$1"
  local text
  text="$(cat)"
  python3 -c '
import re
import sys

pattern = sys.argv[1]
text = sys.stdin.read()
try:
    print(len(list(re.finditer(pattern, text, flags=re.MULTILINE))))
except re.error as e:
    print(f"[tmuxctl] invalid regex pattern: {e}", file=sys.stderr)
    sys.exit(2)
' "$pattern" <<<"$text"
}

count_in_pane() {
  local target="$1"
  local lines="$2"
  local pattern="$3"
  tmuxS capture-pane -p -J -t "$target" -S "-$lines" | count_matches "$pattern"
}

case "$cmd" in
  whoami)
    whoami
    ;;
  new)
    workdir=""
    cmdstr=""
    kill_existing="0"
    env_kv=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --dir) workdir="$2"; shift 2;;
        --cmd) cmdstr="$2"; shift 2;;
        --kill-existing) kill_existing="1"; shift;;
        --env) env_kv+=("$2"); shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "[tmuxctl] unknown arg for new: $1" >&2; exit 2;;
      esac
    done
    if [[ -z "$workdir" || -z "$cmdstr" ]]; then
      echo "[tmuxctl] new requires --dir and --cmd" >&2
      exit 2
    fi
    if tmuxS has-session -t "$SESSION" 2>/dev/null; then
      if [[ "$kill_existing" == "1" ]]; then
        tmuxS kill-session -t "$SESSION"
      else
        echo "[tmuxctl] session exists: $SESSION (use --kill-existing to replace)" >&2
        exit 1
      fi
    fi

    if [[ "${#env_kv[@]}" -gt 0 ]]; then
      tmuxS new-session -d -s "$SESSION" -c "$workdir" "env ${env_kv[*]} $cmdstr"
    else
      tmuxS new-session -d -s "$SESSION" -c "$workdir" "$cmdstr"
    fi
    ;;
  list)
    tmuxS list-sessions || true
    ;;
  kill)
    if tmuxS has-session -t "$SESSION" 2>/dev/null; then
      tmuxS kill-session -t "$SESSION"
    fi
    ;;
  send)
    text=""
    keys=""
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --text) text="$2"; shift 2;;
        --keys) keys="$2"; shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "[tmuxctl] unknown arg for send: $1" >&2; exit 2;;
      esac
    done
    tmuxS send-keys -t "$TARGET" -l -- "$text"
    if [[ -n "$keys" ]]; then
      parse_key_seq "$keys"
    fi
    ;;
  capture)
    lines=200
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --lines) lines="$2"; shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "[tmuxctl] unknown arg for capture: $1" >&2; exit 2;;
      esac
    done
    tmuxS capture-pane -p -J -t "$TARGET" -S "-$lines"
    ;;
  wait)
    pattern=""
    timeout=15
    interval="0.5"
    lines=1000
    quiet="0"
    count_increase="0"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --pattern) pattern="$2"; shift 2;;
        --timeout) timeout="$2"; shift 2;;
        --interval) interval="$2"; shift 2;;
        --lines) lines="$2"; shift 2;;
        --quiet) quiet="1"; shift;;
        --count-increase) count_increase="$2"; shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "[tmuxctl] unknown arg for wait: $1" >&2; exit 2;;
      esac
    done
    if [[ -z "$pattern" ]]; then
      echo "[tmuxctl] wait requires --pattern" >&2
      exit 2
    fi

    baseline_count="0"
    if [[ "$count_increase" != "0" ]]; then
      baseline_count="$(tmuxS capture-pane -p -J -t "$TARGET" -S "-$lines" | python3 -c '
import re
import sys

pattern = sys.argv[1]
text = sys.stdin.read()

try:
    print(len(list(re.finditer(pattern, text, flags=re.MULTILINE))))
except re.error as e:
    print(f"[tmuxctl] invalid regex pattern: {e}", file=sys.stderr)
    sys.exit(2)
' "$pattern")"
    fi

    start_ts="$(date +%s)"
    while true; do
      if [[ "$count_increase" != "0" ]]; then
        current_count="$(tmuxS capture-pane -p -J -t "$TARGET" -S "-$lines" | python3 -c '
import re
import sys

pattern = sys.argv[1]
text = sys.stdin.read()

try:
    print(len(list(re.finditer(pattern, text, flags=re.MULTILINE))))
except re.error as e:
    print(f"[tmuxctl] invalid regex pattern: {e}", file=sys.stderr)
    sys.exit(2)
' "$pattern")"

        required_count="$((baseline_count + count_increase))"
        if [[ "$current_count" -ge "$required_count" ]]; then
          exit 0
        fi
      else
        if tmuxS capture-pane -p -J -t "$TARGET" -S "-$lines" | python3 -c '
import re
import sys

pattern = sys.argv[1]
text = sys.stdin.read()

try:
    matched = re.search(pattern, text, flags=re.MULTILINE) is not None
except re.error as e:
    print(f"[tmuxctl] invalid regex pattern: {e}", file=sys.stderr)
    sys.exit(2)

sys.exit(0 if matched else 1)
' "$pattern"
        then
          exit 0
        fi
      fi
      now_ts="$(date +%s)"
      if (( now_ts - start_ts >= timeout )); then
        if [[ "$quiet" != "1" ]]; then
          echo "[tmuxctl] timeout waiting for pattern: $pattern" >&2
        fi
        exit 1
      fi
      sleep "$interval"
    done
    ;;
  report)
    to="auto"
    text=""
    do_enter="0"
    keys=""
    submit="none"
    clear_input="on"
    progress_pattern='Working|Ran |Explored|Executing|Updated Plan|Checking|Troubleshooting'
    progress_timeout="12"
    progress_lines="800"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --to) to="$2"; shift 2;;
        --text) text="$2"; shift 2;;
        --enter) do_enter="1"; shift;;
        --keys) keys="$2"; shift 2;;
        --submit) submit="$2"; shift 2;;
        --clear-input) clear_input="$2"; shift 2;;
        --progress-pattern) progress_pattern="$2"; shift 2;;
        --progress-timeout) progress_timeout="$2"; shift 2;;
        --progress-lines) progress_lines="$2"; shift 2;;
        -h|--help) usage; exit 0;;
        *) echo "[tmuxctl] unknown arg for report: $1" >&2; exit 2;;
      esac
    done
    if [[ -z "$text" ]]; then
      echo "[tmuxctl] report requires --text" >&2
      exit 2
    fi

    if [[ "$submit" == "none" && -n "$keys" ]]; then
      submit="keys"
    fi
    if [[ "$submit" == "none" && -n "${CODEX_TMUX_ECHO_REPORT_SUBMIT:-}" ]]; then
      submit="$CODEX_TMUX_ECHO_REPORT_SUBMIT"
    fi
    if [[ -z "$keys" && -n "${CODEX_TMUX_ECHO_REPORT_KEYS:-}" ]]; then
      keys="$CODEX_TMUX_ECHO_REPORT_KEYS"
    fi
    if [[ "$to" == "auto" ]]; then
      if [[ -n "${CODEX_TMUX_ECHO_CONTROLLER_TARGET:-}" ]]; then
        to="$CODEX_TMUX_ECHO_CONTROLLER_TARGET"
      elif [[ -n "${TMUX:-}" ]]; then
        to="${TMUX_PANE:-}"
        if [[ -z "$to" ]]; then
          to="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
        fi
      fi
    fi
    if [[ -z "$to" || "$to" == "auto" ]]; then
      echo "[tmuxctl] report --to auto requires running inside tmux, or provide explicit --to" >&2
      exit 2
    fi
    # Best-effort: avoid appending to an in-progress draft in the controller.
    # (For Codex TUI, Esc often exits modes; C-u often clears current input line.)
    if [[ "$submit" == "codex" && "$clear_input" == "on" ]]; then
      tmuxS send-keys -t "$to" Escape C-u 2>/dev/null || true
    fi

    tmuxS send-keys -t "$to" -l -- "$text"

    if [[ "$submit" == "keys" ]]; then
      if [[ -n "$keys" ]]; then
        old_target="$TARGET"
        TARGET="$to"
        parse_key_seq "$keys"
        TARGET="$old_target"
      elif [[ "$do_enter" == "1" ]]; then
        tmuxS send-keys -t "$to" Enter
      fi
      exit 0
    fi

    if [[ "$submit" == "codex" ]]; then
      baseline="$(count_in_pane "$to" "$progress_lines" "$progress_pattern")"
      # Try Tab first (Codex often shows "tab to queue message"), then Esc+Enter fallback.
      attempt_keys=("Tab" "Escape+Enter")
      for k in "${attempt_keys[@]}"; do
        old_target="$TARGET"
        TARGET="$to"
        parse_key_seq "$k"
        TARGET="$old_target"

        start_ts="$(date +%s)"
        while true; do
          now_ts="$(date +%s)"
          if (( now_ts - start_ts >= progress_timeout )); then
            break
          fi
          current="$(count_in_pane "$to" "$progress_lines" "$progress_pattern")"
          if [[ "$current" -gt "$baseline" ]]; then
            exit 0
          fi
          sleep 0.3
        done
      done
      echo "[tmuxctl] report submit=codex: no progress detected after submitting" >&2
      exit 1
    fi

    if [[ "$submit" != "none" ]]; then
      echo "[tmuxctl] invalid --submit: $submit" >&2
      exit 2
    fi
    ;;
  ""|-h|--help)
    usage
    exit 0
    ;;
  *)
    echo "[tmuxctl] unknown command: $cmd" >&2
    usage
    exit 2
    ;;
esac
