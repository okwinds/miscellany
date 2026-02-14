#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
dispatch.sh --task TEXT [options]
dispatch.sh --task-stdin [options]    # read task from stdin

Purpose:
  Dispatch a natural-language task to a worker tmux session (running an interactive CLI),
  then have the worker report back to the scheduler (controller) as a *message* and
  trigger immediate processing on the scheduler side.

Defaults are tuned for: scheduler always runs on *system tmux*.

Options:
  --socket system|auto|isolated|PATH   (default: system)
  --workdir DIR                       (default: current dir)
  --scheduler SESSION|auto            (default: auto; detect current Codex pane)
  --scheduler-target TARGET|auto      (default: auto; pane_id like %3 is best)
  --worker SESSION|auto               (default: auto => worker-<epoch>)
  --cmd STRING                        (default: codex --no-alt-screen)
  --timeout SECONDS                   (default: 600)
  --normalize auto|off                (default: auto; rewrite "meta" tasks into concrete worker steps when possible)
  --preflight auto|off                (default: auto; fail fast for known-unwritable paths like /home/* on macOS)
  --risk auto|allow|off               (default: auto; report and stop on high-risk operations unless allow)

Reporting:
  --report-prefix TEXT                (default: ECHO-REPORT)
  --report-mode auto|draft|send       (default: auto; auto => codex controller -> send; otherwise -> draft)
  --report-submit codex|keys|none     (default: auto via --report-mode; explicit --report-submit overrides)
  --report-keys KEYS                  (default: empty; used if submit=keys)
  --clear-input on|off                (default: on; only affects submit=codex)

Done detection:
  --done-marker TEXT                  (default: auto => __ECHO_DONE_<epoch>__)

Examples:
  bash scripts/dispatch.sh --task '帮我总结一下当前目录下的 README 结构'
  printf '%s' 'hello 你好' | bash scripts/dispatch.sh --task-stdin
EOF
}

SOCKET_MODE="system"
WORKDIR="$(pwd)"
SCHEDULER="auto"
SCHEDULER_TARGET="auto"
WORKER="auto"
CMDSTR="codex --no-alt-screen"
TIMEOUT="600"
NORMALIZE="auto"
PREFLIGHT="auto"
RISK="auto"

REPORT_PREFIX="ECHO-REPORT"
REPORT_MODE="auto"
REPORT_SUBMIT=""
REPORT_SUBMIT_EXPLICIT="0"
REPORT_KEYS=""
CLEAR_INPUT="on"

DONE_MARKER="auto"

TASK=""
TASK_STDIN="0"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --socket) SOCKET_MODE="$2"; shift 2;;
    --workdir) WORKDIR="$2"; shift 2;;
    --scheduler) SCHEDULER="$2"; shift 2;;
    --scheduler-target) SCHEDULER_TARGET="$2"; shift 2;;
    --worker) WORKER="$2"; shift 2;;
    --cmd) CMDSTR="$2"; shift 2;;
    --timeout) TIMEOUT="$2"; shift 2;;
    --normalize) NORMALIZE="$2"; shift 2;;
    --preflight) PREFLIGHT="$2"; shift 2;;
    --risk) RISK="$2"; shift 2;;
    --task) TASK="$2"; shift 2;;
    --task-stdin) TASK_STDIN="1"; shift;;
    --report-prefix) REPORT_PREFIX="$2"; shift 2;;
    --report-mode) REPORT_MODE="$2"; shift 2;;
    --report-submit) REPORT_SUBMIT="$2"; REPORT_SUBMIT_EXPLICIT="1"; shift 2;;
    --report-keys) REPORT_KEYS="$2"; shift 2;;
    --clear-input) CLEAR_INPUT="$2"; shift 2;;
    --done-marker) DONE_MARKER="$2"; shift 2;;
    -h|--help) usage; exit 0;;
    *) echo "[dispatch] unknown arg: $1" >&2; exit 2;;
  esac
done

if [[ "$TASK_STDIN" == "1" ]]; then
  TASK="$(cat)"
fi

if [[ -z "$TASK" ]]; then
  echo "[dispatch] missing --task (or --task-stdin)" >&2
  exit 2
fi

if [[ "$WORKER" == "auto" ]]; then
  WORKER="worker-$(date +%s)"
fi

if [[ "$DONE_MARKER" == "auto" ]]; then
  DONE_MARKER="__ECHO_DONE_$(date +%s)__"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUXCTL="$SCRIPT_DIR/tmuxctl.sh"

detect_controller_target() {
  local controller=""

  if [[ "$SCHEDULER_TARGET" != "auto" ]]; then
    echo "$SCHEDULER_TARGET"
    return 0
  fi

  if [[ -n "${CODEX_TMUX_ECHO_CONTROLLER_TARGET:-}" ]]; then
    echo "$CODEX_TMUX_ECHO_CONTROLLER_TARGET"
    return 0
  fi

  if [[ -n "${TMUX:-}" ]]; then
    controller="${TMUX_PANE:-}"
    if [[ -z "$controller" ]]; then
      controller="$(tmux display-message -p '#{pane_id}' 2>/dev/null || true)"
    fi
    if [[ -n "$controller" ]]; then
      echo "$controller"
      return 0
    fi
  fi

  if [[ "$SCHEDULER" != "auto" ]]; then
    echo "$SCHEDULER"
    return 0
  fi

  # Outside tmux: try to find exactly 1 attached pane running "codex".
  local matches
  matches="$(tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{session_attached}' 2>/dev/null | awk '$3==1 && $2=="codex" {print $1}' || true)"
  local n
  n="$(printf '%s\n' "$matches" | sed '/^$/d' | wc -l | tr -d ' ')"
  if [[ "$n" == "1" ]]; then
    echo "$matches" | head -n 1
    return 0
  fi

  # Fallback: detect a Codex pane by content markers (handles cases where pane_current_command is "node").
  local attached
  attached="$(tmux list-panes -a -F '#{pane_id} #{session_attached}' 2>/dev/null | awk '$2==1 {print $1}' || true)"
  local hit_ids=()
  while IFS= read -r pid; do
    [[ -z "$pid" ]] && continue
    if tmux capture-pane -p -J -t "$pid" -S -200 2>/dev/null | grep -E -q "OpenAI Codex|tab to queue message|Use /skills|dangerously-bypass-approvals-and-sandbox"; then
      hit_ids+=("$pid")
    fi
  done <<<"$attached"

  if [[ "${#hit_ids[@]}" == "1" ]]; then
    echo "${hit_ids[0]}"
    return 0
  fi

  return 1
}

controller_target="$(detect_controller_target || true)"
if [[ -z "$controller_target" ]]; then
  echo "[dispatch] cannot auto-detect scheduler/controller target." >&2
  echo "[dispatch] run this INSIDE the scheduler tmux pane, or set CODEX_TMUX_ECHO_CONTROLLER_TARGET, or pass --scheduler-target." >&2
  echo "[dispatch] hints:" >&2
  echo "  tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{session_name} #{window_index}.#{pane_index}'" >&2
  exit 1
fi

detect_controller_kind() {
  local target="$1"
  local text=""
  text="$(bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$target" capture --lines 220 2>/dev/null || true)"
  if echo "$text" | grep -E -q "OpenAI Codex|tab to queue message|dangerously-bypass-approvals-and-sandbox|Use /skills|for shortcuts"; then
    echo "codex"
  else
    echo "unknown"
  fi
}

controller_kind="$(detect_controller_kind "$controller_target")"

effective_report_submit=""
send_blocked_reason=""
if [[ "$REPORT_SUBMIT_EXPLICIT" == "1" ]]; then
  effective_report_submit="$REPORT_SUBMIT"
else
  case "$REPORT_MODE" in
    auto)
      if [[ "$controller_kind" == "codex" ]]; then
        effective_report_submit="codex"
      else
        effective_report_submit="none"
      fi
      ;;
    draft)
      effective_report_submit="none"
      ;;
    send)
      if [[ "$controller_kind" == "codex" ]]; then
        effective_report_submit="codex"
      else
        effective_report_submit="none"
        send_blocked_reason="report-mode=send requested but controller_kind=$controller_kind (blocked; use --report-submit keys --report-keys <...> if you accept risk)"
      fi
      ;;
    *)
      echo "[dispatch] invalid --report-mode: $REPORT_MODE (expected auto|draft|send)" >&2
      exit 2
      ;;
  esac
fi

if [[ -z "$effective_report_submit" ]]; then
  effective_report_submit="none"
fi

if [[ "$CLEAR_INPUT" != "on" && "$CLEAR_INPUT" != "off" ]]; then
  echo "[dispatch] invalid --clear-input: $CLEAR_INPUT (expected on|off)" >&2
  exit 2
fi

INTENT_SUMMARY=""

extract_file_create_intent_json() {
  local text="$1"
  python3 - "$text" <<'PY'
import json
import re
import sys

text = sys.argv[1]

def clean_content(s: str) -> str:
    s = s.strip()
    if (s.startswith('"') and s.endswith('"')) or (s.startswith("'") and s.endswith("'")):
        s = s[1:-1].strip()
    # Drop trailing full stop (Chinese) as punctuation; keep '.' because user may want it as part of content.
    s = re.sub(r'[。]\s*$', '', s)
    return s

def cut_after_clauses(s: str) -> str:
    # Heuristic: user often continues with meta-instructions after the desired content.
    clause_tokens = ["让它", "让其", "然后", "并且", "并 ", "并在", "完成后", "做完", "之后", "回传", "通知你", "并回传"]
    idxs = [s.find(t) for t in clause_tokens if s.find(t) != -1]
    if idxs:
        s = s[: min(idxs)]
    return s.strip()

patterns = [
    # Chinese common phrasing:
    re.compile(r'在\s*(?P<dir>/[^\s，。,]+)\s*下.*?(创建|新建).*?(文件).*?(叫|名为)\s*(?P<file>[\w.\-]+).*?(写入|写上|内容|文本).*?(叫|为)\s*(?P<content>[^。\n]+)', re.S),
    # Slightly looser: dir + filename + content in separate clauses
    re.compile(r'在\s*(?P<dir>/[^\s，。,]+)\s*下.*?(创建|新建).*?(文件).*?(叫|名为)\s*(?P<file>[\w.\-]+).*?(写入|写上|内容|文本).*?(?P<content>[^。\n]+)', re.S),
    # Current working directory phrasing (no explicit path)
    re.compile(r'(在\s*(你所处的位置|当前目录|当前路径|工作目录)\s*(中|下)?).*?(创建|新建).*?(文件).*?(叫|名为)\s*(?P<file>[\w.\-]+).*?(写入|写上|内容|文本).*?(叫|为)\s*(?P<content>[^。\n]+)', re.S),
    re.compile(r'(在\s*(你所处的位置|当前目录|当前路径|工作目录)\s*(中|下)?).*?(创建|新建).*?(文件).*?(叫|名为)\s*(?P<file>[\w.\-]+).*?(写入|写上|内容|文本).*?(?P<content>[^。\n]+)', re.S),
]

for rx in patterns:
    m = rx.search(text)
    if not m:
        continue
    d = m.groupdict().get('dir', None)
    if d is None:
        d = "__CWD__"
    else:
        d = d.strip()
    f = m.group('file').strip()
    c = cut_after_clauses(clean_content(m.group('content')))
    if d and f and c:
        print(json.dumps({"type": "file_create", "dir": d, "file": f, "content": c}, ensure_ascii=False))
        sys.exit(0)

sys.exit(1)
PY
}

maybe_normalize_task() {
  local text="$1"
  if [[ "$NORMALIZE" == "off" ]]; then
    TASK_NORMALIZED="$text"
    return 0
  fi

  local intent_json=""
  intent_json="$(extract_file_create_intent_json "$text" 2>/dev/null || true)"
  if [[ -z "$intent_json" ]]; then
    TASK_NORMALIZED="$text"
    return 0
  fi

  local dir file content
  dir="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["dir"])' <<<"$intent_json")"
  file="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["file"])' <<<"$intent_json")"
  content="$(python3 -c 'import json,sys; print(json.loads(sys.stdin.read())["content"])' <<<"$intent_json")"

  if [[ "$dir" == "__CWD__" ]]; then
    dir="."
  fi

  local path="${dir%/}/$file"
  local qdir qpath
  qdir="$(printf '%q' "$dir")"
  qpath="$(printf '%q' "$path")"

  INTENT_SUMMARY="Create file at ${path} with content: ${content}"

  local out=""
  out+=$'请把下面步骤当作“最终目标”，不要再解释“启动一个 codex”。你已经在 codex 里。\n'
  out+=$'只在 shell 执行命令（不要 sudo）；执行完做一次验证，然后按回传指令汇报结果。\n\n'
  out+=$'[命令]\n'
  out+="mkdir -p $qdir"$'\n'
  out+="cat > $qpath <<'EOF'"$'\n'
  out+="$content"$'\n'
  out+="EOF"$'\n'
  out+="ls -la $qdir $qpath 2>&1 || true"$'\n'
  out+="cat $qpath 2>&1 || true"$'\n'
  out+=$'\n[验证]\n'
  out+=$'如果上述任一步失败，也要继续执行回传（把错误写进去）。\n'
  TASK_NORMALIZED="$out"
}

preflight_fail_fast_if_needed() {
  local text="$1"
  if [[ "$PREFLIGHT" == "off" ]]; then
    return 0
  fi

  # Only do a narrow preflight for macOS + /home/*, since it is commonly not writable.
  if [[ "$(uname -s 2>/dev/null || true)" != "Darwin" ]]; then
    return 0
  fi
  if [[ "$text" != *"/home/"* ]]; then
    return 0
  fi

  if [[ -L /home ]] && [[ "$(readlink /home 2>/dev/null || true)" == "/System/Volumes/Data/home" ]]; then
    if [[ ! -w /System/Volumes/Data/home ]]; then
      local msg="$REPORT_PREFIX: from=$WORKER | result=fail | details=preflight: /home/* not writable on this macOS (Operation not supported); suggest=/tmp/<name> or $HOME"
      if [[ "$effective_report_submit" == "keys" && -n "$REPORT_KEYS" ]]; then
        bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$controller_target" --text "$msg" --submit "$effective_report_submit" --keys "$REPORT_KEYS" --clear-input "$CLEAR_INPUT" 2>/dev/null || true
      else
        bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$controller_target" --text "$msg" --submit "$effective_report_submit" --clear-input "$CLEAR_INPUT" 2>/dev/null || true
      fi
      echo "[dispatch] preflight fail-fast: /home/* not writable on macOS" >&2
      exit 0
    fi
  fi
}

TASK_NORMALIZED=""
maybe_normalize_task "$TASK"
preflight_fail_fast_if_needed "$TASK_NORMALIZED"

detect_high_risk_reason() {
  local text="$1"
  local reasons=()

  if [[ "$text" == *"sudo "* || "$text" == sudo* ]]; then
    reasons+=("contains sudo")
  fi
  if echo "$text" | grep -E -q '(^|[^[:alnum:]_])rm[[:space:]]+-rf[[:space:]]+/($|[[:space:]])'; then
    reasons+=("rm -rf /")
  fi
  if echo "$text" | grep -E -q '(^|[^[:alnum:]_])dd[[:space:]]+if='; then
    reasons+=("dd if=")
  fi
  if echo "$text" | grep -E -q 'mkfs\.|diskutil[[:space:]]+erase|diskutil[[:space:]]+apfs[[:space:]]+delete'; then
    reasons+=("disk/format command")
  fi
  if echo "$text" | grep -E -q '(^|[[:space:]])/(System|Library|usr|bin|sbin|etc)(/|[[:space:]]|$)'; then
    reasons+=("touches system path")
  fi

  if [[ "${#reasons[@]}" -eq 0 ]]; then
    return 1
  fi
  printf '%s' "$(IFS=', '; echo "${reasons[*]}")"
}

high_risk_reason="$(detect_high_risk_reason "$TASK_NORMALIZED" || true)"
if [[ -n "$high_risk_reason" && "$RISK" != "allow" && "$RISK" != "off" ]]; then
  msg="$REPORT_PREFIX: from=$WORKER | result=blocked | details=risk-gate: $high_risk_reason; action=re-run with --risk allow if you approve"
  if [[ "$effective_report_submit" == "keys" && -n "$REPORT_KEYS" ]]; then
    bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$controller_target" --text "$msg" --submit "$effective_report_submit" --keys "$REPORT_KEYS" --clear-input "$CLEAR_INPUT" 2>/dev/null || true
  else
    bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$controller_target" --text "$msg" --submit "$effective_report_submit" --clear-input "$CLEAR_INPUT" 2>/dev/null || true
  fi
  echo "[dispatch] risk gate: blocked ($high_risk_reason)" >&2
  exit 0
fi

if [[ -n "$send_blocked_reason" ]]; then
  msg="$REPORT_PREFIX: from=$WORKER | result=blocked | details=$send_blocked_reason"
  bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$controller_target" --text "$msg" --submit "none" 2>/dev/null || true
fi

prompt=$'[协议]\n'
prompt+=$'你是 worker（当前就是 Codex CLI）。只做用户任务，不要创建/操作 tmux，不要做无关探索。\n'
prompt+=$'注意：你不需要、也不应该“再启动一个 codex”。你已经在 codex 里。\n'
prompt+=$'不要阅读/检查本 skill 的源码（SKILL.md/scripts），除非完成任务所必需。\n\n'
prompt+=$'[结束条件]\n'
prompt+="完成后请运行：echo $DONE_MARKER"$'\n\n'
prompt+=$'[我的理解]\n'
if [[ -n "$INTENT_SUMMARY" ]]; then
  prompt+="$INTENT_SUMMARY"$'\n'
else
  prompt+=$'（未能可靠抽取结构化意图；按“用户任务”执行）\n'
fi
prompt+=$'\n'
prompt+=$'[回传]\n'
prompt+=$'完成后请执行回传命令：\n'
prompt+="\"$TMUXCTL\" report --to \"$controller_target\" --text \"$REPORT_PREFIX: from=$WORKER | result=<ok|fail> | details=<one-line>\" --submit \"$effective_report_submit\" --clear-input \"$CLEAR_INPUT\""
if [[ "$effective_report_submit" == "keys" && -n "$REPORT_KEYS" ]]; then
  prompt+=" --keys \"$REPORT_KEYS\""
fi
prompt+=$'\n\n[用户任务]\n'
prompt+="$TASK_NORMALIZED"

echo "[dispatch] controller=$controller_target ($controller_kind) worker=$WORKER socket=$SOCKET_MODE report_mode=$REPORT_MODE submit=$effective_report_submit"

bash "$SCRIPT_DIR/interactive_runner.sh" \
  --socket "$SOCKET_MODE" \
  --session "$WORKER" \
  --workdir "$WORKDIR" \
  --cmd "$CMDSTR" \
  --prompt "$prompt" \
  --wait-pattern "$DONE_MARKER" \
  --timeout "$TIMEOUT" \
  --report-to "$controller_target" \
  --report-submit "$effective_report_submit" \
  --report-keys "$REPORT_KEYS" \
  --prompt-template none \
  --expect-report-pattern "$REPORT_PREFIX:" \
  --expect-report-timeout 180
