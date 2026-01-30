# Headless Web Viewer

Render and view webpages using a headless browser (Playwright) to fetch JS-rendered HTML, extract visible text, and optionally save full-page screenshots.

## What’s included

- `SKILL.md`: skill definition + usage notes
- `scripts/render_url_playwright.mjs`: renderer CLI
- `package.json` / `package-lock.json`: Playwright dependency (not vendored)

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

