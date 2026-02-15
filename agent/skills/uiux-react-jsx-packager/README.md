# uiux-react-jsx-packager

Package an existing React UI/UX demo into a single self-contained .jsx file with default-export root component, zero third-party runtime dependencies (no react-router/lucide/echarts/etc.), in-file styles (style tag or inline style objects), inline SVG icons, embedded or placeholder images, and state-based navigation. Use when asked to “合并为单文件 JSX/单文件打包/one-file React/零外部依赖/内联 CSS/替换图标库/用 state 做路由/把 demo 打包成独立 JSX 文件”.

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
rm -rf "$SKILLS_DIR/uiux-react-jsx-packager"
cp -R agent/skills/uiux-react-jsx-packager "$SKILLS_DIR/uiux-react-jsx-packager"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/uiux-react-jsx-packager"
ln -s "$(pwd)/agent/skills/uiux-react-jsx-packager" "$SKILLS_DIR/uiux-react-jsx-packager"
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

When prompted, select `uiux-react-jsx-packager` (repo path: `agent/skills/uiux-react-jsx-packager`).

Verify / read back:

```bash
npx openskills list
npx openskills read uiux-react-jsx-packager
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/uiux-react-jsx-packager`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

This skill is primarily an instruction set in `SKILL.md`, plus a couple of optional helper scripts.

### Verify a merged `.jsx` file

Runs a heuristic gate to catch common packaging violations (non-React imports, `require()`, dynamic `import()`, missing default export, asset imports, etc.):

```bash
python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py /path/to/Merged.jsx
```

Stricter mode (treat warnings as failures):

```bash
python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py --strict /path/to/Merged.jsx
```

### Runtime smoke preview (recommended)

Spin up an isolated Vite+React dev server under `/tmp` to catch “white screen” runtime errors early:

```bash
NO_OPEN=1 PORT=5188 bash agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh /path/to/Merged.jsx
```

If the terminal shows `Port 5188 is in use, trying another one...`, always open the URL in the `Local:` line.
