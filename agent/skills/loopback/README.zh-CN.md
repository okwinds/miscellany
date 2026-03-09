# loopback

"Loopback 迭代开发循环 - 基于 Ralph Loop 思想实现的 Codex 版本。用于创建自引用的迭代开发循环，让 AI 在多次迭代中逐步改进代码，直到任务完成。Use when: (1) 需要多次迭代改进的任务, (2) 复杂功能需要分步实现, (3) 需要自我修正的代码生成, (4) 迭代优化已有代码."

## 来源说明（Provenance）

本 skill 是一个面向 Codex 的 **Ralph Loop** 适配版本。Ralph Loop 最初来自 **Claude Code**（在配置/社区资料里也常写作 `ralphloop` / `ralph-loop`）。这里的 Loopback 并非 Claude Code 官方组件，而是为了在“工具链能力不同”的前提下，尽量保留“同一句 prompt，多轮迭代收敛”的工作方式而做的工程化移植。

## 与 Ralph Loop 的差异（以及差异从何而来）

Ralph Loop 运行在 Claude Code 内部，可以依赖运行时 hook（例如 stop/exit hook）来驱动下一轮迭代。Codex CLI 没有等价的“stop hook”能力，所以 Loopback 采用 **状态文件 + driver 脚本** 的方式在外部实现循环：

- **状态文件**：`.codex/loopback.local.md` 保存原始 PROMPT 与停止契约。
- **driver**：`scripts/codex-loopback-wrapper.sh` 反复调用 `codex exec`，并把每轮输出写到 `.codex/loopback.outputs/iteration-N.log`。
- **完成检测**：通过日志中的结构化标签 `<promise>...</promise>` 来判断，而不是靠“输出 DONE”这种不稳定的自由文本。

这些“实现约束”会直接导致一些使用层面的差异，需要你提前注意：

- **默认必须提供停止契约**（非交互安全）：至少提供 `--completion-promise` 或 `--max-iterations`，否则会失败；除非你显式声明 `--allow-infinite`（不推荐）。
- **“复用同一会话”是实现细节**：Loopback 会尝试通过解析 `codex exec --json` 的事件拿到 session id 并 resume。如果 Codex CLI 的 JSON 结构变更，会影响复用/续跑逻辑；循环本身仍可工作，但可能退化为新会话模式（取决于你的运行器）。
- **上下文主要来自文件而非对话记忆**：每轮能“看见”的内容取决于工作目录、仓库状态以及磁盘上产生的变更。
- **取消是基于文件的**：删除 `.codex/loopback.local.md` 即表示取消（如果你的运行器支持 slash command，也可以用 `/cancel-loop`）。

## 前置条件

- `codex` CLI 已安装且在 `PATH` 中。
- `bash` + 常见命令行工具（macOS 自带 bash 3.2 可用）。
- Python 3 且可 import PyYAML（`python3 -c 'import yaml'` 应能通过；否则需要安装 `pyyaml`）。

## 包含内容

- `SKILL.md`
- `commands/`（支持 slash command 的运行器可用）
- `scripts/`（driver 与辅助脚本）

运行时会在你的项目目录生成：

- `.codex/loopback.local.md`（状态文件）
- `.codex/loopback.outputs/iteration-N.log`（每轮输出日志）

## 安装

> 安装 skill 的本质是：让你的编码工具 / Agent 运行器能发现这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或使用工具内置的“从 Git 安装”能力）。

### 方式 A：复制安装

在仓库根目录执行：

把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（示例：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/loopback"
cp -R agent/skills/loopback "$SKILLS_DIR/loopback"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/loopback"
ln -s "$(pwd)/agent/skills/loopback" "$SKILLS_DIR/loopback"
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

安装时选择 `loopback`（仓库内路径：`agent/skills/loopback`）。

验证/读取：

```bash
npx openskills list
npx openskills read loopback
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/loopback`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 使用方式

如果你的运行器支持读取 `commands/` 中的 slash command：

```text
/loopback --guide
/loopback "修复 X。完成后输出 <promise>DONE</promise>。" --completion-promise "DONE" --max-iterations 10
/cancel-loop
```

如果你的运行器 **不支持** slash command，也可以在项目根目录直接运行脚本：

```bash
bash ./scripts/setup-loopback.sh \
  "修复 X。完成后输出 <promise>DONE</promise>。" \
  --completion-promise "DONE" \
  --max-iterations 10
```

## 安全注意事项

- 建议把“完成标准”写成**可验证**的契约（例如测试全绿、命令无报错、可复现步骤通过）。只有在完全满足契约时才输出 `<promise>`。
- 除非你明确理解风险，否则不要为了省事而在 Codex 中开启“绕过审批/沙盒”等高风险参数（会扩大副作用面）。
