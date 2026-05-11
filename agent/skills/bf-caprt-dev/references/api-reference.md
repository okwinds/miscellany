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
    PromptRenderMode,
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
- `AgentSpec.prompt_render_mode` 默认为 `structured_task`，可选 `direct_task_text` / `precomposed_messages`
- `AgentSpec.prompt_profile` 用于透传 SDK prompt profile，常用 `generation_direct` / `structured_transform`
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

## Prompt Rendering

```python
from capability_runtime import AgentSpec, PromptRenderMode
```

### 模式

- `structured_task`：默认兼容路径；Runtime 把 `AgentSpec` + 业务 `input` 渲染成结构化 task 文本。
- `direct_task_text`：host 在 `input["_runtime_prompt"]["task_text"]` 提供最终 task 文本。
- `precomposed_messages`：host 在 `input["_runtime_prompt"]["messages"]` 提供最终 provider messages。

### 控制面

`_runtime_prompt` 是保留运行时控制面，不是业务输入字段。支持：

- `mode`：run-level 覆盖 `AgentSpec.prompt_render_mode`
- `profile`：run-level 覆盖 `AgentSpec.prompt_profile`
- `task_text`：`direct_task_text` 的最终 task
- `messages`：`precomposed_messages` 的最终 provider messages
- `trace.prompt_hash`：`sha256:<64 lowercase hex>` 摘要
- `trace.composer_version`：prompt composer 版本摘要

`precomposed_messages` 的 messages 每项必须有合法 role，`content` 可以是字符串或 v1 稳定 content parts：

```python
{"role": "system" | "user" | "assistant" | "tool", "content": "..."}

{"role": "user", "content": [
    {"type": "text", "text": "Compare these images."},
    {"type": "image_url", "image_url": {"url": "https://example.test/a.png", "detail": "auto"}},
    {"type": "image_url", "image_url": {"url": "https://example.test/b.png"}},
]}
```

### 多模态 content parts

`precomposed_messages` 是 host-controlled boundary：Runtime 校验、canonicalize、摘要和转发 messages，但不下载、转码、OCR、ASR、视频解码、抽帧、托管或持久化媒体。

v1 稳定支持的 content parts：

- `{"type": "text", "text": str}`
- `{"type": "image_url", "image_url": {"url": str, "detail"?: "auto" | "low" | "high"}}`

关键规则：

- `content` 为 list 时不能为空。
- `text.text` 必须是字符串，允许空字符串。
- `image_url.url` 必须是非空字符串；Runtime 不校验 URL 可达性。
- `image_url.detail` 如存在，只能是 `auto`、`low` 或 `high`。
- 允许多个 `image_url` parts；也允许 image-only content list。
- 未知 part type、未知字段、非 JSON-compatible message 值、非有限数字（如 `NaN`）应 fail-fast 为 `INVALID_PROMPT_MESSAGES`。
- `input_audio`、`file`、`video` 等 provider-specific parts 不属于 v1 contract；如果业务需要视频 vision，先在 host / application 层抽帧为多张 `image_url`，或补新的显式 Runtime contract，不要依赖 passthrough。

`NodeReport.meta` 只记录 prompt evidence 摘要字段，例如 `prompt_render_mode`、`prompt_profile`、`prompt_hash`、message count/roles、composer version，以及多模态摘要：

- `prompt_modalities`
- `prompt_content_part_counts`
- `prompt_media_count`

不要记录完整 prompt 明文、完整 `messages[]`、URL、base64、媒体正文、`tool_calls` 或 `tool_call_id`。

多模态输出继续使用既有 artifact locators：

- `CapabilityResult.artifacts: list[str]`
- `NodeReport.artifacts: list[str]`

Runtime 不新增平行的 binary output 字段。

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
