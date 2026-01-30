# Headless Web Viewer（无头网页查看器）

使用无头浏览器（Playwright）渲染网页，获取 JS 渲染后的 HTML，提取可见文本，并可选保存整页截图。

## 包含内容

- `SKILL.md`：技能定义与用法
- `scripts/render_url_playwright.mjs`：渲染脚本（CLI）
- `package.json` / `package-lock.json`：Playwright 依赖（不提交 `node_modules`）

## 安装到 Codex / Claude Code

> 这一份目录本身就是“技能包”。安装的本质是：把整个目录放进你的工具会扫描的 `skills/` 目录里（保持目录名不变、保留 `SKILL.md`）。

### 方式 A：复制安装（推荐给新手）

在本仓库根目录执行（二选一：`~/.codex/skills` 或 `~/.claude/skills`）：

```bash
SKILLS_DIR=~/.codex/skills   # 或 ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
cp -R agent/skills/headless-web-viewer "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### 方式 B：软链接安装（适合开发/同步更新）

```bash
SKILLS_DIR=~/.codex/skills   # 或 ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
ln -s "$(pwd)/agent/skills/headless-web-viewer" "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### 安装完成后怎么“用”

- 通常需要**重启/新开** Codex 或 Claude Code 会话，让它重新扫描 skills。
- 然后在对话里直接描述诉求即可，例如：“用无头浏览器打开这个 URL 并把可见文本导出来”。

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
