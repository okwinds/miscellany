# xlsx-offline

Excel 表格离线读写与公式校验：创建/修改 xlsx，保持公式可复算，输出必须零公式错误；附带 LibreOffice 重算与错误扫描脚本（依赖安装可能需要网络）。

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
rm -rf "$SKILLS_DIR/xlsx-offline"
cp -R agent/skills/xlsx-offline "$SKILLS_DIR/xlsx-offline"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/xlsx-offline"
ln -s "$(pwd)/agent/skills/xlsx-offline" "$SKILLS_DIR/xlsx-offline"
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

安装时选择 `xlsx-offline`（仓库内路径：`agent/skills/xlsx-offline`）。

验证/读取：

```bash
npx openskills list
npx openskills read xlsx-offline
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/xlsx-offline`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 用法

本技能内置“公式重算 + 错误扫描”脚本（需要 LibreOffice 的 `soffice` 在 `PATH` 中）。请在已安装的 skill 目录内运行：

```bash
cd /path/to/xlsx-offline
python3 ./recalc.py output.xlsx 30
```

说明：

- 默认使用**隔离的 LibreOffice profile**，避免把宏永久写入你真实的 LibreOffice 配置目录。
- 若要使用真实 profile：加 `--no-isolated`
- 若要保留临时 profile 目录用于排查：加 `--keep-profile`
