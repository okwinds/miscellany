# prd-to-uiux-rd-spec

Turn a product PRD into a replica-ready UI/UX engineering spec bundle (directory skeleton, shared foundations, page/component contracts, coverage mapping, index, and worklog).

## What’s included

- `SKILL.md` — the workflow and output contract
- `references/` — templates and checklists
- `examples/` — a tiny example
- `tests/` — eval prompts for self-checking
- `CHANGELOG.md`

## Installation

> Installing a skill means making sure your coding tool / agent runner can discover the `SKILL.md` in this directory (typically by placing it under a `skills/` folder, or by using the tool’s “install from Git” feature).

### Option A: Copy install

Run from the repo root:

Set `SKILLS_DIR` to a directory your tool scans for skills (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/prd-to-uiux-rd-spec"
cp -R agent/skills/prd-to-uiux-rd-spec "$SKILLS_DIR/prd-to-uiux-rd-spec"
```

### Option B: Symlink install

Run from the repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/prd-to-uiux-rd-spec"
ln -s "$(pwd)/agent/skills/prd-to-uiux-rd-spec" "$SKILLS_DIR/prd-to-uiux-rd-spec"
```

### Option C: Install via openskills (GitHub/Git)

Prepare openskills:

- Requires Node.js (18+ recommended).
- No install needed: use `npx openskills ...`.
- Optional global install: `npm i -g openskills` (or `pnpm add -g openskills`).

Install from a cloneable repo URL (avoid GitHub `.../tree/...` links):

```bash
npx openskills install https://github.com/okwinds/miscellany
```

Select `prd-to-uiux-rd-spec` (in-repo path: `agent/skills/prd-to-uiux-rd-spec`).

Verify/read:

```bash
npx openskills list
npx openskills read prd-to-uiux-rd-spec
```

### Option D: Direct Git URL install (tool-dependent)

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repository and locate `agent/skills/prd-to-uiux-rd-spec`.

## After install

Many tools require a restart/new session to rescan skills.

## Usage

- Open `./SKILL.md` and follow the “output contract” + step-by-step workflow.
- If you use OpenSkills, load it with `npx openskills read prd-to-uiux-rd-spec`.
