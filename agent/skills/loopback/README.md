# loopback

"Loopback 迭代开发循环 - 基于 Ralph Loop 思想实现的 Codex 版本。用于创建自引用的迭代开发循环，让 AI 在多次迭代中逐步改进代码，直到任务完成。Use when: (1) 需要多次迭代改进的任务, (2) 复杂功能需要分步实现, (3) 需要自我修正的代码生成, (4) 迭代优化已有代码."

## Provenance

This skill is a Codex-oriented adaptation inspired by the **Ralph Loop** workflow from **Claude Code** (often referred to as `ralphloop` / `ralph-loop` in configs and community docs). It is **not** an official Claude Code component; it’s a practical port that preserves the “same prompt, many iterations” idea in an environment with different tooling constraints.

## How it differs from Ralph Loop (and why)

Ralph Loop runs *inside* Claude Code and can rely on runtime hooks (e.g., a stop/exit hook) to drive the next iteration. Codex CLI doesn’t expose an equivalent “stop hook” mechanism, so Loopback implements the loop externally using a **state file + driver**:

- **State file**: `.codex/loopback.local.md` stores the exact prompt and the stop contract.
- **Driver**: `scripts/codex-loopback-wrapper.sh` repeatedly invokes `codex exec` and logs each run to `.codex/loopback.outputs/iteration-N.log`.
- **Completion detection**: matches a structured tag (`<promise>...</promise>`) in logs, rather than relying on an unstructured “DONE” string.

These constraints create real-world behavioral differences you should account for:

- **Stop contract is mandatory by default** (non-interactive safety): provide `--completion-promise` and/or `--max-iterations`, or explicitly opt into risk with `--allow-infinite`.
- **“Same session” is an implementation detail**: Loopback can try to reuse a Codex session via `codex exec --json` event parsing. If the Codex CLI JSON schema changes, session reuse/resume can break; the loop still works, but may fall back to fresh sessions depending on your runner.
- **Context comes from files, not chat memory**: iteration-to-iteration continuity depends on the working directory, your repo state, and what changed on disk.
- **Cancel is file-based**: cancelling means deleting `.codex/loopback.local.md` (or using `/cancel-loop` if your runner supports slash commands).

## Prereqs

- `codex` CLI available in `PATH`.
- `bash` + coreutils (macOS bash 3.2 supported).
- Python 3 with PyYAML available (`python3 -c 'import yaml'` should succeed; otherwise install `pyyaml`).

## What's included

- `SKILL.md`
- `commands/` (slash-command definitions for runners that support them)
- `scripts/` (driver + helpers)

Runtime artifacts created in your project directory:

- `.codex/loopback.local.md` (state file)
- `.codex/loopback.outputs/iteration-N.log` (per-iteration logs)

## Installation

> Installing a skill means your coding tool / agent runner can discover the `SKILL.md` inside it (typically via a `skills/` directory, or via a built-in “install from Git” feature).

### Option A: copy

From this repo root:

Set `SKILLS_DIR` to whatever skills folder your tool scans (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/loopback"
cp -R agent/skills/loopback "$SKILLS_DIR/loopback"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/loopback"
ln -s "$(pwd)/agent/skills/loopback" "$SKILLS_DIR/loopback"
```

### Option C: install from GitHub/Git via openskills

Prereqs for openskills:

- Requires Node.js (18+ recommended).
- No install needed if you use `npx openskills ...` (it will download and run).
- Optional global install: `npm i -g openskills` (or `pnpm add -g openskills`).

Install from a cloneable repo URL (do **not** use a GitHub `.../tree/...` subdirectory link):

```bash
npx openskills install https://github.com/okwinds/miscellany
```

When prompted, select `loopback` (repo path: `agent/skills/loopback`).

Verify / read back:

```bash
npx openskills list
npx openskills read loopback
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/loopback`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

If your runner supports slash commands from `commands/`:

```text
/loopback --guide
/loopback "Fix X. When done, output <promise>DONE</promise>." --completion-promise "DONE" --max-iterations 10
/cancel-loop
```

If your runner does **not** support slash commands, you can run the scripts directly from your project root:

```bash
bash ./scripts/setup-loopback.sh \
  "Fix X. When done, output <promise>DONE</promise>." \
  --completion-promise "DONE" \
  --max-iterations 10
```

## Safety notes

- Prefer a **verifiable completion contract** (tests, commands, observable criteria). Only output the `<promise>` tag when the contract is fully true.
- Avoid enabling dangerous Codex flags globally (e.g. bypassing approvals/sandbox) unless you understand the consequences in your environment.
