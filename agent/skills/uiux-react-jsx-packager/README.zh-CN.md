# uiux-react-jsx-packager

Package an existing React UI/UX demo into a single self-contained .jsx file with default-export root component, zero third-party runtime dependencies (no react-router/lucide/echarts/etc.), in-file styles (style tag or inline style objects), inline SVG icons, embedded or placeholder images, and state-based navigation. Use when asked to “合并为单文件 JSX/单文件打包/one-file React/零外部依赖/内联 CSS/替换图标库/用 state 做路由/把 demo 打包成独立 JSX 文件”.

## 包含内容

- `SKILL.md`
- `scripts/`（可选）
- `references/`（可选）
- `assets/`（可选）

## 安装

> 安装 skill 的本质是：让你的编码工具 / Agent 运行器能发现这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或使用工具内置的“从 Git 安装”能力）。

### 方式 A：复制安装

在仓库根目录执行：

把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（示例：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/uiux-react-jsx-packager"
cp -R agent/skills/uiux-react-jsx-packager "$SKILLS_DIR/uiux-react-jsx-packager"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/uiux-react-jsx-packager"
ln -s "$(pwd)/agent/skills/uiux-react-jsx-packager" "$SKILLS_DIR/uiux-react-jsx-packager"
```

### 方式 C：用 openskills 从 GitHub/Git 安装

先准备 openskills：

- 需要 Node.js（建议 18+）。
- 不想安装：直接用 `npx openskills ...`（会自动下载并运行）。
- 想全局安装：`npm i -g openskills`（或 `pnpm add -g openskills`）。

从**可 clone 的仓库 URL** 安装（不要用 GitHub 的 `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany
```

安装时选择 `uiux-react-jsx-packager`（仓库内路径：`agent/skills/uiux-react-jsx-packager`）。

验证/读取：

```bash
npx openskills list
npx openskills read uiux-react-jsx-packager
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/uiux-react-jsx-packager`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 使用方法

本 skill 主要是 `SKILL.md` 的工作流说明，并附带少量可选脚本用于验证与预览。

### 校验合并后的 `.jsx`

用启发式规则检查常见违规项（非 React import、`require()`、动态 `import()`、缺少 default export、资产导入等）：

```bash
python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py /path/to/Merged.jsx
```

更严格模式（把 warning 当作 fail）：

```bash
python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py --strict /path/to/Merged.jsx
```

### 运行时 smoke 预览（推荐）

在 `/tmp` 下创建隔离的 Vite+React 预览工程，用来尽早抓到“白屏/运行时异常”：

```bash
NO_OPEN=1 PORT=5188 bash agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh /path/to/Merged.jsx
```

如果终端出现 `Port 5188 is in use, trying another one...`，说明端口被占用并自动切换；请以 `Local:` 行的 URL 为准。
