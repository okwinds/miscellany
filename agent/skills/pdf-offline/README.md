# pdf-offline

PDF 文档离线读写与表单处理：提取文本/表格、合并拆分、生成 PDF、填写表单。适用于“本地处理/读取/生成 PDF 文件”（依赖安装可能需要网络）。

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
rm -rf "$SKILLS_DIR/pdf-offline"
cp -R agent/skills/pdf-offline "$SKILLS_DIR/pdf-offline"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/pdf-offline"
ln -s "$(pwd)/agent/skills/pdf-offline" "$SKILLS_DIR/pdf-offline"
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

When prompted, select `pdf-offline` (repo path: `agent/skills/pdf-offline`).

Verify / read back:

```bash
npx openskills list
npx openskills read pdf-offline
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/pdf-offline`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

Run bundled helpers from inside the installed skill directory:

```bash
cd /path/to/pdf-offline

# (Optional) install Python deps for the bundled CLI helper
bash ./install.sh

# Read PDF → JSON
python3 ./doc_utils.py read path/to/file.pdf

# Merge PDFs
python3 ./doc_utils.py merge merged.pdf a.pdf b.pdf
```

For form-specific workflows (bounding boxes, field extraction, etc.), see `FORMS.md` and scripts under `./scripts/`.
