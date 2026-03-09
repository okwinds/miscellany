# pdf-offline

PDF 文档离线读写与表单处理：提取文本/表格、合并拆分、生成 PDF、填写表单。适用于“本地处理/读取/生成 PDF 文件”（依赖安装可能需要网络）。

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
rm -rf "$SKILLS_DIR/pdf-offline"
cp -R agent/skills/pdf-offline "$SKILLS_DIR/pdf-offline"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/pdf-offline"
ln -s "$(pwd)/agent/skills/pdf-offline" "$SKILLS_DIR/pdf-offline"
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

安装时选择 `pdf-offline`（仓库内路径：`agent/skills/pdf-offline`）。

验证/读取：

```bash
npx openskills list
npx openskills read pdf-offline
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/pdf-offline`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 用法

在已安装的 skill 目录内运行附带脚本：

```bash
cd /path/to/pdf-offline

# （可选）安装本技能附带 CLI 的 Python 依赖
bash ./install.sh

# 读取 PDF → JSON
python3 ./doc_utils.py read path/to/file.pdf

# 合并 PDF
python3 ./doc_utils.py merge merged.pdf a.pdf b.pdf
```

如需“表单字段/标注框”等工作流，请直接看 `FORMS.md` 与 `./scripts/` 下的脚本。
