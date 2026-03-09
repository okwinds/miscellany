---
name: prd-to-uiux-rd-spec
version: "0.1.1"
description: 从产品 PRD 产出“复刻级可落地”的 UI/UX 研发规格文档包（目录同构骨架、公共基座、组件/页面契约、覆盖映射、索引与 worklog）。适用于需要把 PRD 转成前端可复刻实现的规格文档、UI/UX 研发规格、界面契约与验收标准的场景；避免用于只要视觉灵感/纯 UI 赏析或直接写代码实现的请求。
compatibility: 适用于能在仓库内写入 Markdown 文件的 Agent/开发者；默认不要求网络；默认不写业务代码，只输出规格文档与索引/记录。
metadata:
  version: "0.1.0"
  last_updated: "2026-02-09"
---

# PRD → UI/UX 研发规格（复刻级）交付流程

目标：把“产品 PRD（总纲）”转化为**前端可复刻实现**的 UI/UX 研发规格文档包（UI 行为、状态机、数据/事件契约、A11y、验收与测试计划），并让目录结构本身就能传达“做到了什么/没做到什么”。

本 skill 的原则：
- **文档先行**：先冻结“壳层/公共基座/契约”，再写模块页面细节。
- **目录即证据**：打开文件夹即可判断覆盖度与可落地程度（不是散文集）。
- **可演进**：对“未来会增减的内容版块”，用契约/模型承接（前端不写死章节）。
- **安全默认**：本 skill 默认不改业务代码；若用户要求写代码，先把规格与契约写清，再另起任务实现。

---

## 0) 你需要向用户确认的输入（最少集）

1) PRD 路径/链接（或最小 PRD 框架）
2) 是否存在**只读参考基座**（例如旧 UI/UX spec、设计系统、竞品稿件）；如果有，路径在哪里、是否允许改动
3) 前端关键约束（至少选 1 套）：
   - 图表库（如 ECharts）
   - 图标库（如 lucide-react）
   - 导出格式（如 PDF 默认、DOCX 权限、Markdown 复制/导出）
4) 交付粒度：L1 小改 / L2 新模块 / L3 核心壳层（默认按 L2 交付）

如果缺 PRD：先用 `references/output-contract.md` 的“PRD 最小骨架”补齐，否则 UI/UX 规格会漂。

---

## 1) 输出契约（你必须产出的文件/结构）

默认推荐（可按仓库约定调整路径，但结构不变）：
- `docs/specs/prds/<date>-<slug>-prd.md`：产品 PRD（总纲）
- `docs/specs/ui-ux-rd-spec/`：UI/UX 研发规格（可复刻落地）
- `DOCS_INDEX.md`：仓库级文档索引（路径 + 一句话说明）
- `docs/worklog.md`：工作记录（命令 + 决策 + 结果）

`docs/specs/ui-ux-rd-spec/` 目录必须包含：
- `OVERVIEW.md`：UI/UX 总纲（能力地图 + TODO + 入口）
- `DOCS_INDEX.md`：本目录索引（每份规格文档的入口）
- `00_SourceInventory/`：来源/参考/覆盖映射
- `01_Foundation/`：公共基座（tokens/布局/交互/A11y/图标/图表等跨模块约束）
- `02_Components/`：可复用组件规格（含数据/事件契约）
- `03_Patterns/`：跨模块交互模式补充
- `04_Pages/`：页面复刻级规格（每页一份，含状态机/验收/测试计划）
- `05_A11y/`：A11y 汇总（新增组件/页面的约束）

模板见：
- `references/uiux-rd-spec-directory-skeleton.md`
- `references/page-spec-template.md`
- `references/component-spec-template.md`
- `references/coverage-template.md`
- `references/replica-readiness-checklist.md`

---

## 2) 工作流（按顺序执行）

### Step 0：业务关键契约抽取 Gate（防“模板化空心”）

> 风险背景：文档过度模板化会出现“看起来很完整，但缺业务关键契约”的伤害。
>
> 本 Gate 的目标：在写 UI/UX 细节前，把“对象/术语/关键流程/权限边界/核心字段”先冻结到可引用的契约里。

最低要求（缺任何一项都不得进入 Step A 的大量产文档阶段）：
1) **对象与术语（Glossary）**：至少列出核心对象与关系（`Work/Project/Run/Artifact/...`）
2) **关键流程（Key Flows）**：每条流程写清“触发→状态机→产物→回流/导出”
3) **权限边界（Roles/Permissions）**：至少写清“默认只读 vs step-up 写入”的规则（若涉及）
4) **关键字段口径**：成本/耗时/状态等字段的“展示口径”必须能落到字段级（避免后续 UI 争议）

模板（可选）：
- `references/glossary-template.md`

### Step A：先搭“复刻级骨架”（先让结构自证）

1) 创建 `ui-ux-rd-spec/` 并按 skeleton 建好层级与入口文件：
   - `OVERVIEW.md`：先写约束与导航（不要等写完再补）
   - `DOCS_INDEX.md`：先登记每个将要出现的模块/页面（可先 stub）
2) 如果存在只读参考基座（旧 spec/设计系统）：
   - **明确只读**：在 `OVERVIEW.md` 与 `00_SourceInventory/` 写清“引用但不修改”
   - **目录同构**：尽量与只读基座同构，降低“对照成本”

输出检查点：目录结构一眼看上去就像“能落地的工程规格”，而不是“零散文章集合”。

### Step B：冻结公共基座（Foundation）与壳层（Shell）

1) 在 `01_Foundation/FOUNDATION.md` 冻结跨模块约束：
   - 颜色/间距/排版 tokens（若已有基座则引用）
   - 三栏布局原则（左=上下文，中=操作区，右=指令/监控）
   - 图标库约束（如 lucide-react）
   - 图表策略：工作区必须可交互；导出才静态化（若有图表）
2) 在 `04_Pages/` 先创建 `WorkbenchShell.md`（或同义壳层页）：
   - TopBar / Sidebar / Left/Center/Right / Bottom Console 的插槽契约
   - 允许“不同阶段左栏内容不同”的规则：用 slot + data-driven 渲染，而不是写死

注意：壳层没冻结前，不要开始写模块页面细节，否则后续会大返工。

### Step C：组件先行（组件契约 → 页面引用）

在 `02_Components/` 抽象出“跨模块复用且必须稳定”的组件规格：
- 导入/输入组件（上传、粘贴、格式白名单、规范化）
- 图表组件（若需要）：交互、tooltip、click 联动、主题同步、导出静态化
- 执行状态面板（类似 IDE Console）：默认折叠 + 失败自动展开一次（可选）
- “可演进报告/内容”的文档模型（强烈建议）：用 block/section 模型承接未来增减
- 导出组件：PDF 默认、DOCX 权限、Markdown 复制/导出；导出时静态化图表

做法：页面规格只引用组件契约，不在页面里重复写组件细节。

### Step D：页面复刻级规格（每页一份，必须含状态机）

对每个页面按 `references/page-spec-template.md` 输出，至少包含：
- 页面目标、用户、关键任务
- 布局（左/中/右/底部）与信息分区
- 状态机（就绪/运行/完成/失败/取消等）
- 数据契约（字段、来源、刷新策略、空态/错误态）
- 事件/联动契约（click/hover/selection → 筛选/定位/高亮）
- A11y（键盘路径、ARIA、可替代视图）
- 验收标准（AC）与测试计划（离线回归如何验证）

### Step E：覆盖映射（Coverage）与未尽事宜清单

在 `00_SourceInventory/COVERAGE.md` 维护可审计映射：
- PRD/需求点 → 规格落点（页面/组件/基座）
- 明确“未覆盖项”（留到下一版本迭代），避免遗忘

### Step F：索引 + Worklog（交付闭环）

1) 更新仓库 `DOCS_INDEX.md`：登记 PRD 与 UI/UX 规格入口
2) 追加 `docs/worklog.md`：记录关键命令、关键决策与结果（不写敏感信息）

---

## 3) 关键决策规则（避免跑偏）

1) **TopBar vs Sidebar**：TopBar 放“全局一致项”；Sidebar 放“模块级导航”；模块阶段/视图切换优先放 Canvas Header。
2) **左栏内容**：左栏不是固定组件，而是“Context Slot”。不同阶段呈现不同上下文（目录/设定/TOC/待办）。
3) **右栏优先操控**：右侧以指令与监控为主；成本监控可在下部，但不要挤占指令入口。
4) **可演进内容**：凡是“未来会增减的报告版块/字段”，必须通过模型/契约承接，前端不写死。
5) **图表**：工作区图表必须可交互（hover/click 出细节并能联动）；只有导出时才静态化为图片。

---

## 4) 自检（Definition of Done for 文档）

用 `references/replica-readiness-checklist.md` 自检。最低通过线：
- 目录结构一眼看得出“公共基座/组件/页面”的分层
- 每个页面都有状态机 + 数据契约 + AC + 测试计划
- 有 Coverage 映射，且未尽事宜被显式登记
- 仓库 `DOCS_INDEX.md` 与 `docs/worklog.md` 已更新

建议补充自检（强烈建议）：
- 使用 `references/replica-scorecard.md` 进行一次 0/1/2 量化评分，并在总结中记录分数与短板项

---

## 5) 测试提示（给自己做 dry-run）

见 `tests/evals_prd-to-uiux-rd-spec.yaml`，按场景自测：
- 会不会被错误触发
- 缺输入时是否会先补 PRD/约束
- 产物是否符合“复刻级骨架”与覆盖映射要求
