# prd-to-engineering-spec

"Transform PRD (Product Requirements Document) into actionable engineering specifications. Creates detailed technical specs that developers can implement step-by-step without ambiguity. Covers data modeling, API design, business logic, security architecture, deployment, and agent system design. Use when: converting product requirements to technical specs, validating PRD completeness, planning technical implementation, creating task breakdowns, or defining test specifications. Triggers: 'PRD to spec', 'convert requirements', 'technical spec from PRD', 'engineering doc from requirements', 'validate PRD'."

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
rm -rf "$SKILLS_DIR/prd-to-engineering-spec"
cp -R agent/skills/prd-to-engineering-spec "$SKILLS_DIR/prd-to-engineering-spec"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/prd-to-engineering-spec"
ln -s "$(pwd)/agent/skills/prd-to-engineering-spec" "$SKILLS_DIR/prd-to-engineering-spec"
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

When prompted, select `prd-to-engineering-spec` (repo path: `agent/skills/prd-to-engineering-spec`).

Verify / read back:

```bash
npx openskills list
npx openskills read prd-to-engineering-spec
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/prd-to-engineering-spec`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

From this repo root, generate the folder skeleton (default output: `./engineering-spec`):

```bash
bash ./scripts/generate_spec_skeleton.sh
```

Validate an in-progress spec:

```bash
bash ./scripts/validate_spec.sh engineering-spec
```
