# prd-to-engineering-spec

"Transform PRD (Product Requirements Document) into actionable engineering specifications. Creates detailed technical specs that developers can implement step-by-step without ambiguity. Covers data modeling, API design, business logic, security architecture, deployment, and agent system design. Use when: converting product requirements to technical specs, validating PRD completeness, planning technical implementation, creating task breakdowns, or defining test specifications. Triggers: 'PRD to spec', 'convert requirements', 'technical spec from PRD', 'engineering doc from requirements', 'validate PRD'."

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
rm -rf "$SKILLS_DIR/prd-to-engineering-spec"
cp -R agent/skills/prd-to-engineering-spec "$SKILLS_DIR/prd-to-engineering-spec"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/prd-to-engineering-spec"
ln -s "$(pwd)/agent/skills/prd-to-engineering-spec" "$SKILLS_DIR/prd-to-engineering-spec"
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

安装时选择 `prd-to-engineering-spec`（仓库内路径：`agent/skills/prd-to-engineering-spec`）。

验证/读取：

```bash
npx openskills list
npx openskills read prd-to-engineering-spec
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/prd-to-engineering-spec`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 用法

在仓库根目录执行，生成规范目录骨架（默认输出：`./engineering-spec`）：

```bash
bash ./scripts/generate_spec_skeleton.sh
```

校验进行中的工程规格：

```bash
bash ./scripts/validate_spec.sh engineering-spec
```
