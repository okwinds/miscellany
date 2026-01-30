#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import process from "node:process";

function usage() {
  console.error(`Usage:
  render_url_playwright.mjs <url> [options]

Options:
  --out-html <path>        Save rendered HTML to file
  --out-text <path>        Save page textContent to file
  --out-screenshot <path>  Save full-page screenshot (.png recommended)
  --channel <name>         chromium|chrome|msedge (default: chromium)
  --wait-until <event>     domcontentloaded|load|networkidle (default: networkidle)
  --timeout <ms>           Navigation timeout in ms (default: 60000)
  --user-agent <ua>        Override user agent
  --viewport <WxH>         e.g. 1280x720 (default: 1280x720)
  --print html|text|none    Print to stdout (default: none)

Notes:
  - Requires Node Playwright (npm i -D playwright) and a browser installed (npx playwright install).
`);
}

function parseViewport(s) {
  const m = /^(\d+)x(\d+)$/.exec(s || "");
  if (!m) return null;
  return { width: Number(m[1]), height: Number(m[2]) };
}

function ensureParentDir(filePath) {
  const dir = path.dirname(path.resolve(filePath));
  fs.mkdirSync(dir, { recursive: true });
}

function parseArgs(argv) {
  const out = {
    url: null,
    outHtml: null,
    outText: null,
    outScreenshot: null,
    channel: "chromium",
    waitUntil: "networkidle",
    timeout: 60_000,
    userAgent: null,
    viewport: { width: 1280, height: 720 },
    print: "none",
  };

  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--out-html") out.outHtml = argv[++i];
    else if (a === "--out-text") out.outText = argv[++i];
    else if (a === "--out-screenshot") out.outScreenshot = argv[++i];
    else if (a === "--channel") out.channel = argv[++i];
    else if (a === "--wait-until") out.waitUntil = argv[++i];
    else if (a === "--timeout") out.timeout = Number(argv[++i]);
    else if (a === "--user-agent") out.userAgent = argv[++i];
    else if (a === "--viewport") {
      const v = parseViewport(argv[++i]);
      if (!v) return null;
      out.viewport = v;
    } else if (a === "--print") out.print = argv[++i];
    else if (a.startsWith("-")) return null;
    else positional.push(a);
  }

  out.url = positional[0] || null;
  if (!out.url) return null;
  if (!["domcontentloaded", "load", "networkidle"].includes(out.waitUntil)) return null;
  if (!Number.isFinite(out.timeout) || out.timeout <= 0) return null;
  if (!["html", "text", "none"].includes(out.print)) return null;
  if (!["chromium", "chrome", "msedge"].includes(out.channel)) return null;

  return out;
}

async function loadPlaywright() {
  try {
    return await import("playwright");
  } catch {
    try {
      return await import("playwright-core");
    } catch {
      console.error(
        "Playwright is not installed. Install one of:\n" +
          "  npm i -D playwright && npx playwright install   # bundled browsers\n" +
          "or\n" +
          "  npm i -D playwright-core                        # use system Chrome/Edge via --channel\n"
      );
      process.exit(3);
    }
  }
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (!args) {
    usage();
    process.exit(2);
  }

  const pw = await loadPlaywright();

  const browser =
    args.channel === "chromium"
      ? await pw.chromium.launch({ headless: true })
      : await pw.chromium.launch({ headless: true, channel: args.channel });
  try {
    const context = await browser.newContext({
      userAgent: args.userAgent || undefined,
      viewport: args.viewport,
    });
    const page = await context.newPage();
    await page.goto(args.url, { waitUntil: args.waitUntil, timeout: args.timeout });

    const html = await page.content();
    const text = await page.evaluate(() => document.body?.innerText || "");

    if (args.outHtml) {
      ensureParentDir(args.outHtml);
      fs.writeFileSync(args.outHtml, html, "utf8");
    }
    if (args.outText) {
      ensureParentDir(args.outText);
      fs.writeFileSync(args.outText, text, "utf8");
    }
    if (args.outScreenshot) {
      ensureParentDir(args.outScreenshot);
      await page.screenshot({ path: args.outScreenshot, fullPage: true });
    }

    if (args.print === "html") process.stdout.write(html);
    else if (args.print === "text") process.stdout.write(text);
  } finally {
    await browser.close();
  }
}

main().catch((e) => {
  console.error(e?.stack || String(e));
  process.exit(1);
});
