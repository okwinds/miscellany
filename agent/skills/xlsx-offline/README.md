# xlsx-offline

Excel 表格离线读写与公式校验：创建/修改 xlsx，保持公式可复算，输出必须零公式错误；附带 LibreOffice 重算与错误扫描脚本（依赖安装可能需要网络）。

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
rm -rf "$SKILLS_DIR/xlsx-offline"
cp -R agent/skills/xlsx-offline "$SKILLS_DIR/xlsx-offline"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/xlsx-offline"
ln -s "$(pwd)/agent/skills/xlsx-offline" "$SKILLS_DIR/xlsx-offline"
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

When prompted, select `xlsx-offline` (repo path: `agent/skills/xlsx-offline`).

Verify / read back:

```bash
npx openskills list
npx openskills read xlsx-offline
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/xlsx-offline`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

This skill ships a formula recalculation + error scan script (requires `soffice` from LibreOffice on `PATH`). Run it from the installed skill directory:

```bash
cd /path/to/xlsx-offline
python3 ./recalc.py output.xlsx 30
```

Notes:

- Default behavior uses an **isolated LibreOffice profile** to avoid permanently writing macros into your real LibreOffice profile.
- To use your normal LibreOffice profile instead: `--no-isolated`
- To keep the temporary profile dir for debugging: `--keep-profile`
