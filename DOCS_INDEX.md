# Docs Index (Template)

用途：作为仓库的“文档目录”，保证任何人/Agent 都能快速定位关键资料。

约定：
- 每条记录必须包含：**文件路径 + 一句话说明**
- 新增/删除/重命名文档时必须同步更新本索引

建议结构（可按项目调整）：

---

## Core

- `README.md`：仓库入口说明与快速开始。
- `AGENTS.md`：协作宪法（Spec-Driven + TDD + 文档索引 + 任务总结）。
- `DOCS_INDEX.md`：文档索引（本文件）。

---

## Specs

- `docs/specs/`：规格/设计文档目录（每个功能/模块一份 spec）。
- `docs/specs/2026-02-13-uiux-react-jsx-packager-open-source.md`：发布 `uiux-react-jsx-packager` skill 的最小规格（目标/约束/验收/测试计划）。
- `docs/specs/2026-02-15-uiux-react-jsx-packager-runtime-gate.md`：强化 `uiux-react-jsx-packager` 的默认门禁（可跑/不白屏/导航可用）并沉淀通用 smoke/排障。

---

## Worklog & Summaries

- `docs/worklog.md`：工作记录（按时间顺序追加，含命令与结论）。
- `docs/task-summaries/`：任务结束总结目录（每次结项一份）。
- `docs/task-summaries/2026-02-13-uiux-react-jsx-packager-open-source.md`：本次发布 `uiux-react-jsx-packager` skill 的任务总结（变更、验证与结果）。
- `docs/task-summaries/2026-02-15-uiux-react-jsx-packager-runtime-gate.md`：本次强化 `uiux-react-jsx-packager` 运行时门禁的任务总结（变更、验证与结果）。
- `docs/templates/task-summary-template.md`：任务总结模板（复制填空）。

---

## Tests & Quality

- `docs/testing-strategy.md`：测试策略（单元/集成/场景回归与护栏）。

---

## Reusable Assets

- `templates/`：可复用模板（例如脚手架、示例配置、协议模板）。
- `skills/`：可复用技能资产（如果项目有技能系统）。
