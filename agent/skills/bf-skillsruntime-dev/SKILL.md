---
name: bf-skillsruntime-dev
version: 0.1.0
description: "用 Skills Runtime SDK（Python）开发复杂业务 agent、skills、workflow 的编码智能体指南。用户一旦提到 skills_runtime、Skills Runtime SDK、overlay YAML、FakeChatBackend、AgentBuilder、Coordinator、skill_ref_read、skill_exec、approvals/sandbox、WAL/replay、exec sessions、spawn_agent/send_input/wait、waiting_human/resume、examples/apps/workflows，或要在本仓上落地复杂业务开发/修复/回归，就应优先使用本技能。不要用于与本框架无关的通用编码或纯文案任务。"
compatibility: "需要 Python 3。允许读取目标仓库与当前工作区文件；本技能自身不依赖技能目录外文档，所有参考资料均在本技能 references/ 内。脚手架脚本会在用户指定目录写入 run.py、config/runtime.yaml、skills/、tests/。"
---

# Skills Runtime SDK 业务开发指南

核心原则：
- 离线优先：先让 `FakeChatBackend` 跑通最小闭环，再接真模型
- Skills-First：角色能力先沉淀成 `SKILL.md`，编排层只负责组合
- 证据优先：副作用必须能在 WAL / approvals / tool events 中回放
- 双轨协作：固定角色用 `Coordinator`，动态子任务用 collab primitives

事实快照：
- 当前技能按 **2026-04-02 / SDK 0.1.11** 校对
- 本技能只引用当前目录内的 `references/` 与 `scripts/`
- 如果你发现仓库事实再次变化，先更新本技能的本地 references，再继续使用

## 开场动作

1. 先定位本地仓库根目录，不要默认联网克隆。
2. 优先确认当前环境是否已经安装 `skills-runtime-sdk`；未安装时再用本地仓库做 editable install。
3. 先选开发形态，再决定读哪份本地 reference：
   - 单 agent + 工具：看 `references/recipes-index.md`
   - Skills 注入 / references / actions：看 `references/config-templates.md`
   - 多 agent / 动态协作：看 `references/api-cheatsheet.md` + `references/recipes-index.md`
   - 安全 / 审批 / 沙箱：看 `references/safety-and-sandbox.md`
   - 回归 / 验证 / 证据：看 `references/testing-strategy.md`

## 本地环境准备

如果已知仓库根目录，记为 `REPO_ROOT`：

```bash
export REPO_ROOT=/abs/path/to/skills-runtime-sdk
```

安装 SDK 二选一：

```bash
# 方式 A：开发模式安装（推荐）
pip install -e "$REPO_ROOT/packages/skills-runtime-sdk-python"

# 方式 B：临时 PYTHONPATH（不安装）
export PYTHONPATH="$REPO_ROOT/packages/skills-runtime-sdk-python/src"
```

CLI 两种入口都可用：

```bash
skills-runtime-sdk --help
python3 -m skills_runtime.cli.main --help
```

## 快速开始

### 1) 生成业务骨架

```bash
python3 scripts/scaffold_app.py my-app --out . --with-skills
# 预览：加 --dry-run
# 覆盖：加 --force
```

默认生成：
- `run.py`
- `config/runtime.yaml`
- `skills/`
- `tests/`

### 2) 离线跑通

```bash
python3 run.py --workspace-root /tmp/my-app --mode offline
```

### 3) 最小回归

```bash
pytest -q tests
```

如果你正在本仓内开发，再跑仓库门禁：

```bash
bash scripts/pytest.sh
pytest -q packages/skills-runtime-sdk-python/tests/test_examples_smoke.py
```

## 推荐导入与运行骨架

### 最小 Agent

```python
from pathlib import Path
from skills_runtime.agent import Agent
from skills_runtime.llm.fake import FakeChatBackend, FakeChatCall
from skills_runtime.llm.chat_sse import ChatStreamEvent

agent = Agent(
    workspace_root=Path("/tmp/demo").resolve(),
    backend=FakeChatBackend(calls=[
        FakeChatCall(events=[
            ChatStreamEvent(type="text_delta", text="EXAMPLE_OK: done."),
            ChatStreamEvent(type="completed", finish_reason="stop"),
        ])
    ]),
)
result = agent.run("完成任务")
print(result.status, result.final_output, result.wal_locator)
```

### 生产级 AgentBuilder

```python
from pathlib import Path
from skills_runtime import AgentBuilder
from skills_runtime.state.wal_protocol import InMemoryWal
from skills_runtime.safety import ApprovalRule, RuleBasedApprovalProvider
from skills_runtime.safety.approvals import ApprovalDecision

provider = RuleBasedApprovalProvider(
    rules=[
        ApprovalRule(tool="read_file", decision=ApprovalDecision.APPROVED),
    ],
    default=ApprovalDecision.DENIED,
)

agent = (
    AgentBuilder()
    .workspace_root(Path(".").resolve())
    .backend(backend)
    .wal_backend(InMemoryWal())
    .approval_provider(provider)
    .event_hooks([lambda ev: print(ev.type)])
    .build()
)
```

说明：
- `Agent` 推荐从 `skills_runtime.agent` 导入
- `AgentBuilder` / `Coordinator` 推荐从包根 `skills_runtime` 导入
- `RunResult.status` 当前应按 `completed|failed|cancelled|waiting_human` 处理

## 复杂任务落地路由

### 路由 A：单 agent + 标准工具

适用：
- 代码修改、读写文件、最小命令执行、离线 smoke

做法：
- 用 `Agent` 或 `AgentBuilder`
- 工具优先走 builtin tools：`read_file` / `apply_patch` / `file_write` / `shell_exec`
- 所有副作用保留 `approval_*` + `tool_call_*`

先读：
- `references/recipes-index.md`
- `references/testing-strategy.md`

### 路由 B：Skills-First 业务能力

适用：
- 需要把能力打包为可复用 skill
- 需要 mention 注入、`skill_ref_read`、`skill_exec`

做法：
- 先配 `skills.spaces` + `skills.sources`
- mention 必须使用唯一合法格式：`$[namespace].skill_name`
- `references` / `actions` 默认关闭，只有明确需要时再开启
- 先跑 `skills preflight`，再跑 `skills scan`
- 如果要落 `skill_exec`，先在 skill frontmatter 明确声明 `actions`

先读：
- `references/config-templates.md`
- `references/recipes-index.md`

### 路由 C：固定角色多 agent 流水线

适用：
- Analyze → Patch → QA → Report
- Planner → Worker → Reporter
- 角色固定、数量稳定

做法：
- 用 `Coordinator`
- 每个角色能力先沉淀成独立 skill
- 主任务文本显式带 mention，确保出现 `skill_injected`

先读：
- `references/api-cheatsheet.md`
- `references/recipes-index.md`

### 路由 D：动态子任务 / 并行协作

适用：
- 子任务数量不固定
- 运行中途需要追加输入
- 需要 `spawn_agent` / `send_input` / `wait`

做法：
- 用 collab primitives，不要硬套 `Coordinator`
- `spawn_agent` / `send_input` / `close_agent` 一般都要纳入审批治理
- 子 agent 仍然要 Skills-First，各自维护独立 WAL

先读：
- `references/api-cheatsheet.md`
- `references/safety-and-sandbox.md`
- `references/recipes-index.md`

### 路由 E：长任务 / 等待人工 / 可恢复执行

适用：
- `request_user_input`
- `ask_human`
- `waiting_human` 暂停恢复
- WAL replay / fork / resume
- exec sessions 工程式交互

做法：
- 先明确终态和恢复语义
- `waiting_human` 不是失败态，必须单独处理
- 长会话默认带 WAL、审批策略和超时/恢复策略

先读：
- `references/api-cheatsheet.md`
- `references/testing-strategy.md`

## Skills 落地检查清单

1. skill 目录结构最小形态：
   - `skills/<skill_name>/SKILL.md`
   - `references/` 只放需要被读取的材料
   - `actions/` 只放明确允许 `skill_exec` 调用的脚本
2. 任务文本必须带 mention：
   - 正确：`$[biz:myapp].order-summarizer`
3. 先做 CLI 校验：

```bash
skills-runtime-sdk skills preflight --workspace-root . --config config/runtime.yaml --pretty
skills-runtime-sdk skills scan --workspace-root . --config config/runtime.yaml --pretty
```

4. 只有在 overlay 显式开启时才用：
   - `skills.references.enabled=true`
   - `skills.actions.enabled=true`

5. `skill_exec` 的最小 frontmatter 例子：

```yaml
---
name: artifact_builder
description: "动作型 skill：执行 actions/ 中声明的脚本。"
actions:
  build:
    kind: shell
    argv: ["python3", "actions/build_artifact.py"]
    timeout_ms: 5000
    env:
      ARTIFACT_KIND: "demo"
---
```

## Agent / Workflow 落地检查清单

1. 固定角色协作优先 `Coordinator`
2. 动态并发/补充输入优先 collab primitives
3. 默认使用 `AgentBuilder` 组装生产级能力：
   - backend
   - WAL
   - approval provider
   - hooks
4. 人工介入流程必须检查：
   - `waiting_human`
   - `run_waiting_human`
   - resume / replay / fork
5. 交付必须至少给出一条可运行回归命令

## 证据与完成定义

业务交付至少要有：
1. 可运行入口：`run.py` 或等价主入口
2. 最小 overlay：不写死 secrets，只声明 `llm.api_key_env`
3. 离线回归：`FakeChatBackend` + 最小 smoke tests
4. WAL 证据：
   - `run_started`
   - `tool_call_*`
   - `approval_*`（如有副作用）
   - `skill_injected` / `plan_updated` / `human_request` / `human_response`（按场景）
   - `run_completed` / `run_failed` / `run_cancelled` / `run_waiting_human`

## 常见误区

| 误区 | 正解 |
|------|------|
| 直接默认联网克隆仓库 | 先定位本地仓库；已有本地仓库时不要重新克隆 |
| 只写 agent，不写 skill | 复杂项目先定 skill 边界，再写编排 |
| 把 `waiting_human` 当成失败 | 它是可恢复暂停态 |
| 默认放开所有工具审批 | 无人值守优先规则审批，默认 fail-closed |
| `skill_ref_read` / `skill_exec` 直接用 | 必须先显式开启 references/actions |
| 只看最终输出，不看 WAL | 副作用链路必须可审计、可回放 |

## 本地参考导航

- API 与状态/事件：`references/api-cheatsheet.md`
- 配置模板：`references/config-templates.md`
- 场景配方：`references/recipes-index.md`
- 安全/审批/沙箱：`references/safety-and-sandbox.md`
- 测试与验证：`references/testing-strategy.md`
- 仓库事实快照：`references/repo-reading-map.md`
