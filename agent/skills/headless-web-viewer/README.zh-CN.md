# Headless Web Viewer（无头网页查看器）

使用无头浏览器（Playwright）渲染网页，获取 JS 渲染后的 HTML，提取可见文本，并可选保存整页截图。

## 包含内容

- `SKILL.md`：技能定义与用法
- `scripts/render_url_playwright.mjs`：渲染脚本（CLI）
- `package.json` / `package-lock.json`：Playwright 依赖（不提交 `node_modules`）

## 安装

> 这一份目录本身就是“技能包”。安装的本质是：让你的编码工具/Agent 运行器能找到这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或用工具的“从 Git 安装 skill”能力）。

### 方式 A：复制安装

在本仓库根目录执行，把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（例如 `~/.codex/skills` / `~/.claude/skills` / `~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
cp -R agent/skills/headless-web-viewer "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### 方式 B：软链接安装

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/headless-web-viewer"
ln -s "$(pwd)/agent/skills/headless-web-viewer" "$SKILLS_DIR/headless-web-viewer"
cd "$SKILLS_DIR/headless-web-viewer"
npm ci
```

### 方式 C：用 openskills 从 GitHub/Git 安装

用 `openskills install` 指向本仓库的 GitHub 地址（或任意 Git URL），在交互界面选择要安装的 skill：

```bash
npx openskills install <git-url>
```

例如（本仓库；注意：这里是**仓库 URL**，不是 GitHub 的 `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany
```

安装时在列表里选择 `headless-web-viewer`（其在仓库内的路径是 `agent/skills/headless-web-viewer`）。

常用选项：
- `-g`：全局安装
- `-u`：安装到 `.agent/skills/`（便于在不同工具/项目里通用）
- `-y`：跳过交互，安装检测到的全部技能

安装后，可用以下命令验证/读取：

```bash
npx openskills list
npx openskills read headless-web-viewer
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，直接把本仓库链接给它即可（并让它选择/指向 `agent/skills/headless-web-viewer` 这一子目录）；若不支持，请用上面的复制/软链接/`openskills install`。

### 安装完成后怎么用

一般需要重启/新开会话，让工具重新扫描 skills；之后在对话里直接描述诉求即可，例如：“用无头浏览器打开这个 URL 并把可见文本导出来”。

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
