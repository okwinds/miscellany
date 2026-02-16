# Task Summary: Sync/Open-source `ui-ux-spec-genome`（2026-02-16）

## 1) Goal / Scope

- Goal：将本地全局 skill `ui-ux-spec-genome` 同步到本仓库并保持可开源分发；补齐/遵循 skill 版本号规则。
- In Scope：
  - 同步 `agent/skills/ui-ux-spec-genome/` 内容（脚本/参考资料/README）
  - `SKILL.md` 增补并 bump `version`
  - 更新 `DOCS_INDEX.md`、写入 worklog、产出本任务总结与 spec
- Out of Scope：不改动其它 skills；不改动仓库 CI/工具链；不做跨仓库的安装/发布验证（例如 `git push`）。
- Constraints：最小修改；不提交 `.openskills.json` 等本地安装痕迹；README 说明保持工具无关。

## 2) Context（背景与触发）

- 背景：本地全局 skills 目录中的 `ui-ux-spec-genome` 已更新，需要回同步到本仓库 `agent/skills/` 以便开源分发。
- 触发问题（Symptoms）：仓库内 skill 内容落后于本地版本（缺少 `scripts/lint_replica_spec.sh` 等），且同步覆盖会导致 `SKILL.md` 顶部 `version` 丢失。
- 影响范围（Impact）：影响该 skill 的功能覆盖与仓库内版本号规则/CI 检查。

## 3) Spec / Contract（文档契约）

- Contract（接口/事件协议/数据结构）：无对外 API；以 `agent/skills/ui-ux-spec-genome/` 目录结构与脚本 CLI 参数为契约。
- Acceptance Criteria（验收标准）：见 `docs/specs/2026-02-16-ui-ux-spec-genome-sync-open-source.md`。
- Test Plan（测试计划）：脚本 `bash -n` + `--help` 最小可用性；仓库变更自检。
- 风险与降级（Risk/Rollback）：同步覆盖后补回 `version`；必要时回滚 skill 目录到上一个版本。

## 4) Implementation（实现说明）

### 4.1 Key Decisions（关键决策与 trade-offs）

- Decision：使用 `publish_skill.py` 执行同步，并显式排除 `.openskills.json`/`.DS_Store`。
  - Why：避免把本地安装时间戳与无意义系统文件带入开源仓库。
  - Trade-off：同步后仍需人工补齐 `SKILL.md` 的 `version`（因为源 skill 未包含该字段）。
  - Alternatives：手工复制/rsync（更容易遗漏排除项与 README/路径归一化）。

### 4.2 Code Changes（按文件列）

- `agent/skills/ui-ux-spec-genome/SKILL.md`：补回并 bump `version: 0.1.1`。
- `agent/skills/ui-ux-spec-genome/scripts/lint_replica_spec.sh`：同步引入“复刻级 spec lint”脚本。
- `docs/specs/2026-02-15-ui-ux-spec-genome-sync-open-source.md`：本次同步/开源的最小规格与验收。
- `docs/task-summaries/2026-02-15-ui-ux-spec-genome-sync-open-source.md`：本文件（结项记录）。
- `DOCS_INDEX.md`、`docs/worklog.md`：登记与可追溯记录。

## 5) Verification（验证与测试结果）

### Unit / Offline Regression（必须）

- 命令：
  - `bash -n agent/skills/ui-ux-spec-genome/scripts/scan_ui_sources.sh`
  - `bash -n agent/skills/ui-ux-spec-genome/scripts/generate_output_skeleton.sh`
  - `bash -n agent/skills/ui-ux-spec-genome/scripts/lint_replica_spec.sh`
  - `bash agent/skills/ui-ux-spec-genome/scripts/scan_ui_sources.sh --help`
  - `bash agent/skills/ui-ux-spec-genome/scripts/generate_output_skeleton.sh --help`
  - `bash agent/skills/ui-ux-spec-genome/scripts/lint_replica_spec.sh --help`
- 结果：以上命令均返回 `exit 0`。

### Integration（可选）

- 开关（env）：无
- 命令：无
- 结果：无

### Scenario / Regression Guards（强烈建议）

- 新增护栏：无（本次为 skill 同步与发布流程，未新增测试框架）。
- 防止回归类型：通过 `--help` 最小可用性与 `bash -n` 覆盖基础脚本语法问题。

## 6) Results（交付结果）

- 交付物列表：
  - `agent/skills/ui-ux-spec-genome/` 已与本地全局 skill 同步（含 `lint_replica_spec.sh`）。
  - `SKILL.md` 已包含并 bump `version: 0.1.1`。
  - 新增 spec 与 task summary，并登记到 `DOCS_INDEX.md`。
- 如何使用/如何验收：
  - 读取 skill：`npx openskills read ui-ux-spec-genome`
  - 脚本自检：`bash agent/skills/ui-ux-spec-genome/scripts/scan_ui_sources.sh --help`

## 7) Known Issues / Follow-ups

- 已知问题：源全局 skill 的 `SKILL.md` 未包含 `version`；每次同步到仓库后都需要确保补回并 bump。
- 后续建议：如希望减少人工步骤，可在本地全局 skill 中也维护 `version` 字段，并在同步前先 bump。

## 8) Doc Index Update

- 已在 `DOCS_INDEX.md` 登记：是
