# Headless Web Viewer

Render and view webpages using a headless browser (Playwright) to fetch JS-rendered HTML, extract visible text, and optionally save full-page screenshots.

## What’s included

- `SKILL.md`: skill definition + usage notes
- `scripts/render_url_playwright.mjs`: renderer CLI
- `package.json` / `package-lock.json`: Playwright dependency (not vendored)

## Install into Codex / Claude Code

> This folder is the “skill package”. Installing it simply means placing the whole directory (including `SKILL.md`) into your tool’s `skills/` directory, keeping the folder name unchanged.

### Option A: copy (recommended)

From this repo root (pick one: `~/.codex/skills` or `~/.claude/skills`):

```bash
SKILLS_DIR=~/.codex/skills   # or ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
cp -R agent/skills/headless-web-viewer "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### Option B: symlink (best for development)

```bash
SKILLS_DIR=~/.codex/skills   # or ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
ln -s "$(pwd)/agent/skills/headless-web-viewer" "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### After install

- Restart / open a new Codex or Claude Code session so it re-scans skills.
- Then just ask for it in natural language, e.g. “open this URL headlessly and extract visible text”.

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
