---
name: bf-caprt-dev
version: 0.1.1
description: "指导编码智能体以 capability-runtime 为业务落地入口，交付基于 capability-runtime 的 skills / agents / workflows，并在 Greenfield 或 Legacy Convergence 场景下优先使用 Runtime public surface、structured output、NodeReport、host summary 与 service/session surfaces。只要任务目标是用 capability-runtime / capability_runtime 落地业务代码、收敛下游 runtime boundary，或涉及 Runtime.run / Runtime.run_stream / run_structured / run_structured_stream / AgentSpec / PromptRenderMode / prompt_render_mode / _runtime_prompt / precomposed_messages / multimodal / vision / image input / 多图输入 / 视频抽帧输入 / OpenAI-compatible messages / image_url content parts / WorkflowSpec / NodeReport / RuntimeServiceFacade / describe_capability / summarize_host_run，就应优先使用本技能。不要用于普通通用编码、prompt-only 任务、直接学习上游原生框架 API，或任何明确要求“直接用 skills-runtime-sdk / Agently / provider SDK，不走 capability-runtime”的任务；若已触发但随后识别出这是反目标，必须立即退出，并停止提供任何上游实现细节、伪代码或 API 猜测。"
compatibility: "技能事实库必须自包含：只允许引用当前技能目录内的 references/ 与 evals/。如需新增事实材料，先复制到技能目录再引用。执行 capability-runtime 相关开发时，需要 Python 3 与可导入的 capability_runtime 环境；默认可直接从 PyPI 安装 `capability-runtime`，本地源码开发或 monorepo 场景再使用 editable install / PYTHONPATH。目标仓库源码应位于本地工作区；真实 bridge 场景需要完整运行环境。"
---

# bf-caprt-dev

## 定位

本技能用于指导编码智能体通过 `capability-runtime` 落地业务能力，而不是绕过它去直接拼接上游框架。

默认心智模型：

`skill / agent / workflow -> Runtime public surface -> NodeReport / host summary / service surfaces`

### 自包含约束

本技能是一个自包含技能：

- 只允许引用当前技能目录内的 `references/` 与 `evals/`
- 不允许把 `docs/`、`examples/`、`tests/`、`help/`、`README.md` 等外部仓库路径写成技能依赖
- 如需补充 capability-runtime 的新事实，先复制或整理到本技能目录，再在技能正文中引用

## 开场动作

1. 先确认当前 Python 环境是否已经可导入 `capability_runtime`。
2. 若还不能导入，优先使用 PyPI 安装；只有本地源码开发或 monorepo 场景，才改用 editable install。
3. 只在临时验证时使用 `PYTHONPATH` 兜底，不要把它当长期交付方案。
4. 能导入之后再继续看 `references/triad-and-routing.md` 与 `references/api-reference.md`，不要一边猜环境一边写业务代码。

## 本地环境准备

如果是本地源码开发，再记本地仓库目录为 `CAPRT_REPO_ROOT`：

```bash
export CAPRT_REPO_ROOT=/abs/path/to/capability-runtime
```

先做 import 预检：

```bash
python3 -c "import capability_runtime; print('capability_runtime import ok')"
```

如果导入失败，优先使用 PyPI 安装：

```bash
pip install capability-runtime
```

如果你正在改本地源码，或仓库是 monorepo / 需要跟随未发布改动，再对**包含 `pyproject.toml` 的本地源码目录**做 editable install：

```bash
pip install -e "$CAPRT_REPO_ROOT"
```

如果仓库是 monorepo，`pyproject.toml` 不在根目录，就把上面的路径改成实际 Python 包目录。

只做临时验证时，才使用 `PYTHONPATH` 兜底：

```bash
export PYTHONPATH="$CAPRT_REPO_ROOT${PYTHONPATH:+:$PYTHONPATH}"
python3 -c "import capability_runtime; print('capability_runtime import ok')"
```

继续前，至少完成一个 smoke check：

```bash
python3 -c "from capability_runtime import Runtime, RuntimeConfig; print('caprt api ok')"
```

## 何时使用

当任务目标符合下面任一情形时，优先使用本技能：

- 用 `capability-runtime` 新建业务 capability、agent、workflow、service 接口或离线回归样例
- 把已有业务 skills、Agent 壳、Workflow 编排统一收敛到 Runtime public surface
- 需要 `Runtime.run()` / `run_stream()` / `run_structured()` / `run_structured_stream()`
- 需要 `NodeReport`、descriptor、host summary 作为程序判断或审计真相源
- 需要 `RuntimeServiceFacade` / `RuntimeSession` 做 service/session continuity 落地
- 需要 `invoke_capability`、approval/waiting-human、resume、legacy host convergence

### 不要使用

下面这些情况不应触发本技能：

- 普通通用编码，与 capability-runtime 无关
- 只改 prompt，不关心 Runtime、测试、注册、NodeReport 或执行链路
- 想直接学习上游原生框架 API，例如 Agently/TriggerFlow 的原生写法
- 明确要求绕过 capability-runtime，直接把 provider SDK 或上游框架接进业务主流程
- 明确要求“直接用 `skills-runtime-sdk` / `Agently` / provider SDK 完成业务”，并且不需要 `AgentSpec` / `WorkflowSpec` / `Runtime`

## 退出规则

如果用户已经明确否定 `capability-runtime` 入口，本技能必须退出，而不是顺着给上游最短路径。

典型信号：

- “不要 capability-runtime，只要上游”
- “直接用 skills-runtime-sdk 跑业务”
- “直接用 Agently / TriggerFlow 原生写法，不要 Runtime”
- “直接接 provider SDK，别走 capability-runtime”

退出时必须收敛成两句：

1. 边界判断：这不属于 `bf-caprt-dev`，因为用户已明确不要 `capability-runtime`
2. 改派建议：只说明更适合的技能或任务类别，例如：
   - `bf-skillsruntime-dev`
   - `agently-*`
   - `prompt-engineering`
   - 普通通用编码

禁止出现：

- 上游 SDK 的 import 示例
- 上游最短路径伪代码
- “根据记忆推测” 的 API 用法
- 任何继续顺着用户要求展开的实现步骤

## 先判两件事

在写代码前先判断两条轴线：

### 1. 任务背景

- `Greenfield`
  - 新建能力或新建编排，没有沉重的历史 boundary 包袱
- `Legacy Convergence`
  - 下游已经有 runtime boundary、task stream、approval API、registry façade、workflow slice、service façade 或 session continuity，需要把内部真相源收敛到 capability-runtime

无法判断时，先按 `Legacy Convergence` 处理，因为它更保守。

### 2. 当前主焦点

- `Capability 建模`
  - 决定 skill / agent / workflow 分工
- `Workflow 编排`
  - 组织多个 capability 的数据流与调用顺序
- `Structured Output`
  - 重点是 `run_structured()` / `run_structured_stream()`
- `Prompt Rendering`
  - 重点是 `AgentSpec.prompt_render_mode` / `prompt_profile` 与 run-level `_runtime_prompt`
- `Multimodal Prompt Boundary`
  - 重点是 `precomposed_messages`、OpenAI-compatible content parts、vision 输入与 evidence 最小披露
- `Host Convergence`
  - descriptor、host summary、approval/resume、service/session
- `Bridge 接线`
  - 真实模型接线与传输兼容

默认路由顺序：

`Capability 建模 -> 执行入口 -> 证据链 -> Host / Service Convergence -> Bridge`

不要一开始就跳到 bridge。

## 关键红线与边界原则

### 1. 业务代码不得绕过 capability-runtime

无论内部桥接依赖什么，业务主流程都不得直接调用底层上游框架来代替 `capability-runtime`。

需要直出生成、低噪音 prompt 或预组装 provider messages 时，也仍然通过 `Runtime.run()` / `run_stream()`，使用 `AgentSpec.prompt_render_mode` 与 `_runtime_prompt` 控制输入形态。

多模态不是绕过 `capability-runtime` 的理由。vision、图片、多图、视频抽帧等需求仍应先判断能否通过 `precomposed_messages` 进入 Runtime public surface，而不是把业务 handler、前端或 worker 改成 provider SDK 直连。

### 2. 不得把 Workflow 写成直接编排 Skill 节点

Workflow 编排的是 `Agent / Workflow`。
skill 是能力素材与能力来源，不是 Workflow 的对外原语。

### 3. Legacy 任务不得擅自改 outward-facing contract

如果下游已经存在：

- task stream
- approval API
- workflow slice / replay / continue
- service façade / session continuity contract
- DB / Redis 持久化 schema
- projector / task event 协议

除非用户明确授权，否则不要改这些表面；先做内部真相源收敛。

### 4. runtime output envelope 先 normalize，再 validate

当 structured output 出现“字段看起来缺失、但原始 payload 里似乎还有内容”时，先把它当成 **output envelope 不稳定** 处理，而不是立刻判定模型没给数据。

典型 envelope 形态包括：

- `output / result / payload / data` 这类单层或多层包裹
- `text + structured payload` 并存
- 前缀说明文字 + JSON / dict 正文
- host / adapter / transport 附带元信息，再把真正结构化结果包在内部

默认顺序：

1. 对原始 payload 做无损扫描
2. 先识别 envelope 层和宿主附带元信息
3. 抽出最可能的 canonical structured candidate
4. 对等价字段、错误层级、历史别名做 lossless normalize
5. 再做 validate / coverage / completeness / degraded 判定
6. 只有 normalize 后仍缺失，才允许 retry、fallback 或 estimated

一句话原则：

- **先把 output envelope 解开，再判断 contract 是否真的缺失。**

### 5. 生成型 capability 仍以 Runtime 为入口

当 capability 的核心价值来自 LLM 生成内容时，不要把“低噪音 prompt”误解为绕过 Runtime。可以由 host / composer / application 预组装最终 provider messages，但业务执行入口仍应通过 `Runtime.run()`、`run_stream()`、`run_structured()` 或 `run_structured_stream()`。

通用要求：

- `AgentSpec` 描述可执行 capability；skill 是能力素材，不是业务对外执行入口。
- `_runtime_prompt` 或等价 run-level prompt override 是输入形态控制面，不是替代 Runtime 的外部执行框架。
- prompt render trace 应用于审计与回放；不应泄露到模型可见正文，除非这是明确的业务输入。
- skill / prompt asset 可以来自生态或上游，但进入生产 runtime 前应有可解析 contract 或结构化说明，避免业务代码只依赖一大段 prompt 文本。
- 若下游需要最终 provider messages 取证，优先通过 Runtime host summary、NodeReport、run metadata 或业务 host trace 暴露，而不是绕到底层 provider client。

数据面提醒：

- Runtime 只保证能力执行与边界稳定，不自动保证生成内容质量。
- 生成型 capability 应让业务层定义 output contract、field semantics、quality baseline、golden fixtures 或 semantic gates。
- 不要把“structured output 可解析”误判为“用户价值达标”；用户可见内容、报告、脚本、建议、分析等仍需要领域质量验收。

运行态提醒：

- AgentSpec 注册、`prompt_profile` 设置或 `_runtime_prompt` 支持存在，只能证明代码路径具备能力，不自动证明部署环境已经启用。
- 生成型 capability 上线前，应核对 effective deployment config：默认配置、部署清单 / compose / helm fallback、环境变量覆盖、运行中进程环境和必要的 scoped restart。
- 如果宿主有 allowlist / feature flag / prompt mode 开关，分别确认 runtime 路由开关与 prompt composer 开关；不要用一个开关替代另一个开关的语义。
- 真实 provider prompt capture 是生成型 runtime 接线的重要验收证据；没有 capture 时，只能说“代码具备路径”，不要说“模型已经吃到优化 prompt”。

### 6. 多模态输入是 host-controlled prompt boundary，不是 provider passthrough 口子

当任务涉及 vision、图片、多图、视频帧、OpenAI-compatible messages 或多模态 chatbot 时，默认路线是：

1. 用 `AgentSpec(prompt_render_mode="precomposed_messages")` 描述可执行 capability；
2. 由 host / application 在 `input["_runtime_prompt"]["messages"]` 提供最终 messages；
3. 通过 `Runtime.run()` / `run_stream()` 执行，保留 Runtime events、WAL、NodeReport、host summary 与 output validation；
4. 在 `NodeReport.meta` 只暴露安全摘要，不记录完整 prompt、messages、URL、base64 或媒体正文。

当前 v1 稳定多模态输入只接受 `text` 与 `image_url` content parts。允许多张图片、image-only content list，以及把单个视频在 host / frontend / application 层抽成多张代表帧后作为多个 `image_url` parts 传入。

不要把 `input_audio`、`file`、`video` 或 provider-specific content parts 当作可偷渡 passthrough；如果业务确实需要这些形态，先把它登记为新的显式 runtime contract，而不是绕开 `capability-runtime`。

Runtime 在这条边界上只负责校验、canonicalize、转发与 evidence 摘要；它不负责下载、转码、OCR、ASR、视频解码、抽帧、文件托管或媒体持久化。多模态输出仍使用既有 artifact locator：`CapabilityResult.artifacts` / `NodeReport.artifacts`，不要新造平行 binary output 字段。

### 7. usage metadata 是下游审计证据，不要在 host 边界丢失

当 `NodeReport.usage` 或等价 host summary 暴露 `request_id`、`provider`、token 数、模型名等字段时，下游 runtime boundary 应无损透传这些字段。尤其是网关型 provider 场景里，gateway/carrier request id 与上游模型 provider request id 可能同时存在；不要把辅助 provider id 冒充成 carrier-owned canonical id，也不要因为结构化 output 已成功就丢掉 usage metadata。

如果下游 billing、audit、cost reporting 或 replay 依赖 request id，要在 adapter / projector / worker 三层分别写回归测试：adapter 保留字段，projection 继续透传，最终 observation / audit store 能读取到该字段。

## 默认业务主路径

无论 Greenfield 还是 Legacy，默认先走这条路径：

1. 读取 `references/triad-and-routing.md`
2. 读取 `references/api-reference.md`
3. 判断当前更像 `skill / agent / workflow` 中的哪一种落地形态
4. 如果 Agent 依赖 skills，准备 skills bundle / overlay / workspace
5. 写 `AgentSpec` / `WorkflowSpec`
   - 如果 host 已经有最终 prompt，先选 `prompt_render_mode`，不要把 prompt 包在普通业务 input 里
6. `rt.register_many([...])` 后先 `rt.validate()`
7. 优先用 `mock` 或 `sdk_native` 做离线回归
8. 需要结构化结果时，优先用 `run_structured()` / `run_structured_stream()`
9. 需要程序判断时，优先读 `NodeReport`、descriptor、host summary
10. 需要服务化时，再进入 `RuntimeServiceFacade` / `RuntimeSession`
11. 离线路径稳定后，最后才切 `bridge`

## Greenfield：默认落地方式

### 决策规则

- 先决定能力素材是不是 `skill`
- 再决定可执行单元是不是 `agent`
- 需要编排时再升到 `workflow`
- 默认让 `Runtime` 成为唯一执行入口

### 默认做法

- `skill`
  - 作为业务能力资产沉淀
  - 通过上游 source / overlay / mention / action 体系被消费
- `agent`
  - Runtime 可直接执行的 capability 单元
  - 默认优先采用 `AgentSpec(skills=[...])` 承载 skills-first 能力
- `workflow`
  - 只编排 `Agent / Workflow`
  - 不直接依赖底层 Skill 节点或私有桥接 helper

### 最小骨架

```python
from capability_runtime import AgentSpec, CapabilityKind, CapabilitySpec

agent = AgentSpec(
    base=CapabilitySpec(
        id="incident.triage",
        kind=CapabilityKind.AGENT,
        name="Incident Triage",
        description="分析输入事件并给出处置建议。",
    ),
    skills=["incident-triager"],
)
```

```python
from capability_runtime import (
    WorkflowSpec,
    CapabilityKind,
    CapabilityRef,
    CapabilitySpec,
    InputMapping,
    Step,
)

workflow = WorkflowSpec(
    base=CapabilitySpec(
        id="incident.flow",
        kind=CapabilityKind.WORKFLOW,
        name="Incident Flow",
    ),
    steps=[
        Step(
            id="triage",
            capability=CapabilityRef(id="incident.triage"),
            input_mappings=[InputMapping(source="context.alert", target_field="alert")],
        ),
    ],
)
```

```python
rt.register_many([agent, workflow])
assert rt.validate() == []
result = await rt.run("incident.flow", input={"alert": {...}})
assert result.node_report is not None
```

## Legacy Convergence：保守收敛方式

先识别下游是否已经有这些层：

- manifest source / registry façade
- runtime boundary / executor / adapter
- projector / task stream
- approval API / HITL store
- workflow slice / continue / replay
- service façade / session continuity
- 持久化事实模型

默认目标不是重写它们，而是判断：

- 哪些已经可以切到 Runtime public surface
- 哪些仍然应该留在下游边界
- 哪些 outward-facing contract 不能动

### 推荐收敛顺序

#### 阶段 1：registry / manifest / descriptor

优先考虑：

- `Runtime.register()`
- `Runtime.register_many()`
- `Runtime.register_with_manifest()`
- `Runtime.validate()`
- `Runtime.describe_capability()`
- `Runtime.list_capabilities()`

#### 阶段 2：host protocol internal truth

优先考虑：

- `Runtime.summarize_host_run()`
- `Runtime.build_approval_ticket()`
- `Runtime.build_resume_intent()`

#### 阶段 3：service/session boundary

只有任务明确需要 service 化或 continuity 时，才考虑：

- `RuntimeServiceFacade`
- `RuntimeSession`

### 默认不要自动进入

以下内容默认不进入第一反应：

- workflow slice / replay / continue 重写
- service façade 全面替换
- session continuity 协议重写
- Redis / DB 事实模型改造

如果任务真的需要这些，再确认用户是否明确授权扩大战场。

## Public Surface 使用优先级

### 默认业务路径优先用

- `Runtime.register()` / `register_many()` / `validate()`
- `Runtime.run()` / `run_stream()`
- `Runtime.run_structured()` / `run_structured_stream()`
- `Runtime.describe_capability()` / `list_capabilities()`
- `Runtime.summarize_host_run()`

### Host / Service 场景再看

- `Runtime.register_with_manifest()`
- `Runtime.build_approval_ticket()`
- `Runtime.build_resume_intent()`
- `RuntimeServiceFacade`
- `RuntimeSession`
- `make_invoke_capability_tool()`

### 不要默认依赖

- 深路径 import
- 私有 helper
- 内部 adapter / engine 细节

业务代码只从包根导入公共 API。细节读：

- `references/api-reference.md`

## Prompt Rendering Strategy

当 host 或应用层已经生成最终 prompt，不要把它塞进普通 `input` 让 Runtime 再包成 JSON。按目标选择 `structured_task` / `direct_task_text` / `precomposed_messages`。

关键约束：
- `_runtime_prompt` 是 Runtime 保留控制面，不是业务 input 字段
- run-level `_runtime_prompt["mode"]` / `["profile"]` 可以覆盖 `AgentSpec`
- `prompt_profile` 只使用 SDK 已支持的 profile：`default_agent` / `generation_direct` / `structured_transform`
- `precomposed_messages` 必须仍走 Runtime 公共入口、events、WAL、NodeReport 和 output validation
- `NodeReport.meta` 只记录 `prompt_render_mode`、`prompt_profile`、`prompt_hash`、message count/roles、composer version 等摘要，不记录完整 prompt 明文
- 多模态 `precomposed_messages` 的 content 可包含 `text` 与 `image_url` parts；视频等非 v1 parts 先在 host 层转换或另立显式 contract，不要 provider-specific passthrough
- 非法 messages / trace / profile 应 fail-fast 为 `INVALID_PROMPT_MESSAGES`

细节读 `references/api-reference.md` 的 Prompt Rendering。

## 运行模式选择

| 模式 | 用途 | 建议 |
|---|---|---|
| `mock` | 纯协议 / 注册 / 编排逻辑测试 | 最快验证 Runtime 语义 |
| `sdk_native` | 默认开发模式 | 业务开发优先使用 |
| `bridge` | 真实模型 / 真实传输接线 | 只在离线路径稳定后再切换 |

默认顺序：

`mock -> sdk_native -> bridge`

## 复杂任务路由

当任务已经超过“单 Agent + 单次 run”的复杂度，按下面路由：

- skills-first 结构化 Agent：读 `references/patterns-cookbook.md` 中“模式 1”
- Workflow 编排多个 Agent：读 `references/patterns-cookbook.md` 中“模式 2”
- 子能力委托 / 子 Agent：读 `references/patterns-cookbook.md` 中“模式 3”
- waiting-human / approval / resume：读 `references/patterns-cookbook.md` 中“模式 4”
- service façade / session continuity：读 `references/patterns-cookbook.md` 中“模式 5”
- 复杂任务覆盖矩阵与验收：读 `references/complex-task-matrix.md`

## 最小验证清单

### Greenfield

- `register_many()` 能成功
- `validate()` 为空
- `run()` / `run_stream()` 终态符合预期
- 需要结构化结果时优先走 `run_structured()` / `run_structured_stream()`
- `NodeReport` 存在，关键判断不依赖自由文本
- contract test 至少覆盖：理想 structured output、带 envelope 的 output、`text + structured payload` 混合形态

### Legacy Convergence

- descriptor 真相源是否已切到 Runtime public surface
- host summary 是否已能统一 success / failed / waiting-human 判断
- approval / resume 的内部真相源是否统一
- service/session 只在需要时进入
- outward-facing contract 是否保持不变
- bridge / host / adapter 的 envelope 差异是否已被 normalize，而不是在下游散落特判

## Structured Output / Bridge Contract Test 补充

只要任务涉及 `run_structured()`、`run_structured_stream()`、bridge、host summary 或真实传输接线，最小 contract test 不要只测一种“理想输出”。

至少覆盖三类样本：

1. **理想形态**
   - 结构化对象直接满足 contract

2. **envelope 形态**
   - 结构化对象被 `output / result / payload` 之类包裹

3. **混合文本形态**
   - 有说明文字、summary 或 `text` 字段，同时附带机器可消费的 structured payload

验收目标不是“所有输出都长得一模一样”，而是：

- canonical consumer 能稳定拿到同一语义结果
- normalize 逻辑是无损的
- 下游判断不依赖某一种偶然的 envelope 长相

## Do / Don't

### Do

- 优先把业务问题翻译成 `skill / agent / workflow`
- 默认把 Agent 做成 skills-first，但保持三元能力平衡
- 先补测试，再改注册面、执行面或宿主真相源
- 用 `NodeReport`、descriptor、host summary 做程序判断
- 复杂任务优先走本技能自带的 local references

### Don't

- 不要直接用底层上游框架写业务主流程
- 不要把 Workflow 写成直接编排 Skill 节点
- 不要把宿主扩展面误当成普通业务任务的默认路径
- 不要从自由文本里正则判断业务成功失败
- 不要在 Legacy 任务里顺手重写 task stream、approval API、workflow slice
- 不要引用技能目录外的“事实文档”

## 默认先读

- `references/triad-and-routing.md`
- `references/api-reference.md`
- `references/patterns-cookbook.md`
- `references/complex-task-matrix.md`
- `references/trigger-review-checklist.md`
- `evals/evals.json`

## 一句话提醒

阅读上游能力，是为了判断 `capability-runtime` 已经桥接到了哪里，以及下游边界还能如何变薄；不是为了绕过 `capability-runtime` 直接使用上游来落地业务。
