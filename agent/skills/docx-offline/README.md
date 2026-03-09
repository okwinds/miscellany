# docx-offline

DOCX 文档离线读写：提取/分析、OOXML 解包编辑回包、批注与修订（tracked changes/redlining）。适用于合同/制度/论文等需要保留格式与修订痕迹的场景（依赖安装可能需要网络）。

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
rm -rf "$SKILLS_DIR/docx-offline"
cp -R agent/skills/docx-offline "$SKILLS_DIR/docx-offline"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/docx-offline"
ln -s "$(pwd)/agent/skills/docx-offline" "$SKILLS_DIR/docx-offline"
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

When prompted, select `docx-offline` (repo path: `agent/skills/docx-offline`).

Verify / read back:

```bash
npx openskills list
npx openskills read docx-offline
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/docx-offline`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

Run these commands from the installed skill directory:

```bash
cd /path/to/docx-offline

# Text extraction (preserve tracked changes)
pandoc --track-changes=all path-to-file.docx -o out.md

# OOXML workflow
python3 ./ooxml/scripts/unpack.py path-to-file.docx unpacked-docx
python3 ./ooxml/scripts/pack.py unpacked-docx out.docx
```

For tracked changes / comments workflows, follow `ooxml.md`.
