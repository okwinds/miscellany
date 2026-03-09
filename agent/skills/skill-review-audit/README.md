# skill-review-audit

Use when a user asks to review, interpret, or audit an AI agent skill (SKILL.md plus bundled scripts/references/assets) for capabilities, triggering behavior, tool/command usage, safety & privacy risk, supply-chain provenance, quality gaps, and improvement recommendations; also use when validating a skill before installing or deploying it.

## What's included

- `SKILL.md`
- `scripts/` (optional)
- `references/` (optional)
- `assets/` (optional)

## Installation

> Installing a skill means your coding tool / agent runner can discover the `SKILL.md` inside it (typically via a `skills/` directory, or via a built-in “install from Git” feature).

### Option A: copy

From this repo root:

Set `SKILLS_DIR` to whatever skills folder your tool scans (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/skill-review-audit"
cp -R agent/skills/skill-review-audit "$SKILLS_DIR/skill-review-audit"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/skill-review-audit"
ln -s "$(pwd)/agent/skills/skill-review-audit" "$SKILLS_DIR/skill-review-audit"
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

When prompted, select `skill-review-audit` (repo path: `agent/skills/skill-review-audit`).

Verify / read back:

```bash
npx openskills list
npx openskills read skill-review-audit
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/skill-review-audit`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

Run the bundled (read-only) scanner to quickly inventory a skill directory:

```bash
bash ./scripts/scan_skill.sh /path/to/target-skill
```

Treat the output as sensitive (it may surface tokens/keys depending on the target); redact before sharing.
