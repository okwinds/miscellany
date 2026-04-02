# 配方索引（本地快照）

> 用途：在不读取仓库外文档的前提下，快速决定“复杂任务该落哪种形态”。

当前快照覆盖：
- 8 个 step-by-step
- 4 个 skills 示例
- 1 个 state 示例
- 19 个 workflow 示例
- 多个 apps 原型

## 路由总表

| 场景 | 推荐形态 | 核心能力 | 必看证据 |
|------|----------|----------|----------|
| 读代码 / 改 patch / 最小回归 | 单 agent + 标准工具 | `read_file` / `apply_patch` / `shell_exec` | `tool_call_*` + `approval_*` |
| 命令执行要可控 | 单 agent + approvals + sandbox | `shell_exec` + `RuleBasedApprovalProvider` | `approval_*` + `data.sandbox.*` |
| Skills 引用材料 / 动作脚本 | Skills-First | mention + `skill_ref_read` / `skill_exec` | `skill_injected` |
| 固定角色流水线 | `Coordinator` | Analyze / Patch / QA / Report | 每个角色独立 WAL |
| 动态并行子任务 | collab primitives | `spawn_agent` / `send_input` / `wait` | master/child 双证据链 |
| 多轮访谈 / 决策点 | Human I/O + plan | `request_user_input` + `update_plan` | `human_request` / `human_response` / `plan_updated` |
| 长任务断点恢复 | replay / fork / resume | WAL + `waiting_human` | `run_waiting_human` / replay evidence |
| 交互式工程会话 | exec sessions | `exec_command` + `write_stdin` | session id + `tool_call_finished` |
| workflow 评测 | eval harness | 多次运行 + artifacts + score | 可比产物与评分记录 |

## 复杂开发任务推荐组合

### 1. 业务编码代理

适用：
- 在仓库里读代码、改代码、跑最小验证

推荐：
- `AgentBuilder`
- builtin file tools
- 规则审批 provider
- WAL

### 2. Skills-First 业务助手

适用：
- 需要显式 skill 包、references、actions

推荐：
- `skills preflight`
- `skills scan`
- mention 驱动注入
- `skill_ref_read` / `skill_exec`

### 3. 固定流程多 agent

适用：
- 角色固定、阶段稳定

推荐角色：
- Analyzer
- Patcher
- QA
- Reporter

推荐：
- `Coordinator`
- 每个角色一个 skill
- workspace 产物隔离

### 4. 动态子 agent 协作

适用：
- planner 先拆任务，再动态 spawn 子 agent
- 运行中途需要补充输入

推荐：
- `spawn_agent`
- `send_input`
- `wait`
- `close_agent` / `resume_agent`

### 5. 等待人工与恢复执行

适用：
- 表单访谈
- 审批后继续
- 人工补充信息后续跑

推荐：
- 单独处理 `waiting_human`
- 不要把它当成失败
- 需要时结合 replay / fork / resume

## 业务交付的最小护栏

1. 能离线跑通：`FakeChatBackend`
2. 有最小 smoke tests
3. 有明确产物：`report.md` / `submission.json` / `result.json`
4. 有 WAL 定位：`wal_locator`
5. 有副作用证据：`approval_*` + `tool_call_*`

## 常见选择错误

| 错误 | 正确做法 |
|------|----------|
| 动态任务还硬塞 `Coordinator` | 用 collab primitives |
| skill 要读 references，却没开开关 | 显式开启 `skills.references.enabled` |
| workflow 有人类决策点，却只看 `completed/failed` | 把 `waiting_human` 纳入状态机 |
| 直接让模型拼危险命令 | 用 rules approval + sandbox |
