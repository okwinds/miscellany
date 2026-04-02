# bf-skillsruntime-dev

"用 Skills Runtime SDK（Python）开发复杂业务 agent、skills、workflow 的编码智能体指南。用户一旦提到 skills_runtime、Skills Runtime SDK、overlay YAML、FakeChatBackend、AgentBuilder、Coordinator、skill_ref_read、skill_exec、approvals/sandbox、WAL/replay、exec sessions、spawn_agent/send_input/wait、waiting_human/resume、examples/apps/workflows，或要在本仓上落地复杂业务开发/修复/回归，就应优先使用本技能。不要用于与本框架无关的通用编码或纯文案任务。"

## 包含内容

- `SKILL.md`
- `scripts/`
- `references/`

## 安装

> 安装 skill 的本质是：让你的编码工具 / Agent 运行器能发现这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或使用工具内置的“从 Git 安装”能力）。

### 方式 A：复制安装

在仓库根目录执行：

把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（示例：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-skillsruntime-dev"
cp -R agent/skills/bf-skillsruntime-dev "$SKILLS_DIR/bf-skillsruntime-dev"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-skillsruntime-dev"
ln -s "$(pwd)/agent/skills/bf-skillsruntime-dev" "$SKILLS_DIR/bf-skillsruntime-dev"
```

### 方式 C：用 openskills 从 GitHub/Git 安装

先准备 openskills：

- 需要 Node.js（建议 18+）。
- 不想安装：直接用 `npx openskills ...`（会自动下载并运行）。
- 想全局安装：`npm i -g openskills`（或 `pnpm add -g openskills`）。

从**可 clone 的仓库 URL** 安装（不要用 GitHub 的 `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany.git
```

安装时选择 `bf-skillsruntime-dev`（仓库内路径：`agent/skills/bf-skillsruntime-dev`）。

验证/读取：

```bash
npx openskills list
npx openskills read bf-skillsruntime-dev
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/bf-skillsruntime-dev`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 使用示例

如果你想快速生成一个 Skills Runtime SDK 业务应用骨架，请在技能目录内执行：

```bash
python3 ./scripts/scaffold_app.py my-app --out /tmp/my-app --with-skills
```

只预览、不落盘：

```bash
python3 ./scripts/scaffold_app.py my-app --out /tmp/my-app --with-skills --dry-run
```
