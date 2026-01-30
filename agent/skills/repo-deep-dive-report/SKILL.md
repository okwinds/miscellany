---
name: repo-deep-dive-report
description: End-to-end source code repository deep dive and review. Use when you need to understand a repo’s architecture, core abstractions, entrypoints and execution flow, extension points, and operational/developer setup; and when you must deliver a structured report (Markdown + standalone HTML) with diagrams (Mermaid), actionable recommendations, and a scored evaluation.
---

# Repo Deep Dive Report（通用代码仓库深度走读 + 交付报告）

## Workflow（按阶段交付，证据驱动）

目标：把“读仓库”从随缘走读变成可复用的工程化流程：**收敛范围 → 建全局地图 → 追入口与关键链路 → 深挖高杠杆模块 → 总结文档与上手 → 评分与建议 → 生成 MD+HTML 可查阅交付物**。

## 安全与脱敏（必读）

在阅读与交付报告时，默认把仓库内容视为可能包含敏感信息：

- **不要**在报告/聊天中粘贴：密钥、token、cookie、私钥、`.env` 的值、生产连接串、内部域名/内网 IP、真实用户数据。
- 需要引用配置时：只列出**键名**与用途（必要时对值做掩码，如 `AKIA…WXYZ`）。
- 需要引用日志/请求时：优先展示**最小片段**，并删除/替换敏感字段（如 `Authorization`、`Set-Cookie`、`password`）。
- 需要引用源码时：仅引用支撑结论的最小片段，避免大段复制；尽量用“文件路径 + 符号名 + 行号/范围”定位。
- 若用户明确要求包含敏感细节：先确认其可分享范围与用途，再继续。

### 0) 明确输入与边界（先问清楚再开始）

- 确认仓库路径、分支/commit、目标读者（开发/架构/运维/产品）。
- 明确“锚点”：从哪个入口/函数/CLI/HTTP 路由/任务开始追（若用户没给，选择最常见入口并说明依据）。
- 明确交付：是否需要 Mermaid 图、是否要 MD+HTML、是否要“评分/改进建议”、是否需要可运行的示例。

### 1) Phase 1：全局地图（Architecture Map）

- 建立“目录级视图”：顶层目录职责、核心包/模块、examples/tests/docs/infra 的位置与用途。
- 找出“装配点/入口点”：典型包括 `main`/CLI、Web 入口、框架初始化、依赖注入、插件注册等。
- 产出模块依赖 Mermaid（不必精确到函数级；优先稳定且可读的组件级关系）。
- 要求：每个关键结论都能落到**文件路径 + 关键符号名（类/函数/配置键）**；能给行号就给。

### 2) Phase 2：入口与执行流程（Entrypoint → Critical Path）

- 从锚点符号开始追踪：定义 → 调用点 → 关键对象如何被初始化/注入/持有。
- 把“链式/管线式调用”拆解成步骤：每一步修改了哪些字段/状态、依赖了哪些配置、触发了哪些外部边界（网络/DB/队列/LLM/文件系统）。
- 输出：**步骤列表（带方法名/文件路径）** +（可选）Mermaid `sequenceDiagram`。

### 3) Phase 3：核心模块深挖（High-Leverage Subsystems）

选择 3–6 个“最影响使用/扩展/稳定性”的模块深挖（按仓库类型调整）：
- **数据模型/校验/结构化输出**：schema 定义、验证、重试/纠错、流式解析等。
- **工作流/编排**：DSL/状态机/事件系统/并发控制/可观测性。
- **工具/插件/扩展系统**：注册、选择策略、协议接口、生命周期、Tracing。
- **模型/Provider 适配层**：配置消费、请求/响应标准化、切换 provider 的边界。
- **存储/缓存/队列**：一致性、错误处理、回放/重试。

深挖输出结构建议固定为：**概念 → 代码定位 → 核心数据结构 → 关键流程/算法 → 示例 → 扩展点**。

### 4) Phase 4：上手实操与二次开发（Getting Started + Extensibility）

- 最小依赖：从依赖清单（如 `pyproject.toml` / `package.json` / `go.mod` / `Cargo.toml`）提取关键依赖并分类（运行/开发/可选集成）。
- 跑通一个最小示例：列出必须配置（env/key/base_url/端口/数据库），以及常见坑（网络、权限、流式、超时等）。
- 二次开发扩展点：新增模块/节点/规则时，应该改哪里、遵循什么模式、如何写最小测试/示例验证。

### 5) Phase 5：仓库内文档总结（Docs for Dev/Agent）

- 读取仓库内的 `docs/`、`CONTRIBUTING`、`AGENTS.md`、以及“给 AI/开发者的专用文档目录”。
- 总结三类信息：推荐组织方式、核心 API 使用规范、鼓励/禁止的模式（含原因/风险）。

### 6) Phase 6：评分（Scorecard）与改进建议

- 采用 100 分制、多维度（≥8）评分；每个维度必须有“观察到的事实/证据点”支撑，避免空泛。
- 输出：总分 + 分项分数 + 解释 + Top 改进建议（按影响/成本排序）。
- 评分维度模板见 `references/scoring_rubric.md`。

### 7) 交付物生成（Markdown + Standalone HTML）

- 在仓库内创建/更新：`docs/repo_review.md` 与 `docs/repo_review.html`（或按用户指定路径）。
- HTML 离线可读：自带 CSS、包含目录；Mermaid 至少保留 code block（可选 CDN 渲染但不能依赖网络）。
- 可用脚本渲染 HTML（stdlib-only）：`scripts/render_md_to_html.py`。

## Quality Gates（如何保证交付品质）

在输出最终报告前，逐项自检：
- **可追溯性**：关键结论都能落到具体文件/符号（必要时给行号）；不凭空推测。
- **覆盖性**：用户提出的每个问题都有明确回答（或明确说明“仓库里未找到/无法确认”的原因）。
- **图表**：至少 1 张 Mermaid（模块依赖）；执行链路建议再给 1 张 sequenceDiagram。
- **可操作性**：Getting Started 至少给出一条可执行路径（命令 + 配置项），并列出常见坑与排查。
- **可扩展性说明**：至少指出 2–4 个可扩展点（plugin/extension/hook/interface），并给出扩展步骤清单。
- **评分可信度**：每个维度有证据与权衡；总分计算透明。
- **交付可读性**：Markdown 有目录、层级清晰；HTML 可直接打开阅读、代码块不破坏版式。

## Resources（随用随读，避免占用上下文）

### scripts/
- `scripts/render_md_to_html.py`：把报告 Markdown 渲染成离线 HTML（stdlib-only）。
- `scripts/repo_snapshot.py`：生成仓库快照（语言/关键文件/规模）供报告引用（可选）。

### references/
- `references/report_outline.md`：报告大纲模板（Phase 1–6 + 附录）。
- `references/mermaid_templates.md`：Mermaid 图模板（模块依赖图 + 时序图）。
- `references/scoring_rubric.md`：评分维度与打分口径（100 分制）。
