# skill-creator-cc

Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, update or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.

## What's included

- `SKILL.md`
- `scripts/` (optional)
- `references/` (optional)
- `assets/` (optional)
- `agents/` (specialized subagent prompts used by the benchmark/review workflow)
- `eval-viewer/` (self-contained review UI generator for qualitative output review)

## Installation

> Installing a skill means your coding tool / agent runner can discover the `SKILL.md` inside it (typically via a `skills/` directory, or via a built-in “install from Git” feature).

### Option A: copy

From this repo root:

Set `SKILLS_DIR` to whatever skills folder your tool scans (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/skill-creator-cc"
cp -R agent/skills/skill-creator-cc "$SKILLS_DIR/skill-creator-cc"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/skill-creator-cc"
ln -s "$(pwd)/agent/skills/skill-creator-cc" "$SKILLS_DIR/skill-creator-cc"
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

When prompted, select `skill-creator-cc` (repo path: `agent/skills/skill-creator-cc`).

Verify / read back:

```bash
npx openskills list
npx openskills read skill-creator-cc
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/skill-creator-cc`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

The skill itself is driven by `SKILL.md`, but it also ships runnable helpers for evaluation and packaging workflows.

Validate the copied/published skill:

```bash
python3 ./scripts/quick_validate.py .
```

Package the skill as a `.skill` bundle:

```bash
python3 -m scripts.package_skill .
```

Generate a static review page from an eval workspace:

```bash
python3 ./eval-viewer/generate_review.py \
  /path/to/skill-workspace/iteration-1 \
  --skill-name skill-creator-cc \
  --static /tmp/skill-creator-cc-review.html
```
