# bf-caprt-dev

"指导编码智能体以 capability-runtime 为业务落地入口，交付基于 capability-runtime 的 skills / agents / workflows，并在 Greenfield 或 Legacy Convergence 场景下优先使用 Runtime public surface、structured output、NodeReport、host summary 与 service/session surfaces。只要任务目标是用 capability-runtime / capability_runtime 落地业务代码、收敛下游 runtime boundary，或涉及 Runtime.run / Runtime.run_stream / run_structured / run_structured_stream / AgentSpec / PromptRenderMode / prompt_render_mode / _runtime_prompt / precomposed_messages / multimodal / vision / image input / 多图输入 / 视频抽帧输入 / OpenAI-compatible messages / image_url content parts / WorkflowSpec / NodeReport / RuntimeServiceFacade / describe_capability / summarize_host_run，就应优先使用本技能。不要用于普通通用编码、prompt-only 任务、直接学习上游原生框架 API，或任何明确要求“直接用 skills-runtime-sdk / Agently / provider SDK，不走 capability-runtime”的任务；若已触发但随后识别出这是反目标，必须立即退出，并停止提供任何上游实现细节、伪代码或 API 猜测。"

## What's included

- `SKILL.md`
- `references/`
- `evals/`

## Installation

> Installing a skill means your coding tool / agent runner can discover the `SKILL.md` inside it (typically via a `skills/` directory, or via a built-in “install from Git” feature).

### Option A: copy

From this repo root:

Set `SKILLS_DIR` to whatever skills folder your tool scans (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-caprt-dev"
cp -R agent/skills/bf-caprt-dev "$SKILLS_DIR/bf-caprt-dev"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/bf-caprt-dev"
ln -s "$(pwd)/agent/skills/bf-caprt-dev" "$SKILLS_DIR/bf-caprt-dev"
```

### Option C: install from GitHub/Git via openskills

Prereqs for openskills:

- Requires Node.js (18+ recommended).
- No install needed if you use `npx openskills ...` (it will download and run).
- Optional global install: `npm i -g openskills` (or `pnpm add -g openskills`).

Install from a cloneable repo URL (do **not** use a GitHub `.../tree/...` subdirectory link):

```bash
npx openskills install https://github.com/okwinds/miscellany.git
```

When prompted, select `bf-caprt-dev` (repo path: `agent/skills/bf-caprt-dev`).

Verify / read back:

```bash
npx openskills list
npx openskills read bf-caprt-dev
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/bf-caprt-dev`.

### After install

Many tools require a restart / new session to re-scan skills.
