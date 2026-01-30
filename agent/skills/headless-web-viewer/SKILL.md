---
name: headless-web-viewer
description: Render and view webpages using a headless browser (Playwright) to fetch JS-rendered HTML, extract visible text, and optionally save full-page screenshots. Use when a user asks to “无头浏览器打开/查看网页”, needs the rendered DOM instead of raw curl HTML, or wants a screenshot of a page.
---

# Headless Web Viewer

## Run

### Render + save artifacts

```bash
node agent/skills/headless-web-viewer/scripts/render_url_playwright.mjs '<URL>' \
  --out-html /tmp/page.html \
  --out-text /tmp/page.txt \
  --out-screenshot /tmp/page.png
```

### Print to stdout (pipe-friendly)

```bash
node agent/skills/headless-web-viewer/scripts/render_url_playwright.mjs '<URL>' --print text
```

## Dependencies

This skill requires Playwright in the environment where it runs.

### Option A (recommended for global use, no browser download)

Install Playwright Core and use system Chrome:

```bash
npm i -D playwright-core
```

Run with `--channel chrome`.

### Option B (bundled browsers)

```bash
npm i -D playwright
npx playwright install
```

Do not auto-install dependencies unless the user asks.

## Tips

- If a page hangs on `networkidle`, retry with `--wait-until domcontentloaded`.
- If a page blocks headless Chromium, try setting `--user-agent` to a realistic UA.
