# 配置模板与合并规则

## 配置优先级（高 → 低）

1. `session_settings`
2. 环境变量（`SKILLS_RUNTIME_SDK_*`）
3. overlay YAML（如 `config/runtime.yaml` + `--config`）
4. SDK embedded default

## 基本原则

- Schema 是 strict，未知字段 fail-fast
- 不把 API key 写进 YAML，只声明 `llm.api_key_env`
- `references` / `actions` 默认关闭，需要时显式开启
- 无人值守默认 fail-closed，不要把所有工具一次性放开

## 最小 overlay（单 agent）

```yaml
run:
  max_steps: 20
safety:
  mode: "ask"
  approval_timeout_ms: 60000
sandbox:
  default_policy: none
```

## Skills-First overlay

```yaml
run:
  max_steps: 20
safety:
  mode: "ask"
  approval_timeout_ms: 60000
sandbox:
  default_policy: none
skills:
  strictness:
    unknown_mention: error
    duplicate_name: error
    mention_format: strict
  references:
    enabled: false
  actions:
    enabled: false
  spaces:
    - id: app-space
      namespace: "biz:myapp"
      sources: [app-fs]
      enabled: true
  sources:
    - id: app-fs
      type: filesystem
      options:
        root: "./skills"
```

## 远端 Skills sources（复杂部署）

当业务要从集中存储分发 skills，而不是只读本地 filesystem 时，可以扩展到：
- `redis`
- `pgsql`
- `in-memory`

示例：

```yaml
skills:
  spaces:
    - id: prod-space
      namespace: "biz:prod"
      sources: [fs-local, redis-main, pgsql-main]
      enabled: true
  sources:
    - id: fs-local
      type: filesystem
      options:
        root: "./skills"
    - id: redis-main
      type: redis
      options:
        dsn_env: "SKILLS_REDIS_DSN"
        key_prefix: "skills:"
    - id: pgsql-main
      type: pgsql
      options:
        dsn_env: "SKILLS_PG_DSN"
        schema: "public"
        table: "skills_registry"
```

注意：
- 远端 source 的凭据通过环境变量注入
- 生产环境仍建议先跑 preflight / scan，再决定是否启用 references/actions

## 开启 references / actions

### `skill_ref_read`

```yaml
skills:
  references:
    enabled: true
```

### `skill_exec`

```yaml
skills:
  actions:
    enabled: true
```

## 真模型 overlay

```yaml
llm:
  base_url: "https://api.openai.com/v1"
  api_key_env: "OPENAI_API_KEY"
  timeout_sec: 60
  retry:
    max_retries: 3
    base_delay_sec: 0.5
    cap_delay_sec: 8.0
    jitter_ratio: 0.1
```

## 人工介入 / 长任务建议

```yaml
run:
  max_steps: 40
  human_timeout_ms: 3000
  # 需要 replay/resume 时再显式开启
  # resume_strategy: replay
```

## 配置解析（代码）

```python
from pathlib import Path
from skills_runtime import bootstrap

resolved = bootstrap.resolve_effective_run_config(
    workspace_root=Path(".").resolve(),
    session_settings={},
)

print(resolved.base_url)
print(resolved.api_key_env)
print(resolved.sources)
```
