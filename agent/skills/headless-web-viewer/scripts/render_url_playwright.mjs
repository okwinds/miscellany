#!/usr/bin/env node
import crypto from "node:crypto";
import fs from "node:fs";
import https from "node:https";
import os from "node:os";
import path from "node:path";
import process from "node:process";

function usage() {
  console.error(`Usage:
  render_url_playwright.mjs <url> [options]

Options:
  --out-html <path>        Save rendered HTML to file
  --out-text <path>        Save page textContent to file
  --out-screenshot <path>  Save full-page screenshot (.png recommended)
  --out-meta <path>        Save run metadata (UA/viewport/locale/timezone) as JSON
  --channel <name>         chromium|chrome|msedge (default: chromium)
  --wait-until <event>     domcontentloaded|load|networkidle (default: networkidle)
  --timeout <ms>           Navigation timeout in ms (default: 60000)
  --user-agent <ua>        Override user agent
  --viewport <WxH>         e.g. 1280x720 (default: realistic random)
  --seed <value>           Seed randomness (number or string) for reproducible runs
  --ipinfo on|off          Fetch https://ipinfo.io once and use it to pick locale/timezone/UA (default: on)
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

function fnv1a32(input) {
  const s = String(input);
  let h = 0x811c9dc5;
  for (let i = 0; i < s.length; i++) {
    h ^= s.charCodeAt(i);
    h = Math.imul(h, 0x01000193);
  }
  return h >>> 0;
}

function seedToUint32(seed) {
  if (seed === null || seed === undefined) {
    return crypto.randomBytes(4).readUInt32LE(0);
  }
  const asNumber = Number(seed);
  if (Number.isFinite(asNumber)) return (asNumber >>> 0) || 1;
  return fnv1a32(seed) || 1;
}

function createRng(seed) {
  let t = (seed >>> 0) || 1;
  function next() {
    t += 0x6d2b79f5;
    let x = t;
    x = Math.imul(x ^ (x >>> 15), x | 1);
    x ^= x + Math.imul(x ^ (x >>> 7), x | 61);
    return ((x ^ (x >>> 14)) >>> 0) / 4294967296;
  }

  return {
    float: next,
    int(min, max) {
      const lo = Math.ceil(min);
      const hi = Math.floor(max);
      if (hi < lo) throw new Error(`Invalid rng.int range: ${min}-${max}`);
      return lo + Math.floor(next() * (hi - lo + 1));
    },
    pick(arr) {
      if (!Array.isArray(arr) || arr.length === 0) throw new Error("rng.pick on empty array");
      return arr[Math.floor(next() * arr.length)];
    },
    bool(p = 0.5) {
      return next() < p;
    },
  };
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
    outMeta: null,
    channel: "chromium",
    waitUntil: "networkidle",
    timeout: 60_000,
    userAgent: null,
    viewport: null,
    seed: null,
    ipinfo: "on",
    print: "none",
  };

  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === "--out-html") out.outHtml = argv[++i];
    else if (a === "--out-text") out.outText = argv[++i];
    else if (a === "--out-screenshot") out.outScreenshot = argv[++i];
    else if (a === "--out-meta") out.outMeta = argv[++i];
    else if (a === "--channel") out.channel = argv[++i];
    else if (a === "--wait-until") out.waitUntil = argv[++i];
    else if (a === "--timeout") out.timeout = Number(argv[++i]);
    else if (a === "--user-agent") out.userAgent = argv[++i];
    else if (a === "--seed") out.seed = argv[++i];
    else if (a === "--ipinfo") out.ipinfo = argv[++i];
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
  if (!["on", "off"].includes(out.ipinfo)) return null;

  return out;
}

const DEFAULT_UA_TEMPLATES = [
  // Desktop Chrome-style UAs (no "HeadlessChrome"). Version filled from browser.version().
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{CHROME_VERSION} Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{CHROME_VERSION} Safari/537.36",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/{CHROME_VERSION} Safari/537.36",
];

function extractChromeVersion(browserVersion) {
  const s = String(browserVersion || "");
  const m4 = /(\d+\.\d+\.\d+\.\d+)/.exec(s);
  if (m4) return m4[1];
  const m3 = /(\d+\.\d+\.\d+)/.exec(s);
  if (m3) return `${m3[1]}.0`;
  return "122.0.6261.69";
}

const DEFAULT_VIEWPORT_POOL = [
  { width: 1366, height: 768 },
  { width: 1536, height: 864 },
  { width: 1440, height: 900 },
  { width: 1280, height: 800 },
  { width: 1920, height: 1080 },
];

const DEFAULT_LOCALE_PROFILES = [
  { locale: "en-US", timezoneId: "America/New_York", acceptLanguage: "en-US,en;q=0.9" },
  { locale: "en-US", timezoneId: "America/Los_Angeles", acceptLanguage: "en-US,en;q=0.9" },
  { locale: "en-GB", timezoneId: "Europe/London", acceptLanguage: "en-GB,en;q=0.9" },
  { locale: "zh-CN", timezoneId: "Asia/Shanghai", acceptLanguage: "zh-CN,zh;q=0.9,en;q=0.8" },
  { locale: "ja-JP", timezoneId: "Asia/Tokyo", acceptLanguage: "ja-JP,ja;q=0.9,en;q=0.8" },
];

const IPINFO_URL = "https://ipinfo.io";
const IPINFO_TIMEOUT_MS = 5_000;
// Cross-process cache: avoids hitting ipinfo.io repeatedly when the script is invoked many times in one "task".
// Keep TTL modest because exit IP can change (VPN, mobile hotspot, etc.).
const IPINFO_CACHE_TTL_MS = 10 * 60 * 1000;
const IPINFO_CACHE_PATH = path.join(os.tmpdir(), "headless-web-viewer-ipinfo.json");
let ipinfoOncePromise = null;

function isValidIanaTimezone(timezoneId) {
  const tz = String(timezoneId || "").trim();
  return /^[A-Za-z_]+(?:\/[A-Za-z0-9_\-+]+)+$/.test(tz);
}

function pickWeighted(rng, items) {
  const total = items.reduce((s, it) => s + it.weight, 0);
  if (!(total > 0)) throw new Error("pickWeighted requires positive total weight");
  let r = rng.float() * total;
  for (const it of items) {
    r -= it.weight;
    if (r <= 0) return it.value;
  }
  return items[items.length - 1].value;
}

function ipinfoCountryToLocale(countryCode) {
  const cc = String(countryCode || "").toUpperCase();
  switch (cc) {
    case "US":
      return { locale: "en-US", acceptLanguage: "en-US,en;q=0.9" };
    case "GB":
      return { locale: "en-GB", acceptLanguage: "en-GB,en;q=0.9" };
    case "CA":
      return { locale: "en-CA", acceptLanguage: "en-CA,en;q=0.9,fr-CA;q=0.7" };
    case "AU":
      return { locale: "en-AU", acceptLanguage: "en-AU,en;q=0.9" };
    case "NZ":
      return { locale: "en-NZ", acceptLanguage: "en-NZ,en;q=0.9" };
    case "IE":
      return { locale: "en-IE", acceptLanguage: "en-IE,en;q=0.9" };
    case "DE":
      return { locale: "de-DE", acceptLanguage: "de-DE,de;q=0.9,en;q=0.7" };
    case "FR":
      return { locale: "fr-FR", acceptLanguage: "fr-FR,fr;q=0.9,en;q=0.7" };
    case "ES":
      return { locale: "es-ES", acceptLanguage: "es-ES,es;q=0.9,en;q=0.7" };
    case "IT":
      return { locale: "it-IT", acceptLanguage: "it-IT,it;q=0.9,en;q=0.7" };
    case "BR":
      return { locale: "pt-BR", acceptLanguage: "pt-BR,pt;q=0.9,en;q=0.7" };
    case "MX":
      return { locale: "es-MX", acceptLanguage: "es-MX,es;q=0.9,en;q=0.7" };
    case "CN":
      return { locale: "zh-CN", acceptLanguage: "zh-CN,zh;q=0.9,en;q=0.8" };
    case "TW":
      return { locale: "zh-TW", acceptLanguage: "zh-TW,zh;q=0.9,en;q=0.8" };
    case "HK":
      return { locale: "zh-HK", acceptLanguage: "zh-HK,zh;q=0.9,en;q=0.8" };
    case "JP":
      return { locale: "ja-JP", acceptLanguage: "ja-JP,ja;q=0.9,en;q=0.8" };
    case "KR":
      return { locale: "ko-KR", acceptLanguage: "ko-KR,ko;q=0.9,en;q=0.7" };
    case "IN":
      return { locale: "en-IN", acceptLanguage: "en-IN,en;q=0.9,hi;q=0.6" };
    default:
      return null;
  }
}

function defaultTimezoneForLocale(locale) {
  const l = String(locale || "");
  const hit = DEFAULT_LOCALE_PROFILES.find((p) => p.locale === l);
  return hit?.timezoneId || null;
}

function defaultAcceptLanguageForLocale(locale) {
  const l = String(locale || "");
  const hit = DEFAULT_LOCALE_PROFILES.find((p) => p.locale === l);
  return hit?.acceptLanguage || null;
}

function fallbackTimezoneForIpInfo({ country, region, rng }) {
  const cc = String(country || "").toUpperCase();
  const r = String(region || "");

  if (cc === "US") {
    if (/(California|Washington|Oregon|Nevada)/i.test(r)) return "America/Los_Angeles";
    if (/(New York|Massachusetts|Virginia|Maryland|New Jersey|Pennsylvania|Florida)/i.test(r))
      return "America/New_York";
    if (/(Texas|Illinois|Minnesota|Wisconsin|Tennessee)/i.test(r)) return "America/Chicago";
    if (/(Colorado|Utah|Arizona|New Mexico)/i.test(r)) return "America/Denver";
    return rng.bool(0.55) ? "America/New_York" : "America/Los_Angeles";
  }
  if (cc === "CA") {
    if (/(British Columbia)/i.test(r)) return "America/Vancouver";
    return "America/Toronto";
  }
  if (cc === "GB") return "Europe/London";
  if (cc === "DE") return "Europe/Berlin";
  if (cc === "FR") return "Europe/Paris";
  if (cc === "ES") return "Europe/Madrid";
  if (cc === "IT") return "Europe/Rome";
  if (cc === "BR") return "America/Sao_Paulo";
  if (cc === "MX") return "America/Mexico_City";
  if (cc === "CN") return "Asia/Shanghai";
  if (cc === "TW") return "Asia/Taipei";
  if (cc === "HK") return "Asia/Hong_Kong";
  if (cc === "JP") return "Asia/Tokyo";
  if (cc === "KR") return "Asia/Seoul";
  if (cc === "IN") return "Asia/Kolkata";

  return null;
}

function deriveGeoProfile({ rng, ipinfoData }) {
  if (!ipinfoData || typeof ipinfoData !== "object") {
    const fallback = rng.pick(DEFAULT_LOCALE_PROFILES);
    return {
      source: "default",
      country: null,
      region: null,
      city: null,
      timezoneId: fallback.timezoneId,
      locale: fallback.locale,
      acceptLanguage: fallback.acceptLanguage,
      uaHint: { osWeights: null },
    };
  }

  const country = String(ipinfoData.country || "").toUpperCase() || null;
  const region = String(ipinfoData.region || "") || null;
  const city = String(ipinfoData.city || "") || null;

  const mapped = ipinfoCountryToLocale(country);
  const locale =
    mapped?.locale ||
    (() => {
      const fallback = rng.pick(DEFAULT_LOCALE_PROFILES);
      return fallback.locale;
    })();
  const acceptLanguage =
    mapped?.acceptLanguage || defaultAcceptLanguageForLocale(locale) || "en-US,en;q=0.9";

  const timezoneId =
    (isValidIanaTimezone(ipinfoData.timezone) ? String(ipinfoData.timezone) : null) ||
    fallbackTimezoneForIpInfo({ country, region, rng }) ||
    defaultTimezoneForLocale(locale) ||
    rng.pick(DEFAULT_LOCALE_PROFILES).timezoneId;

  const osWeightsByCountry = (() => {
    switch (country) {
      case "CN":
        return { windows: 0.86, mac: 0.09, linux: 0.05 };
      case "JP":
        return { windows: 0.7, mac: 0.25, linux: 0.05 };
      case "KR":
        return { windows: 0.75, mac: 0.2, linux: 0.05 };
      case "US":
        return { windows: 0.65, mac: 0.25, linux: 0.1 };
      case "GB":
      case "DE":
      case "FR":
        return { windows: 0.6, mac: 0.3, linux: 0.1 };
      default:
        return { windows: 0.7, mac: 0.2, linux: 0.1 };
    }
  })();

  return {
    source: "ipinfo",
    country,
    region,
    city,
    timezoneId,
    locale,
    acceptLanguage,
    uaHint: { osWeights: osWeightsByCountry },
  };
}

function pickUserAgentTemplate(rng, geoProfile) {
  const osWeights = geoProfile?.uaHint?.osWeights;
  if (!osWeights) return rng.pick(DEFAULT_UA_TEMPLATES);
  return pickWeighted(rng, [
    { value: DEFAULT_UA_TEMPLATES[0], weight: osWeights.windows },
    { value: DEFAULT_UA_TEMPLATES[1], weight: osWeights.mac },
    { value: DEFAULT_UA_TEMPLATES[2], weight: osWeights.linux },
  ]);
}

async function fetchJsonHttps(url, timeoutMs, headers = {}) {
  return await new Promise((resolve, reject) => {
    const req = https.request(
      url,
      { method: "GET", headers: { Accept: "application/json", ...headers } },
      (res) => {
        const chunks = [];
        res.on("data", (c) => chunks.push(c));
        res.on("end", () => {
          const body = Buffer.concat(chunks).toString("utf8");
          if (res.statusCode && res.statusCode >= 400) {
            reject(new Error(`HTTP ${res.statusCode}`));
            return;
          }
          try {
            resolve(JSON.parse(body));
          } catch (e) {
            reject(e);
          }
        });
      }
    );
    req.on("error", reject);
    req.setTimeout(timeoutMs, () => {
      req.destroy(new Error("timeout"));
    });
    req.end();
  });
}

function sanitizeIpInfo(raw) {
  if (!raw || typeof raw !== "object") return null;
  return {
    ip: typeof raw.ip === "string" ? raw.ip : null,
    hostname: typeof raw.hostname === "string" ? raw.hostname : null,
    city: typeof raw.city === "string" ? raw.city : null,
    region: typeof raw.region === "string" ? raw.region : null,
    country: typeof raw.country === "string" ? raw.country : null,
    loc: typeof raw.loc === "string" ? raw.loc : null,
    org: typeof raw.org === "string" ? raw.org : null,
    postal: typeof raw.postal === "string" ? raw.postal : null,
    timezone: typeof raw.timezone === "string" ? raw.timezone : null,
  };
}

function tryReadIpInfoCache() {
  try {
    const raw = fs.readFileSync(IPINFO_CACHE_PATH, "utf8");
    const parsed = JSON.parse(raw);
    if (!parsed || typeof parsed !== "object") return null;
    if (typeof parsed.fetchedAtMs !== "number") return null;
    if (!parsed.data || typeof parsed.data !== "object") return null;
    const data = sanitizeIpInfo(parsed.data);
    if (!data) return null;
    return { fetchedAtMs: parsed.fetchedAtMs, data };
  } catch {
    return null;
  }
}

function writeIpInfoCache(data) {
  const payload = { fetchedAtMs: Date.now(), data: sanitizeIpInfo(data) };
  if (!payload.data) return;
  const tmp = `${IPINFO_CACHE_PATH}.${process.pid}.${Math.random().toString(16).slice(2)}.tmp`;
  try {
    fs.writeFileSync(tmp, JSON.stringify(payload) + "\n", "utf8");
    fs.renameSync(tmp, IPINFO_CACHE_PATH);
  } catch {
    try {
      fs.unlinkSync(tmp);
    } catch {
      // ignore
    }
  }
}

async function getIpInfoOnce(mode) {
  if (mode === "off") {
    return {
      enabled: false,
      ok: false,
      timeoutMs: IPINFO_TIMEOUT_MS,
      cache: { path: IPINFO_CACHE_PATH, hit: false, stale: false, ttlMs: IPINFO_CACHE_TTL_MS },
      data: null,
      error: null,
    };
  }

  if (!ipinfoOncePromise) {
    ipinfoOncePromise = (async () => {
      const cached = tryReadIpInfoCache();
      if (cached) {
        const ageMs = Date.now() - cached.fetchedAtMs;
        const stale = !(ageMs >= 0 && ageMs <= IPINFO_CACHE_TTL_MS);
        if (!stale) {
          return {
            enabled: true,
            ok: true,
            timeoutMs: IPINFO_TIMEOUT_MS,
            cache: {
              path: IPINFO_CACHE_PATH,
              hit: true,
              stale: false,
              ageMs,
              ttlMs: IPINFO_CACHE_TTL_MS,
            },
            data: cached.data,
            error: null,
          };
        }
      }

      try {
        const raw = await fetchJsonHttps(IPINFO_URL, IPINFO_TIMEOUT_MS);
        writeIpInfoCache(raw);
        return {
          enabled: true,
          ok: true,
          timeoutMs: IPINFO_TIMEOUT_MS,
          cache: { path: IPINFO_CACHE_PATH, hit: false, stale: false, ttlMs: IPINFO_CACHE_TTL_MS },
          data: sanitizeIpInfo(raw),
          error: null,
        };
      } catch (e) {
        // If ipinfo is temporarily unavailable, a stale cache is still better than dropping to a random geo profile.
        const cached = tryReadIpInfoCache();
        if (cached) {
          const ageMs = Date.now() - cached.fetchedAtMs;
          return {
            enabled: true,
            ok: true,
            timeoutMs: IPINFO_TIMEOUT_MS,
            cache: {
              path: IPINFO_CACHE_PATH,
              hit: true,
              stale: true,
              ageMs,
              ttlMs: IPINFO_CACHE_TTL_MS,
            },
            data: cached.data,
            error: e?.message ? String(e.message) : String(e),
          };
        }
        return {
          enabled: true,
          ok: false,
          timeoutMs: IPINFO_TIMEOUT_MS,
          cache: { path: IPINFO_CACHE_PATH, hit: false, stale: false, ttlMs: IPINFO_CACHE_TTL_MS },
          data: null,
          error: e?.message ? String(e.message) : String(e),
        };
      }
    })();
  }

  return await ipinfoOncePromise;
}

async function randomPause(page, rng, minMs, maxMs) {
  const ms = rng.int(minMs, maxMs);
  await page.waitForTimeout(ms);
}

async function maybeScroll(page, rng) {
  const steps = rng.bool(0.75) ? 1 : 2;
  for (let i = 0; i < steps; i++) {
    const deltaY = rng.int(200, 900);
    try {
      await page.mouse.wheel(0, deltaY);
    } catch {
      await page.evaluate((dy) => window.scrollBy(0, dy), deltaY);
    }
    await randomPause(page, rng, 250, 900);
  }
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
    const seed32 = seedToUint32(args.seed);
    const rng = createRng(seed32);
    const chromeVersion = extractChromeVersion(browser.version());
    const ipinfo = await getIpInfoOnce(args.ipinfo);
    const geoProfile = deriveGeoProfile({ rng, ipinfoData: ipinfo.data });
    const viewport = args.viewport || rng.pick(DEFAULT_VIEWPORT_POOL);
    const userAgent =
      args.userAgent ||
      pickUserAgentTemplate(rng, geoProfile).replace("{CHROME_VERSION}", chromeVersion);

    const context = await browser.newContext({
      userAgent,
      viewport,
      locale: geoProfile.locale,
      timezoneId: geoProfile.timezoneId,
      extraHTTPHeaders: { "Accept-Language": geoProfile.acceptLanguage },
    });
    const page = await context.newPage();
    await page.goto(args.url, { waitUntil: args.waitUntil, timeout: args.timeout });

    // Human-ish pacing: small delay + 1-2 scrolls to trigger lazy content and reduce "instant extraction" fingerprints.
    await randomPause(page, rng, 150, 650);
    await maybeScroll(page, rng);
    await randomPause(page, rng, 80, 300);

    if (args.outMeta) {
      const observed = await page.evaluate(() => {
        const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
        return {
          userAgent: navigator.userAgent,
          language: navigator.language,
          languages: Array.isArray(navigator.languages) ? navigator.languages.slice() : [],
          timeZone: tz,
          innerWidth: window.innerWidth,
          innerHeight: window.innerHeight,
          devicePixelRatio: window.devicePixelRatio,
        };
      });

      const meta = {
        url: args.url,
        seed: args.seed ?? null,
        seed32,
        ipinfo,
        geoProfile,
        chosen: {
          userAgent,
          viewport,
          locale: geoProfile.locale,
          timezoneId: geoProfile.timezoneId,
          acceptLanguage: geoProfile.acceptLanguage,
        },
        observed,
      };

      ensureParentDir(args.outMeta);
      fs.writeFileSync(args.outMeta, JSON.stringify(meta, null, 2) + "\n", "utf8");
    }

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
