# bf-caprt-dev

"指导编码智能体以 capability-runtime 为业务落地入口，交付基于 capability-runtime 的 skills / agents / workflows，并在 Greenfield 或 Legacy Convergence 场景下优先使用 Runtime public surface、structured output、NodeReport、host summary 与 service/session surfaces。只要任务目标是用 capability-runtime / capability_runtime 落地业务代码、收敛下游 runtime boundary，或涉及 Runtime.run / Runtime.run_stream / run_structured / run_structured_stream / AgentSpec / PromptRenderMode / prompt_render_mode / _runtime_prompt / precomposed_messages / multimodal / vision / image input / 多图输入 / 视频抽帧输入 / OpenAI-compatible messages / image_url content parts / WorkflowSpec / NodeReport / RuntimeServiceFacade / describe_capability / summarize_host_run，就应优先使用本技能。不要用于普通通用编码、prompt-only 任务、直接学习上游原生框架 API，或任何明确要求“直接用 skills-runtime-sdk / Agently / provider SDK，不走 capability-runtime”的任务；若已触发但随后识别出这是反目标，必须立即退出，并停止提供任何上游实现细节、伪代码或 API 猜测。"

## 包含内容

- `SKILL.md`
- `references/`
- `evals/`

## 安装

> 安装 skill 的本质是：让你的编码工具 / Agent 运行器能发现这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或使用工具内置的“从 Git 安装”能力）。

### 方式 A：复制安装

在仓库根目录执行：

把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（示例：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-caprt-dev"
cp -R agent/skills/bf-caprt-dev "$SKILLS_DIR/bf-caprt-dev"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-caprt-dev"
ln -s "$(pwd)/agent/skills/bf-caprt-dev" "$SKILLS_DIR/bf-caprt-dev"
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

安装时选择 `bf-caprt-dev`（仓库内路径：`agent/skills/bf-caprt-dev`）。

验证/读取：

```bash
npx openskills list
npx openskills read bf-caprt-dev
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/bf-caprt-dev`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。
