# docx-offline

DOCX 文档离线读写：提取/分析、OOXML 解包编辑回包、批注与修订（tracked changes/redlining）。适用于合同/制度/论文等需要保留格式与修订痕迹的场景（依赖安装可能需要网络）。

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
rm -rf "$SKILLS_DIR/docx-offline"
cp -R agent/skills/docx-offline "$SKILLS_DIR/docx-offline"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/docx-offline"
ln -s "$(pwd)/agent/skills/docx-offline" "$SKILLS_DIR/docx-offline"
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

安装时选择 `docx-offline`（仓库内路径：`agent/skills/docx-offline`）。

验证/读取：

```bash
npx openskills list
npx openskills read docx-offline
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/docx-offline`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 用法

在已安装的 skill 目录内运行这些命令：

```bash
cd /path/to/docx-offline

# 提取文本（保留修订痕迹）
pandoc --track-changes=all path-to-file.docx -o out.md

# OOXML 解包/回包
python3 ./ooxml/scripts/unpack.py path-to-file.docx unpacked-docx
python3 ./ooxml/scripts/pack.py unpacked-docx out.docx
```

如需“批注/修订（tracked changes）”的规范操作，请按 `ooxml.md` 的流程走。
