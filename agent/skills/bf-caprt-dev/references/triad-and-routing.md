# Triad And Routing

## 核心心智模型

默认业务主链路：

`skill / agent / workflow -> Runtime public surface -> NodeReport / host summary / service surfaces`

## 三元能力分工

### skill

- 业务能力资产
- 承载 references / actions / mentions / sources
- 不是 Workflow 的对外原语

### agent

- Runtime 可直接执行的 capability 单元
- 默认优先采用 `AgentSpec(skills=[...])` 做 skills-first 落地

### workflow

- 编排多个 `Agent / Workflow`
- 负责顺序、循环、条件、并行
- 不直接编排 Skill 节点

## 任务轴线

### 背景

- `Greenfield`
- `Legacy Convergence`

### 主焦点

- `Capability 建模`
- `Workflow 编排`
- `Structured Output`
- `Host / Service Convergence`
- `Bridge 接线`

默认顺序：

`Capability 建模 -> 执行入口 -> 证据链 -> Host / Service Convergence -> Bridge`

## Public Surface 优先级

### 默认先用

- `Runtime.register()` / `register_many()` / `validate()`
- `Runtime.run()` / `run_stream()`
- `Runtime.run_structured()` / `run_structured_stream()`
- `Runtime.describe_capability()` / `list_capabilities()`
- `Runtime.summarize_host_run()`

### 需要 host/service 再用

- `Runtime.register_with_manifest()`
- `Runtime.build_approval_ticket()`
- `Runtime.build_resume_intent()`
- `RuntimeServiceFacade`
- `RuntimeSession`
- `make_invoke_capability_tool()`

## 模式切换顺序

1. `mock`
2. `sdk_native`
3. `bridge`

## 最小验收

### Greenfield

- 注册成功
- 依赖校验通过
- `run()` / `run_stream()` 或 `run_structured()` 行为稳定
- `NodeReport` 存在

### Legacy

- descriptor / host summary / approval-resume 真相源能内部收敛
- outward-facing contract 不被顺手改掉

## 复杂任务的额外关注点

- 结构化输出：先 canonicalize，再判 degraded / fallback
- invoke_capability：对子能力调用做 tool evidence 审计
- RuntimeServiceFacade：只有 service 化时才引入
- Workflow：永远只编排 Agent / Workflow
