# bf-skillsruntime-dev

"用 Skills Runtime SDK（Python）开发复杂业务 agent、skills、workflow 的编码智能体指南。用户一旦提到 skills_runtime、Skills Runtime SDK、overlay YAML、FakeChatBackend、AgentBuilder、Coordinator、skill_ref_read、skill_exec、approvals/sandbox、WAL/replay、exec sessions、spawn_agent/send_input/wait、waiting_human/resume、examples/apps/workflows，或要在本仓上落地复杂业务开发/修复/回归，就应优先使用本技能。不要用于与本框架无关的通用编码或纯文案任务。"

## What's included

- `SKILL.md`
- `scripts/`
- `references/`

## Installation

> Installing a skill means your coding tool / agent runner can discover the `SKILL.md` inside it (typically via a `skills/` directory, or via a built-in “install from Git” feature).

### Option A: copy

From this repo root:

Set `SKILLS_DIR` to whatever skills folder your tool scans (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-skillsruntime-dev"
cp -R agent/skills/bf-skillsruntime-dev "$SKILLS_DIR/bf-skillsruntime-dev"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-skillsruntime-dev"
ln -s "$(pwd)/agent/skills/bf-skillsruntime-dev" "$SKILLS_DIR/bf-skillsruntime-dev"
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

When prompted, select `bf-skillsruntime-dev` (repo path: `agent/skills/bf-skillsruntime-dev`).

Verify / read back:

```bash
npx openskills list
npx openskills read bf-skillsruntime-dev
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/bf-skillsruntime-dev`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

If you want to scaffold a new Skills Runtime SDK business app, run the bundled script from the skill directory:

```bash
python3 ./scripts/scaffold_app.py my-app --out /tmp/my-app --with-skills
```

Preview only:

```bash
python3 ./scripts/scaffold_app.py my-app --out /tmp/my-app --with-skills --dry-run
```
