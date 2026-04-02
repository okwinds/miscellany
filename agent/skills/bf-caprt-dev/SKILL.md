---
name: bf-caprt-dev
version: 0.1.0
description: "指导编码智能体以 capability-runtime 为业务落地入口，交付基于 capability-runtime 的 skills / agents / workflows，并在 Greenfield 或 Legacy Convergence 场景下优先使用 Runtime public surface、structured output、NodeReport、host summary 与 service/session surfaces。只要任务目标是用 capability-runtime / capability_runtime 落地业务代码、收敛下游 runtime boundary，或涉及 Runtime.run / Runtime.run_stream / run_structured / run_structured_stream / AgentSpec / WorkflowSpec / NodeReport / RuntimeServiceFacade / describe_capability / summarize_host_run，就应优先使用本技能。不要用于普通通用编码、prompt-only 任务、直接学习上游原生框架 API，或任何明确要求“直接用 skills-runtime-sdk / Agently / provider SDK，不走 capability-runtime”的任务；若已触发但随后识别出这是反目标，必须立即退出，并停止提供任何上游实现细节、伪代码或 API 猜测。"
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
- `Host Convergence`
  - descriptor、host summary、approval/resume、service/session
- `Bridge 接线`
  - 真实模型接线与传输兼容

默认路由顺序：

`Capability 建模 -> 执行入口 -> 证据链 -> Host / Service Convergence -> Bridge`

不要一开始就跳到 bridge。

## 三条红线

### 1. 业务代码不得绕过 capability-runtime

无论内部桥接依赖什么，业务主流程都不得直接调用底层上游框架来代替 `capability-runtime`。

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

### 4. structured output 先 canonicalize，再 fallback

当 structured output 出现“字段看起来缺失、但原始 payload 里似乎还有内容”时，先按下面顺序处理：

1. 对原始 payload 做无损扫描
2. 识别等价字段和错误层级
3. 先做 lossless canonicalize，恢复 canonical structured output
4. 再做 coverage / completeness / degraded 判定
5. 只有 canonicalize 后仍缺失，才允许 retry、fallback 或 estimated

一句话原则：

- 只要真数据还在 payload 里，就先救回真数据，不要抢先造估算值

## 默认业务主路径

无论 Greenfield 还是 Legacy，默认先走这条路径：

1. 读取 `references/triad-and-routing.md`
2. 读取 `references/api-reference.md`
3. 判断当前更像 `skill / agent / workflow` 中的哪一种落地形态
4. 如果 Agent 依赖 skills，准备 skills bundle / overlay / workspace
5. 写 `AgentSpec` / `WorkflowSpec`
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

### Legacy Convergence

- descriptor 真相源是否已切到 Runtime public surface
- host summary 是否已能统一 success / failed / waiting-human 判断
- approval / resume 的内部真相源是否统一
- service/session 只在需要时进入
- outward-facing contract 是否保持不变

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
