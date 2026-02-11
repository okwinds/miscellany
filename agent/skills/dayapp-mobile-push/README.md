# dayapp-mobile-push

Send a critical mobile push through Day.app (Bark) with one GET request. Use when a task finishes, fails, is blocked, or needs immediate alerting, and you should summarize task name and summary from current task context before sending.

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
rm -rf "$SKILLS_DIR/dayapp-mobile-push"
cp -R agent/skills/dayapp-mobile-push "$SKILLS_DIR/dayapp-mobile-push"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/dayapp-mobile-push"
ln -s "$(pwd)/agent/skills/dayapp-mobile-push" "$SKILLS_DIR/dayapp-mobile-push"
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

When prompted, select `dayapp-mobile-push` (repo path: `agent/skills/dayapp-mobile-push`).

Verify / read back:

```bash
npx openskills list
npx openskills read dayapp-mobile-push
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/dayapp-mobile-push`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

Send one push notification:

```bash
python3 scripts/send_dayapp_push.py --task-name "BuildDone" --task-summary "CLI build and tests passed"
```

Preview the request URL without sending:

```bash
python3 scripts/send_dayapp_push.py --task-name "DeployBlocked" --task-summary "Release blocked by policy" --dry-run
```
