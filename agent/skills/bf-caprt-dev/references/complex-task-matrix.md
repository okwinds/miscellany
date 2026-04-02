# Complex Task Matrix

## 1. skills-first + structured output

适用：

- 业务能力来自 Skills
- 需要稳定 JSON 输出

必须锁住：

- `AgentSpec(skills=[...])`
- `output_schema`
- `Runtime.run_structured()` 或 `run_structured_stream()`
- `NodeReport`

验收：

- 成功结果是结构化 `dict`
- 失败路径给出明确 `error_code`
- 不从自由文本推断成功失败

## 2. Workflow 编排多个 Agent

适用：

- 多步骤业务流程
- 需要顺序 / 循环 / 条件 / 并行

必须锁住：

- Workflow 只编排 `Agent / Workflow`
- `InputMapping.target_field` 显式存在
- `Step.input_mappings`
- `LoopStep.item_input_mappings`
- `ConditionalStep.condition_source + branches + default`

验收：

- `rt.validate()` 为空
- output_mappings 正确
- 每步结果能回到控制面证据

## 3. invoke_capability 子能力委托

适用：

- 父 Agent 在运行中需要调用子 Agent / 子 Workflow

必须锁住：

- `make_invoke_capability_tool`
- `InvokeCapabilityAllowlist`
- tool evidence

验收：

- `NodeReport.tool_calls` 中存在 `invoke_capability`
- 子调用成功 / 失败 / 超时都有可观测证据

## 4. waiting-human / approval / resume

适用：

- 需要等待审批或人类输入

必须锁住：

- `Runtime.summarize_host_run()`
- `Runtime.build_approval_ticket()`
- `Runtime.build_resume_intent()`

验收：

- 等待态判断基于 host summary / approval ticket
- 不从自由文本解析等待状态

## 5. RuntimeServiceFacade / RuntimeSession

适用：

- service 化调用入口
- session continuity

必须锁住：

- `RuntimeServiceFacade`
- `RuntimeServiceRequest`
- `RuntimeSession`

验收：

- service/session 只在需要时引入
- continuity 信息显式进入 request/session

## 6. Legacy Convergence

适用：

- 下游已有 runtime boundary / task stream / approval API / session contract

必须锁住：

- 先内部真相源收敛
- 外部协议不乱改

验收：

- descriptor / host summary / approval-resume 真相源切到 Runtime public surface
- task stream / approval API / service 协议保持不变，除非用户授权
