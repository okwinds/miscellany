#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMUXCTL="$SCRIPT_DIR/tmuxctl.sh"

SOCKET_MODE="isolated"
SESSION_CTL="echo-ctl"
SESSION_WRK="echo-wrk"
MARK="__CODEX_TMUX_ECHO_OK__"

# Use isolated socket (so test doesn't touch system tmux)
export CODEX_TMUX_ECHO_SOCKET_DIR="${TMPDIR:-/tmp}/codex-tmux-echo-selftest"

echo "[selftest] starting controller"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --session "$SESSION_CTL" new --dir "$(pwd)" --cmd "bash --noprofile --norc" --kill-existing

echo "[selftest] starting worker"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --session "$SESSION_WRK" new --dir "$(pwd)" --cmd "bash --noprofile --norc" --kill-existing

echo "[selftest] worker reporting to controller"
bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$SESSION_CTL" --text "$MARK"

echo "[selftest] waiting mark in controller pane"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION_CTL" wait --pattern "$MARK" --timeout 10 --interval 0.2 --lines 200

echo "[selftest] draft vs send semantics on bash controller"
DR="__CODEX_TMUX_ECHO_DRAFT__"

echo "[selftest] clear controller input line"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION_CTL" send --text "" --keys "C-u"

echo "[selftest] make controller print CTL_READY"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION_CTL" send --text "echo CTL_READY" --keys "Enter"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION_CTL" wait --pattern "^CTL_READY$" --timeout 5 --interval 0.2 --lines 200

echo "[selftest] report-submit none: inject only, should NOT execute"
bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$SESSION_CTL" --text "echo $DR" --submit none
sleep 0.4
if bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION_CTL" capture --lines 220 | grep -x -F "$DR" >/dev/null 2>&1; then
  echo "[selftest] FAIL: draft unexpectedly executed" >&2
  exit 1
fi

echo "[selftest] clear controller input line"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION_CTL" send --text "" --keys "C-u"

echo "[selftest] report-submit keys+Enter: should execute"
bash "$TMUXCTL" --socket "$SOCKET_MODE" report --to "$SESSION_CTL" --text "echo $DR" --submit keys --keys "Enter"
bash "$TMUXCTL" --socket "$SOCKET_MODE" --target "$SESSION_CTL" wait --pattern "^$DR$" --timeout 5 --interval 0.2 --lines 260

echo "[selftest] PASS"

# cleanup sessions only
bash "$TMUXCTL" --socket "$SOCKET_MODE" --session "$SESSION_WRK" kill || true
bash "$TMUXCTL" --socket "$SOCKET_MODE" --session "$SESSION_CTL" kill || true
