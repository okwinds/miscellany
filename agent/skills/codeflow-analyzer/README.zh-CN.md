# codeflow-analyzer

追踪并记录代码库中任意功能或流程的完整调用链/数据流。适用于理解功能端到端如何工作、追踪调用链、分析代码流、跨层映射数据流，以及逆向工程流程。

## 包含内容

- `SKILL.md` — 核心技能定义和工作流程
- `scripts/` (可选) — 辅助脚本
- `references/` (可选) — 参考资料
- `assets/` (可选) — 支持资源

## 安装

> 安装技能意味着让你的编码工具/代理运行器能够发现其中的 `SKILL.md`（通常通过 `skills/` 目录，或内置的"从 Git 安装"功能）。

### 方式 A: 复制

在仓库根目录执行：

将 `SKILLS_DIR` 设置为你的工具扫描的技能目录（例如：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/codeflow-analyzer"
cp -R agent/skills/codeflow-analyzer "$SKILLS_DIR/codeflow-analyzer"
```

### 方式 B: 符号链接

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/codeflow-analyzer"
ln -s "$(pwd)/agent/skills/codeflow-analyzer" "$SKILLS_DIR/codeflow-analyzer"
```

### 方式 C: 通过 openskills 从 GitHub/Git 安装

openskills 前置条件：

- 需要 Node.js（推荐 18+ 版本）
- 使用 `npx openskills ...` 无需安装（会自动下载运行）
- 可选全局安装：`npm i -g openskills`（或 `pnpm add -g openskills`）

从可克隆的仓库 URL 安装（**不要**使用 GitHub `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany.git
```

当提示选择时，选择 `codeflow-analyzer`（仓库路径：`agent/skills/codeflow-analyzer`）。

验证/查看：

```bash
npx openskills list
npx openskills read codeflow-analyzer
```

### 方式 D: 提供你的工具 GitHub 链接

许多编码工具可以直接从 GitHub/Git URL 安装/加载技能。如果你的工具支持，指向此仓库并选择/定位 `agent/skills/codeflow-analyzer`。

### 安装后

许多工具需要重启/新建会话来重新扫描技能。
