# Headless Web Viewer

Render and view webpages using a headless browser (Playwright) to fetch JS-rendered HTML, extract visible text, and optionally save full-page screenshots.

## What’s included

- `SKILL.md`: skill definition + usage notes
- `scripts/render_url_playwright.mjs`: renderer CLI
- `package.json` / `package-lock.json`: Playwright dependency (not vendored)

## Installation

> This folder is the “skill package”. Installing it means your coding tool/agent runner can discover the `SKILL.md` inside it (commonly by placing the directory into a `skills/` folder, or by using the tool’s “install from Git” feature).

### Option A: copy

From this repo root, set `SKILLS_DIR` to whatever skills folder your tool scans (e.g. `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
cp -R agent/skills/headless-web-viewer "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### Option B: symlink

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
ln -s "$(pwd)/agent/skills/headless-web-viewer" "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### Option C: install from GitHub/Git via openskills

Prereqs for openskills:

- Requires Node.js (18+ recommended).
- No install needed if you use `npx openskills ...` (it will download and run).
- Optional global install: `npm i -g openskills` (or `pnpm add -g openskills`).

Use `openskills install` with this repo’s GitHub URL (or any Git URL), then select which skill(s) to install:

```bash
npx openskills install <git-url>
```

Example (this repo; note: use a cloneable **repo URL**, not a GitHub `.../tree/...` subdirectory link):

```bash
npx openskills install https://github.com/okwinds/miscellany
```

When prompted, select `headless-web-viewer` (repo path: `agent/skills/headless-web-viewer`).

Common options:
- `-g`: install globally
- `-u`: install into `.agent/skills/` (portable across tools/projects)
- `-y`: skip prompts, install all detected skills

Verify / read back:

```bash
npx openskills list
npx openskills read headless-web-viewer
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/headless-web-viewer`. If it doesn’t, use copy/symlink or `openskills install`.

### After install

Restart / open a new session so your tool re-scans skills, then ask in natural language (e.g. “open this URL headlessly and extract visible text”).

## Usage

From the repo root:

```bash
node agent/skills/headless-web-viewer/scripts/render_url_playwright.mjs 'https://example.com' \
  --out-html /tmp/page.html \
  --out-text /tmp/page.txt \
  --out-screenshot /tmp/page.png
```

Pipe-friendly text output:

```bash
node agent/skills/headless-web-viewer/scripts/render_url_playwright.mjs 'https://example.com' --print text
```

## Dependencies

This skill needs Playwright available at runtime.

- Recommended (no browser download): install `playwright-core` and use system Chrome/Edge via `--channel chrome|msedge`
- Alternative (bundled browsers): install `playwright` and run `npx playwright install`

Install in this skill directory:

```bash
cd agent/skills/headless-web-viewer
npm ci
```

## Tips

- If a page hangs on `networkidle`, retry with `--wait-until domcontentloaded`.
- If a page blocks headless Chromium, try `--user-agent` and/or `--channel chrome`.
