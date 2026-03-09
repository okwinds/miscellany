# prd-writing-guide

"Write complete, unambiguous PRDs that development teams can implement without guesswork. Includes requirement discovery framework, structured documentation methodology, completeness checklists, and common pitfall avoidance. Use when: writing new PRDs, reviewing PRD drafts, validating requirement completeness, preparing for engineering handoff. Triggers: 'write PRD', '写PRD', '产品需求文档', '需求文档', '需求规格', '需求评审', '完善需求', 'create requirements doc', 'product requirements', 'feature spec', 'requirements document'. Anti-triggers: 'technical design doc', 'architecture design', 'implementation plan', 'API design', '架构设计', '技术方案', '实现方案', '接口设计'."

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
rm -rf "$SKILLS_DIR/prd-writing-guide"
cp -R agent/skills/prd-writing-guide "$SKILLS_DIR/prd-writing-guide"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/prd-writing-guide"
ln -s "$(pwd)/agent/skills/prd-writing-guide" "$SKILLS_DIR/prd-writing-guide"
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

安装时选择 `prd-writing-guide`（仓库内路径：`agent/skills/prd-writing-guide`）。

验证/读取：

```bash
npx openskills list
npx openskills read prd-writing-guide
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/prd-writing-guide`。

## 用法

### 使用内置的 PRD 目录骨架生成脚本（可选）

在仓库根目录执行（或在你安装 skill 的目录执行）：

```bash
bash ./scripts/generate_prd_skeleton.sh ./docs/prd "User Dashboard Redesign"
```

随后补全生成的 Markdown 文件，并用 `./references/` 里的检查清单做完整性校验。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。
