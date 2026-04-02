# 模式 Cookbook（capability-runtime 常见开发模式）

## 模式 1：skills-first 结构化 Agent

适用：

- 业务能力主要来自 Skills
- 需要稳定 JSON 输出
- 需要保留 `NodeReport` 作为证据

```python
from capability_runtime import (
    AgentIOSchema,
    AgentSpec,
    CapabilityKind,
    CapabilitySpec,
    CapabilityStatus,
    ExecutionContext,
    Runtime,
    RuntimeConfig,
)

agent = AgentSpec(
    base=CapabilitySpec(
        id="agent.qa.quality_check",
        kind=CapabilityKind.AGENT,
        name="QualityCheck",
        description="客服对话质检",
    ),
    skills=["qa_checker"],
    output_schema=AgentIOSchema(
        fields={
            "conversation_id": "str",
            "overall_score": "float",
            "passed": "bool",
        },
        required=["conversation_id", "overall_score", "passed"],
    ),
)

rt = Runtime(
    RuntimeConfig(
        mode="sdk_native",
        workspace_root=workspace_root,
        sdk_backend=backend,
        preflight_mode="off",
    )
)
rt.register(agent)
assert rt.validate() == []

ctx = ExecutionContext(run_id="qa_demo_001", max_depth=10)
result = await rt.run_structured("agent.qa.quality_check", input=input_data, context=ctx)
assert result.status == CapabilityStatus.SUCCESS
assert result.node_report is not None
```

## 模式 2：Workflow 编排 skills-first Agent

适用：

- Skills 用来承载业务能力
- Agent 是运行单元
- Workflow 负责编排多个 Agent

```python
from capability_runtime import (
    AgentSpec,
    CapabilityKind,
    CapabilityRef,
    CapabilitySpec,
    InputMapping,
    Runtime,
    RuntimeConfig,
    Step,
    WorkflowSpec,
)

draft = AgentSpec(
    base=CapabilitySpec(id="agent.draft", kind=CapabilityKind.AGENT, name="Draft"),
    skills=["writer"],
)
review = AgentSpec(
    base=CapabilitySpec(id="agent.review", kind=CapabilityKind.AGENT, name="Review"),
    skills=["reviewer"],
)

workflow = WorkflowSpec(
    base=CapabilitySpec(id="wf.skills_first", kind=CapabilityKind.WORKFLOW, name="SkillsFirstWorkflow"),
    steps=[
        Step(id="draft", capability=CapabilityRef(id="agent.draft")),
        Step(
            id="review",
            capability=CapabilityRef(id="agent.review"),
            input_mappings=[InputMapping(source="step.draft", target_field="draft")],
        ),
    ],
    output_mappings=[
        InputMapping(source="step.draft", target_field="draft"),
        InputMapping(source="step.review", target_field="review"),
    ],
)

rt = Runtime(RuntimeConfig(mode="sdk_native", workspace_root=workspace_root, sdk_backend=backend))
rt.register_many([draft, review, workflow])
assert rt.validate() == []
result = await rt.run("wf.skills_first", input={})
assert result.node_report is not None
```

### Conditional / Loop 正确写法

```python
from capability_runtime import CapabilityRef, ConditionalStep, InputMapping, LoopStep, Step

loop = LoopStep(
    id="process_items",
    capability=CapabilityRef(id="agent.processor"),
    iterate_over="step.plan.items",
    item_input_mappings=[InputMapping(source="item", target_field="item")],
)

route = ConditionalStep(
    id="route",
    condition_source="step.plan.next_action",
    branches={
        "review": Step(id="review", capability=CapabilityRef(id="agent.review")),
        "publish": Step(id="publish", capability=CapabilityRef(id="agent.publish")),
    },
    default=Step(id="fallback", capability=CapabilityRef(id="agent.fallback")),
)
```

## 模式 3：invoke_capability 子能力委托

适用：

- 一个 Agent 在运行中需要调用子 Agent / 子 Workflow
- 希望子调用进入 tool evidence，而不是绕开 Runtime

```python
from capability_runtime import InvokeCapabilityAllowlist, Runtime, RuntimeConfig, make_invoke_capability_tool
from dataclasses import replace

child_cfg = replace(parent_cfg, sdk_backend=child_backend, custom_tools=[])

invoke_tool = make_invoke_capability_tool(
    child_runtime_config=child_cfg,
    child_specs=[child_agent_spec],
    allowlist=InvokeCapabilityAllowlist(allowed_ids=["child.echo"]),
    requires_approval=True,
)

rt = Runtime(
    RuntimeConfig(
        mode="sdk_native",
        workspace_root=workspace_root,
        sdk_backend=parent_backend,
        custom_tools=[invoke_tool],
    )
)
```

验收要点：

- `result.node_report.tool_calls` 中能看到 `invoke_capability`
- 子调用失败 / 超时要在 tool evidence 中可见

## 模式 4：waiting-human / approval / resume

适用：

- 下游宿主需要统一 waiting-human 终态
- 需要审批票据和 resume intent

```python
from capability_runtime import HostRunStatus

result = await rt.run("agent.review", input=payload)
snapshot = rt.summarize_host_run(result, capability_id="agent.review")

if snapshot.status == HostRunStatus.WAITING_HUMAN:
    ticket = rt.build_approval_ticket(result, capability_id="agent.review")
    intent = rt.build_resume_intent(
        run_id=snapshot.run_id,
        approval_key=ticket.approval_key if ticket else None,
        decision="approved",
        session_id="session-001",
        host_turn_id="turn-001",
    )
```

验收要点：

- 程序判断基于 `snapshot.status` / `ApprovalTicket`
- 不从自由文本解析“是否等待审批”

## 模式 5：RuntimeServiceFacade / RuntimeSession

适用：

- 需要 service 化调用入口
- 需要 session continuity / host turn 透传

```python
from capability_runtime import RuntimeServiceFacade, RuntimeServiceRequest, RuntimeSession

facade = RuntimeServiceFacade(rt)

request = RuntimeServiceRequest(
    capability_id="agent.qa.quality_check",
    input=input_data,
    session=RuntimeSession(
        session_id="session-qa-001",
        host_turn_id="turn-001",
        history=[{"role": "user", "content": "上次沟通继续"}],
    ),
)

result = await facade.run(request)
```

验收要点：

- 需要 continuity 时才引入 `RuntimeSession`
- 不把 service façade 当作普通业务任务的默认起点

## 模式 6：模式升级顺序

推荐顺序：

1. `mock`
2. `sdk_native`
3. `bridge`

对应目标：

- `mock`：先锁注册、依赖、Workflow 结构
- `sdk_native`：再锁 Skills / tools / approvals / WAL / NodeReport
- `bridge`：最后锁真实模型与传输
