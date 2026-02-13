# uiux-react-jsx-packager

把一个现有的 React UI/UX Demo 打包成 **单个自包含** 的 `*.jsx` 文件：默认导出根组件、运行时只依赖 React（不依赖 react-router/lucide/echarts 等第三方库）、样式内联（`<style>` 或 `style={{...}}`）、图标替换为内联 SVG、图片改为 base64 或确定性占位图，并用组件 state 实现“路由/导航”。适用于你希望“合并为单文件 JSX/单文件打包/one-file React/零外部依赖/内联 CSS/替换图标库/用 state 做路由/把 demo 打包成独立 JSX 文件”的场景。

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

这个 skill 本质是一套写在 `SKILL.md` 里的工作流说明。你可以在需要“把 React UI Demo 合并成单文件 `*.jsx`”时，让你的编码工具 / Agent 运行器使用 `uiux-react-jsx-packager`。

如果你希望对生成的单文件做一个快速本地校验，可以运行随附的验证脚本：

```bash
cd /path/to/uiux-react-jsx-packager
python3 scripts/verify_singlefile_jsx.py /path/to/YourMerged.jsx
```
