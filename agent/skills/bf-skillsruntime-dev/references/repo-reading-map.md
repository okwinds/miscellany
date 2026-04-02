# 仓库事实快照（复制版）

> 本页不是让你去读仓库外文档，而是把当前仓库最关键的事实压缩成技能内快照。

## 当前版本

- SDK 包版本：`0.1.11`
- Python 包名：`skills-runtime-sdk`
- CLI 脚本：`skills-runtime-sdk`

## 公开导出面

- `skills_runtime.agent`：稳定导出 `Agent`
- `skills_runtime`：导出 `Agent`、`AgentBuilder`、`Coordinator`、`ChildResult`、`RunResult`、`__version__`

## 当前运行状态

`RunResult.status` 应按四态理解：
- `completed`
- `failed`
- `cancelled`
- `waiting_human`

## 当前关键事件

run 终态：
- `run_completed`
- `run_failed`
- `run_cancelled`
- `run_waiting_human`

协作/证据相关：
- `skill_injected`
- `plan_updated`
- `human_request`
- `human_response`
- `approval_requested`
- `approval_decided`
- `tool_call_requested`
- `tool_call_started`
- `tool_call_finished`

## 当前内置工具族

- 执行：`shell_exec` / `shell` / `shell_command` / `exec_command` / `write_stdin`
- 文件：`file_read` / `file_write` / `read_file` / `list_dir` / `grep_files` / `apply_patch`
- 交互：`ask_human` / `request_user_input` / `update_plan`
- Skills：`skill_exec` / `skill_ref_read`
- 其他：`view_image` / `web_search`
- 协作：`spawn_agent` / `wait` / `send_input` / `close_agent` / `resume_agent`

## 当前示例版图（快照）

### step-by-step

- 01_offline_minimal_run
- 02_offline_tool_call_read_file
- 03_approvals_and_safety
- 04_sandbox_evidence_and_verification
- 05_exec_sessions_across_processes
- 06_collab_across_processes
- 07_skills_references_and_actions
- 08_plan_and_user_input

### workflows

当前快照中可直接作为复杂任务样板的 workflow 包括：
- 多 agent 代码流水线
- 单 agent 表单访谈
- references 驱动流水线
- map-reduce 并行子任务
- code review → fix → QA → report
- WAL fork + replay resume
- skill actions
- studio / fastapi SSE gateway
- branching router
- retry + degrade
- collab 并行子 agent
- exec sessions 工程式交互
- workflow eval harness
- rules-based parser
- minimal rag stub
- view_image offline
- policy compliance patch
- data import validate and fix
- chatops incident triage

### examples/apps

当前快照包含的 app 原型：
- form_interview_pro
- rules_parser_pro
- incident_triage_assistant
- repo_change_pipeline_pro
- ci_failure_triage_and_fix
- data_import_validate_and_fix
- auto_loop_research_assistant
- policy_compliance_redactor_pro
- fastapi_sse_gateway_pro

## 当前已确认的技能修正点

1. 不再引用 GitHub URL 或技能目录外文档作为必读资源
2. CLI 说明明确：`skills-runtime-sdk` 与 `python3 -m skills_runtime.cli.main` 都可用
3. 状态机明确包含 `waiting_human`
4. 复杂任务指导按“单 agent / Skills-First / Coordinator / collab / replay”五条路线展开
