# bf-caprt-dev Trigger Review Checklist

用途：

- 快速人工审看 `bf-caprt-dev` 的触发边界是否稳定
- 判断它是否能正确区分 `Greenfield` 与 `Legacy Convergence`
- 判断它是否能同时守住三元能力平衡、Runtime 入口优先、多模态 prompt boundary、以及复杂任务路由

使用方式：

1. 把下面任一 prompt 单独丢给智能体
2. 只观察五件事：
   - 是否触发 `bf-caprt-dev`
   - 若触发，是否正确判断 `Greenfield` 或 `Legacy Convergence`
   - 是否保持 `skill / agent / workflow` 分工清楚
   - 是否把 `Runtime` 保持为业务入口，而不是把回答带向上游原生实现
   - 多模态任务是否继续走 `precomposed_messages` + Runtime public surface，而不是 provider 直连
   - 复杂任务是否路由到正确的 host / service / structured / workflow 表面
3. 若样例里有 2 条及以上判断明显错误，说明技能边界需要复审

## 应该触发

### 1. Greenfield + structured output

```text
帮我用 capability-runtime 做一个客服质检 agent，默认走 skills-first，最后我希望通过 Runtime.run_structured() 拿到稳定 JSON 结果，并保留 NodeReport 作为审计证据。
```

### 2. Greenfield + workflow orchestration

```text
我已经有几个业务 skills，想通过 WorkflowSpec 把它们编排成一个能力流，统一用 capability-runtime 注册、校验和执行。请直接给我落地实现思路。
```

### 3. Greenfield + triad balancing

```text
我先准备业务 SKILL.md bundle 和 overlay，再想用 capability-runtime 包一个可执行 agent，后面再决定要不要继续编排成 workflow。请帮我定落地顺序。
```

### 4. Child capability delegation

```text
我想做一个父 agent，在运行中通过 invoke_capability 调一个子 agent，但对外仍然只暴露 capability-runtime 的 Runtime 入口。你帮我设计实现路径和验收点。
```

### 5. Service façade + session continuity

```text
我要把一个 capability-runtime agent 暴露成服务调用入口，并且支持 session continuity。请优先告诉我 RuntimeServiceFacade 和 RuntimeSession 应该怎么接，不要先谈底层 provider。
```

### 6. Legacy + internal convergence

```text
我们下游已经有自己的 runtime boundary、task stream 和 approval API，我不想重写业务层，只想把内部 registry、descriptor 和 waiting-human 真相源收敛到 capability-runtime。外部协议不要动。
```

### 7. Legacy + host-facing review

```text
请 review 一下我们现在的 capability-runtime 接入方式，看看哪些注册、host summary、approval/resume 逻辑已经可以直接用 Runtime 的 public surface 收敛，哪些还该留在下游边界里。
```

### 8. Multimodal + multi-image vision

```text
我要用 capability-runtime 做一个 chatbot，支持一轮上传多张图片，然后用 gpt-5.4 做 vision 对话。AI 访问不能直连 provider SDK，请给我落地方式。
```

### 9. Multimodal + video boundary

```text
我想在 capability-runtime 里支持单个视频 vision 输入，是不是可以直接传 video content part 给模型？
```

### 10. Multimodal + evidence privacy

```text
多模态 precomposed messages 里有 base64 图片，我希望 NodeReport 能审计但不能泄露原始图片、URL 或 prompt 明文。这个边界应该怎么做？
```

### 11. Bridge transport but Runtime business entry

```text
用 capability-runtime 接一个 OpenAI-compatible endpoint 做 vision agent，后端可以配置 bridge，但业务入口必须是 Runtime。请告诉我如何避免误用 Agently 或 provider SDK 当业务入口。
```

## 不该触发

### 12. Upstream-native learning

```text
教我 Agently 的 TriggerFlow 原生怎么写并发和条件分支，我想直接了解它的底层工作流写法，不需要 capability-runtime 这一层。
```

### 13. Prompt-only optimization

```text
我只想优化一下 system prompt，让回答更像资深产品经理，不需要改 Runtime、测试、注册、NodeReport 或执行链路。
```

### 14. Direct upstream execution

```text
我这次就想直接用 skills-runtime-sdk 的 Agent 和 overlay 来跑业务，不需要 capability-runtime 的 AgentSpec、WorkflowSpec 或 Runtime。请给我最短路径。
```
