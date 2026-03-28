# codeflow-analyzer

Trace and document the complete call chain / data flow of any feature or process in a codebase. Useful for understanding how a feature works end-to-end, tracing call chains, analyzing code flow, mapping data flow across layers, and reverse-engineering processes.

## What's included

- `SKILL.md` — Core skill definition and workflow
- `scripts/` (optional) — Helper scripts if any
- `references/` (optional) — Reference materials
- `assets/` (optional) — Supporting assets

## Installation

> Installing a skill means your coding tool / agent runner can discover the `SKILL.md` inside it (typically via a `skills/` directory, or via a built-in "install from Git" feature).

### Option A: copy

From this repo root:

Set `SKILLS_DIR` to whatever skills folder your tool scans (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/codeflow-analyzer"
cp -R agent/skills/codeflow-analyzer "$SKILLS_DIR/codeflow-analyzer"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/codeflow-analyzer"
ln -s "$(pwd)/agent/skills/codeflow-analyzer" "$SKILLS_DIR/codeflow-analyzer"
```

### Option C: install from GitHub/Git via openskills

Prereqs for openskills:

- Requires Node.js (18+ recommended).
- No install needed if you use `npx openskills ...` (it will download and run).
- Optional global install: `npm i -g openskills` (or `pnpm add -g openskills`).

Install from a cloneable repo URL (do **not** use a GitHub `.../tree/...` subdirectory link):

```bash
npx openskills install https://github.com/okwinds/miscellany.git
```

When prompted, select `codeflow-analyzer` (repo path: `agent/skills/codeflow-analyzer`).

Verify / read back:

```bash
npx openskills list
npx openskills read codeflow-analyzer
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/codeflow-analyzer`.

### After install

Many tools require a restart / new session to re-scan skills.
