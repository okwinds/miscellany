# API 速查（capability-runtime 公共 API）

## 总原则

- 业务代码只从 `capability_runtime` 包根导入公共 API
- 不依赖深路径 import
- `Runtime` 是默认执行入口

## Core

```python
from capability_runtime import Runtime, RuntimeConfig, CustomTool
```

- `Runtime(config: RuntimeConfig)`：构造运行时
- `rt.register(spec)`：注册单个 capability
- `rt.register_many([spec1, spec2])`：批量注册 capability
- `rt.validate() -> list[str]`：校验依赖；空列表表示通过
- `await rt.run(capability_id, input=..., context=...) -> CapabilityResult`
- `async for item in rt.run_stream(capability_id, input=..., context=...): ...`

## RuntimeConfig 关键字段

```python
RuntimeConfig(
    mode="mock" | "bridge" | "sdk_native",
    workspace_root=Path(...),
    sdk_config_paths=[Path(...)],
    sdk_backend=...,
    preflight_mode="off" | "warn" | "error",
    approval_provider=...,
    custom_tools=[CustomTool(...)],
    skills_config=dict | None,
    in_memory_skills=dict | None,
    exec_sessions=...,
    collab_manager=...,
    wal_backend=...,
    runtime_client=...,
    runtime_server=...,
    mock_handler=...,
)
```

## Capability Protocol

```python
from capability_runtime import (
    CapabilitySpec,
    CapabilityKind,
    CapabilityRef,
    CapabilityResult,
    CapabilityStatus,
    AgentSpec,
    AgentIOSchema,
    WorkflowSpec,
    Step,
    LoopStep,
    ParallelStep,
    ConditionalStep,
    InputMapping,
    ExecutionContext,
)
```

### 关键约束

- `AgentSpec(skills=[...])` 是 skills-first 的默认承载方式
- `WorkflowSpec` 只编排 `Agent / Workflow`
- `InputMapping` 必须显式给出：
  - `source`
  - `target_field`
- `Step` 使用 `input_mappings=[...]`
- `LoopStep` 使用 `item_input_mappings=[...]`
- `ConditionalStep` 当前是：
  - `condition_source`
  - `branches`
  - `default`

### InputMapping.source 常用前缀

| 前缀 | 含义 | 示例 |
|---|---|---|
| `context.*` | 初始输入 / 执行上下文 | `context.user_input` |
| `previous.*` | 上一步输出 | `previous.output` |
| `step.<id>.*` | 指定步骤输出 | `step.plan.items` |
| `item.*` | LoopStep 当前迭代项 | `item.name` |
| `literal.*` | 字面量 | `literal.ready` |

## Structured Output

- `await rt.run_structured(...)`：只支持带 `output_schema` 的 `AgentSpec`
- `async for ev in rt.run_structured_stream(...):`：结构化流式消费
- 对 `WorkflowSpec` 不能直接调用 `run_structured()` 期待强结构结果

## Evidence / Host Surfaces

```python
from capability_runtime import (
    NodeReport,
    NodeResult,
    ApprovalTicket,
    ResumeIntent,
    HostRunSnapshot,
    RuntimeServiceFacade,
    RuntimeServiceRequest,
    RuntimeServiceHandle,
    RuntimeSession,
)
```

### 常用 host-facing 方法

- `rt.describe_capability(capability_id)`
- `rt.list_capabilities(...)`
- `rt.register_with_manifest(spec, entry=...)`
- `rt.build_approval_ticket(result, capability_id=...)`
- `rt.summarize_host_run(result, capability_id=...)`
- `rt.build_resume_intent(run_id=..., approval_key=..., decision=...)`

## Host Toolkit

```python
from capability_runtime import (
    InvokeCapabilityAllowlist,
    make_invoke_capability_tool,
)
```

用途：

- 把子 Agent / 子 Workflow 委托纳入 tool evidence
- 保持对外 capability 仍然是 `Agent / Workflow`

## Errors

```python
from capability_runtime import (
    RuntimeFrameworkError,
    CapabilityNotFoundError,
)
```

不要假设还有其他公共错误导出名。
