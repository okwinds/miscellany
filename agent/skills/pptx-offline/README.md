# pptx-offline

PPTX 文档离线读写：解析/替换/重排/缩略图、OOXML 解包编辑回包，以及 html2pptx（HTML→PPT）工作流。适用于生成与维护演示文稿（依赖安装可能需要网络）。

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
rm -rf "$SKILLS_DIR/pptx-offline"
cp -R agent/skills/pptx-offline "$SKILLS_DIR/pptx-offline"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/pptx-offline"
ln -s "$(pwd)/agent/skills/pptx-offline" "$SKILLS_DIR/pptx-offline"
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

When prompted, select `pptx-offline` (repo path: `agent/skills/pptx-offline`).

Verify / read back:

```bash
npx openskills list
npx openskills read pptx-offline
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/pptx-offline`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

Run these commands from the installed skill directory:

```bash
cd /path/to/pptx-offline

# Text extraction to markdown
python -m markitdown path-to-file.pptx

# OOXML workflow
python3 ./ooxml/scripts/unpack.py path-to-file.pptx unpacked-pptx
python3 ./ooxml/scripts/pack.py unpacked-pptx out.pptx
```

### HTML → PPT (html2pptx)

Install Node deps locally (recommended):

```bash
cd /path/to/pptx-offline
npm i
```

Then convert a single HTML slide:

```bash
node ./scripts/html2pptx-local.cjs slide.html out.pptx
```
