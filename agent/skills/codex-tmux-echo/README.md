# codex-tmux-echo

Drive interactive CLIs via tmux reliably: create sessions, send keys, wait for output, and report back to a controller pane.

This skill does **not** assume any `--yolo`/`--full-auto` flags; pass your desired command string via `--cmd`.

## ⚠️ Safety Notes (Read First)

This skill uses `tmux send-keys` to type into panes. If the controller/target is wrong, it can type (and potentially execute) commands in the wrong place.

- Prefer the default `--report-mode auto` (Codex controller => auto-send; otherwise => draft-only injection).
- Avoid `--report-submit keys` with `Enter` unless you explicitly pin `--scheduler-target` and understand the target pane.
- Don’t display secrets in controller panes; the tool may `capture-pane` to detect readiness/progress.

## Contents

- `SKILL.md`
- `scripts/`

## Install

Installation is tool-agnostic: “installed” just means your agent runner can discover the `SKILL.md` directory.

### Option A: Copy (recommended)

```bash
SKILLS_DIR=~/.claude/skills
mkdir -p "$SKILLS_DIR"
cp -R "$(pwd)/agent/skills/codex-tmux-echo" "$SKILLS_DIR/codex-tmux-echo"
```

### Option B: Symlink (dev-friendly)

```bash
SKILLS_DIR=~/.claude/skills
mkdir -p "$SKILLS_DIR"
ln -s "$(pwd)/agent/skills/codex-tmux-echo" "$SKILLS_DIR/codex-tmux-echo"
```

### Option C: OpenSkills (from Git)

```bash
# Runs without installation (Node.js 18+ recommended)
npx openskills install https://github.com/okwinds/miscellany --global
```

Then select the skill by name `codex-tmux-echo` (in-repo path: `agent/skills/codex-tmux-echo`).

After install, restart your agent session so it re-scans skills.

## Usage

Offline self-test:

```bash
bash scripts/selftest.sh
```

Natural-language dispatch (recommended when scheduler is always on system tmux):

```bash
bash scripts/start_scheduler.sh --socket system --session scheduler --workdir /Users/okwinds/Files/工作/opensource
tmux attach -t scheduler

# In the scheduler pane:
bash scripts/codex-tmux-echo 'hello，你好呀'
```

Backchannel modes:

```bash
# Default: auto (Codex controller => auto-send; otherwise => draft-only)
bash scripts/codex-tmux-echo 'summarize this repo'

# Draft-only injection (no auto-submit)
bash scripts/codex-tmux-echo --report-mode draft 'report status only'

# Force send (only works when controller is detected as Codex)
bash scripts/codex-tmux-echo --report-mode send 'send result as a message'
```

Run a command in tmux and wait for a pattern:

```bash
bash scripts/interactive_runner.sh --session demo --workdir "$(pwd)" --cmd "bash --noprofile --norc" \
  --prompt "echo READY" --wait-pattern "READY"
```
