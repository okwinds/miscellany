# prd-writing-guide

"Write complete, unambiguous PRDs that development teams can implement without guesswork. Includes requirement discovery framework, structured documentation methodology, completeness checklists, and common pitfall avoidance. Use when: writing new PRDs, reviewing PRD drafts, validating requirement completeness, preparing for engineering handoff. Triggers: 'write PRD', '写PRD', '产品需求文档', '需求文档', '需求规格', '需求评审', '完善需求', 'create requirements doc', 'product requirements', 'feature spec', 'requirements document'. Anti-triggers: 'technical design doc', 'architecture design', 'implementation plan', 'API design', '架构设计', '技术方案', '实现方案', '接口设计'."

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
rm -rf "$SKILLS_DIR/prd-writing-guide"
cp -R agent/skills/prd-writing-guide "$SKILLS_DIR/prd-writing-guide"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/prd-writing-guide"
ln -s "$(pwd)/agent/skills/prd-writing-guide" "$SKILLS_DIR/prd-writing-guide"
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

When prompted, select `prd-writing-guide` (repo path: `agent/skills/prd-writing-guide`).

Verify / read back:

```bash
npx openskills list
npx openskills read prd-writing-guide
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/prd-writing-guide`.

## Usage

### Use the included skeleton generator (optional)

From this repo root (or from wherever you installed the skill):

```bash
bash ./scripts/generate_prd_skeleton.sh ./docs/prd "User Dashboard Redesign"
```

Then fill in the generated Markdown files and validate completeness using the checklists in `./references/`.

### After install

Many tools require a restart / new session to re-scan skills.
