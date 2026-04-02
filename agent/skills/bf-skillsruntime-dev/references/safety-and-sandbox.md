# 安全 / 审批 / 沙箱

## 两层防御模型

### Layer 1：Gatekeeper（决定是否允许）

链路：
- 风险检测
- policy（allow / ask / deny）
- approvals（人类或程序化）

最小配置：

```yaml
safety:
  mode: "ask"
  allowlist: ["ls", "pwd", "cat", "rg"]
  denylist: ["sudo", "rm -rf"]
  tool_allowlist: []
  tool_denylist: []
  approval_timeout_ms: 60000
```

### Layer 2：Fence（限制能访问什么）

```yaml
sandbox:
  default_policy: none
  # default_policy: restricted
```

平台适配：
- macOS：seatbelt
- Linux：bubblewrap

## 无人值守默认策略

- 默认使用规则审批，未命中规则一律拒绝
- 不要把 `ask` 理解成“需要人工点击才安全”
- 在 CI / backend / workflow 场景里，推荐程序化 `RuleBasedApprovalProvider`

```python
provider = RuleBasedApprovalProvider(
    rules=[
        ApprovalRule(
            tool="shell_exec",
            condition=lambda req: (req.details.get("argv") or [None])[0] == "pytest",
            decision=ApprovalDecision.APPROVED,
        ),
    ],
    default=ApprovalDecision.DENIED,
)
```

## `approved_for_session`

适合：
- `exec_command` + 多次 `write_stdin`
- 轮询式 workflow

价值：
- 降低重复审批噪音
- 不丢失 WAL 审计链

## 当前证据字段

必须能看到：
- `approval_requested`
- `approval_decided`
- `tool_call_requested`
- `tool_call_started`
- `tool_call_finished`

沙箱证据重点看：
- `tool_call_finished.result.data.sandbox.requested`
- `tool_call_finished.result.data.sandbox.effective`
- `tool_call_finished.result.data.sandbox.adapter`
- `tool_call_finished.result.data.sandbox.active`

## `waiting_human` 相关安全语义

- `waiting_human` 是 run 级暂停，不是安全放行
- `ask_human` / `request_user_input` 触发的人类介入，必须能在 WAL 里看见
- 如果 workflow 需要人工决策恢复，状态机里必须单独处理：
  - `run_waiting_human`
  - `human_request`
  - `human_response`

## 协作原语的审批建议

对以下工具要有明确策略：
- `spawn_agent`
- `send_input`
- `close_agent`
- `resume_agent`

经验规则：
- `wait` 一般不需要强审批
- `spawn_agent` / `send_input` 通常需要
- 子 agent 的副作用审批不能因为 master 已通过而被隐式放开

## 推荐安全默认值

```yaml
safety:
  mode: "ask"
  allowlist: ["pwd", "ls", "cat", "rg", "pytest"]
  denylist: ["sudo", "rm -rf", "mkfs", "dd", "shutdown", "reboot"]
  approval_timeout_ms: 5000

sandbox:
  default_policy: restricted
```
