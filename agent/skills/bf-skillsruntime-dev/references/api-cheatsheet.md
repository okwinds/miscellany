# Python API 速查

> 本页是按 2026-04-02 的仓库事实整理的本地快照。

## 推荐导入

```python
from pathlib import Path

from skills_runtime.agent import Agent
from skills_runtime import AgentBuilder, Coordinator
from skills_runtime.llm.fake import FakeChatBackend, FakeChatCall
from skills_runtime.llm.chat_sse import ChatStreamEvent
from skills_runtime.llm.openai_chat import OpenAIChatCompletionsBackend
from skills_runtime.config.loader import AgentSdkLlmConfig
from skills_runtime.safety import ApprovalRule, RuleBasedApprovalProvider
from skills_runtime.safety.approvals import ApprovalProvider, ApprovalDecision, ApprovalRequest
from skills_runtime.tools.protocol import ToolCall, ToolResult, ToolResultPayload, ToolSpec, HumanIOProvider
from skills_runtime.state.wal_protocol import InMemoryWal
from skills_runtime.core.contracts import AgentEvent
```

说明：
- `Agent`：推荐从 `skills_runtime.agent` 导入
- `AgentBuilder` / `Coordinator`：推荐从包根 `skills_runtime` 导入
- 包根同样导出 `Agent`，但本技能默认把 `Agent` 与 `AgentBuilder` 分开写，减少歧义

## Agent 构造

### 最小构造

```python
agent = Agent(workspace_root=Path(".").resolve(), backend=backend)
```

### AgentBuilder（推荐）

```python
agent = (
    AgentBuilder()
    .workspace_root(Path(".").resolve())
    .backend(backend)
    .wal_backend(InMemoryWal())
    .approval_provider(provider)
    .event_hooks([hook_fn])
    .build()
)
```

## 运行方式

```python
# 同步
result = agent.run("任务描述")
print(result.status, result.final_output, result.wal_locator)

# 流式
for event in agent.run_stream("任务描述"):
    print(event.type, event.payload)

# 异步流式
async for event in agent.run_stream_async("任务描述"):
    print(event.type)
```

### 当前 `RunResult.status`

- `completed`
- `failed`
- `cancelled`
- `waiting_human`

注意：
- `waiting_human` 是可恢复暂停态，不要和 `failed` 混用

## 关键事件族

### run 级事件

- `run_started`
- `run_completed`
- `run_failed`
- `run_cancelled`
- `run_waiting_human`

### LLM / tools / approvals / skills / human

- `llm_request_started`
- `llm_response_received`
- `tool_call_requested`
- `tool_call_started`
- `tool_call_finished`
- `approval_requested`
- `approval_decided`
- `skill_injected`
- `plan_updated`
- `human_request`
- `human_response`

## 自定义工具

### Decorator 方式

```python
@agent.tool
def my_tool(arg: str) -> str:
    return f"Result: {arg}"
```

### ToolSpec + handler

```python
spec = ToolSpec(
    name="hello_tool",
    description="返回问候语",
    parameters={"type": "object", "properties": {}, "required": [], "additionalProperties": False},
)

def handler(call: ToolCall, _ctx) -> ToolResult:
    payload = ToolResultPayload(ok=True, stdout="hi", exit_code=0, data={"result": "hi"})
    return ToolResult.from_payload(payload)

agent.register_tool(spec, handler, override=False)
```

## 审批提供者

### 规则审批（推荐）

```python
provider = RuleBasedApprovalProvider(
    rules=[
        ApprovalRule(tool="shell_exec", decision=ApprovalDecision.DENIED),
        ApprovalRule(
            tool="shell_exec",
            condition=lambda req: (req.details.get("argv") or [None])[0] == "pytest",
            decision=ApprovalDecision.APPROVED,
        ),
    ],
    default=ApprovalDecision.DENIED,
)
```

### Scripted approval（离线回归）

```python
class ScriptedApproval(ApprovalProvider):
    def __init__(self, decisions):
        self._decisions = iter(decisions)

    async def request_approval(self, *, request: ApprovalRequest, timeout_ms=None):
        _ = request
        _ = timeout_ms
        return next(self._decisions, ApprovalDecision.DENIED)
```

## Human I/O

```python
class ScriptedHumanIO(HumanIOProvider):
    def __init__(self, answers_by_question_id):
        self._answers = answers_by_question_id

    async def request_input(self, *, question_id, prompt, **kw):
        _ = prompt
        _ = kw
        return self._answers.get(question_id, "")
```

## LLM Backend

### Fake（离线）

```python
backend = FakeChatBackend(calls=[
    FakeChatCall(events=[
        ChatStreamEvent(type="text_delta", text="EXAMPLE_OK: done."),
        ChatStreamEvent(type="completed", finish_reason="stop"),
    ])
])
```

### OpenAI-compatible（真模型）

```python
llm_cfg = AgentSdkLlmConfig(
    base_url="https://api.openai.com/v1",
    api_key_env="OPENAI_API_KEY",
    timeout_sec=60,
    retry={"max_retries": 3, "base_delay_sec": 0.5, "cap_delay_sec": 8.0, "jitter_ratio": 0.1},
)
backend = OpenAIChatCompletionsBackend(llm_cfg)
```

## 多 agent 两条路线

### 固定角色：`Coordinator`

适用：
- Analyze → Patch → QA → Report
- 角色数量固定，编排结构稳定

要点：
- `ChildResult.status` 同样可能是 `waiting_human`
- 适合把角色能力做成稳定 skill 组合

最小模板：

```python
from skills_runtime.agent import Agent
from skills_runtime import Coordinator

primary = Agent(workspace_root=Path(".").resolve(), backend=backend)
reviewer = Agent(workspace_root=Path(".").resolve(), backend=backend)
fixer = Agent(workspace_root=Path(".").resolve(), backend=backend)
qa = Agent(workspace_root=Path(".").resolve(), backend=backend)

coord = Coordinator(agents=[primary, reviewer, fixer, qa])
result = coord.run_with_child(
    "请汇总 reviewer 的结论并继续完成主任务。",
    child_task="$[biz:app].repo_reviewer\\n请先做只读审查。",
    child_index=1,
)
print(result.status, result.wal_locator)
```

### 动态协作：collab primitives

相关工具：
- `spawn_agent`
- `wait`
- `send_input`
- `close_agent`
- `resume_agent`

适用：
- 子任务数量动态变化
- 中途需要追加输入
- 需要跨进程托管 exec / collab 状态

常见任务文本形态：

```text
$[biz:app].master_planner
请拆成 3 个子任务，并用 spawn_agent / send_input / wait 管理执行。
```

## 当前 builtin tools 概览

- 执行：`shell_exec` / `shell` / `shell_command` / `exec_command` / `write_stdin`
- 文件：`file_read` / `file_write` / `read_file` / `list_dir` / `grep_files` / `apply_patch`
- 交互：`ask_human` / `request_user_input` / `update_plan`
- Skills：`skill_exec` / `skill_ref_read`
- 其他：`view_image` / `web_search`
- 协作：`spawn_agent` / `wait` / `send_input` / `close_agent` / `resume_agent`

## CLI 入口

以下两种入口都有效：

```bash
skills-runtime-sdk --help
python3 -m skills_runtime.cli.main --help
```
