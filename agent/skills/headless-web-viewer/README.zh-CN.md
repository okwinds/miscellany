# Headless Web Viewer（无头网页查看器）

使用无头浏览器（Playwright）渲染网页，获取 JS 渲染后的 HTML，提取可见文本，并可选保存整页截图。

## 包含内容

- `SKILL.md`：技能定义与用法
- `scripts/render_url_playwright.mjs`：渲染脚本（CLI）
- `package.json` / `package-lock.json`：Playwright 依赖（不提交 `node_modules`）

## 用法

在仓库根目录执行：

```bash
node agent/skills/headless-web-viewer/scripts/render_url_playwright.mjs 'https://example.com' \
  --out-html /tmp/page.html \
  --out-text /tmp/page.txt \
  --out-screenshot /tmp/page.png
```

只输出文本（方便管道处理）：

```bash
node agent/skills/headless-web-viewer/scripts/render_url_playwright.mjs 'https://example.com' --print text
```

## 依赖说明

运行时需要 Playwright：

- 推荐（不下载浏览器）：安装 `playwright-core`，并用 `--channel chrome|msedge` 调用系统浏览器
- 备选（自带浏览器）：安装 `playwright`，并执行 `npx playwright install`

在技能目录安装依赖：

```bash
cd agent/skills/headless-web-viewer
npm ci
```

## 小贴士

- 若 `networkidle` 卡住，尝试 `--wait-until domcontentloaded`。
- 若页面反爬/拦截无头浏览器，尝试 `--user-agent` 或 `--channel chrome`。

