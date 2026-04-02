# 测试策略

## 基线原则

- 离线优先：先用 `FakeChatBackend`
- 可回归：最小 smoke test 必须能稳定复现
- 有证据：不仅看 stdout，也看 `wal_locator` 与事件链
- 小范围优先：先测当前改动直接相关部分，再决定是否放大全量验证

## 最小验证顺序

### 1. 业务骨架自身

```bash
python3 run.py --workspace-root /tmp/my-app --mode offline
pytest -q tests
```

### 2. Skills 配置

```bash
skills-runtime-sdk skills preflight --workspace-root . --config config/runtime.yaml --pretty
skills-runtime-sdk skills scan --workspace-root . --config config/runtime.yaml --pretty
```

### 3. 仓库内开发时的门禁

```bash
bash scripts/pytest.sh
pytest -q packages/skills-runtime-sdk-python/tests/test_examples_smoke.py
```

### 4. workflow 评测

当 workflow 已经能稳定离线跑通，需要比较多次运行的一致性时，再启用 eval harness：

```bash
python3 docs_for_coding_agent/examples/workflows/15_workflow_eval_harness/run.py --workspace-root /tmp/srsdk-eval
```

期望产物：
- `eval_report.md`
- `eval_score.json`
- `runs/`

## 离线 backend

```python
backend = FakeChatBackend(calls=[
    FakeChatCall(events=[
        ChatStreamEvent(type="text_delta", text="EXAMPLE_OK: done."),
        ChatStreamEvent(type="completed", finish_reason="stop"),
    ])
])
```

## 离线 approvals / human I/O

### Scripted approval

```python
class ScriptedApproval(ApprovalProvider):
    def __init__(self, decisions):
        self._decisions = iter(decisions)

    async def request_approval(self, *, request, timeout_ms=None):
        _ = request
        _ = timeout_ms
        return next(self._decisions, ApprovalDecision.DENIED)
```

### Scripted human I/O

```python
class ScriptedHumanIO(HumanIOProvider):
    def __init__(self, answers_by_question_id):
        self._answers = answers_by_question_id

    async def request_input(self, *, question_id, prompt, **kw):
        _ = prompt
        _ = kw
        return self._answers.get(question_id, "")
```

## 复杂任务的必查证据

### Skills-First

- `skill_injected`
- mention 与 namespace 是否匹配

### 副作用工具

- `approval_requested`
- `approval_decided`
- `tool_call_finished.result.ok`

### Human-in-the-loop

- `human_request`
- `human_response`
- `run_waiting_human`

### 动态协作

- master 的 `spawn_agent/send_input/wait`
- child 的独立 `wal_locator`

### workflow eval

- `eval_report.md`
- `eval_score.json`
- 归一化后的 diff 摘要是否稳定

## 真模型集成测试（可选）

只在需要时开启：

```bash
export OPENAI_API_KEY='...'
```

注意：
- 没有 key 时应 skip，而不是伪通过
- 真模型验证只作为补充，不能替代离线回归

## 当前交付定义

最少满足：
1. 有入口文件
2. 有最小 overlay
3. 有离线 smoke
4. 有 WAL 证据
5. 如果涉及 skill / approval / human / collab，就有对应事件断言
