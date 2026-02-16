# Spec: Sync/Open-source `ui-ux-spec-genome`（2026-02-16）

## Goal

- 将本地全局 skill `ui-ux-spec-genome` 的最新内容同步到本仓库 `agent/skills/ui-ux-spec-genome/` 并保持可开源分发。
- 保证该 skill 在仓库内满足版本号规则：修改任意文件必须 bump `SKILL.md` 顶部 `version`（SemVer）。
- 保证发布内容可复现、可安装（README 工具无关），且不携带本地安装痕迹文件（例如 `.openskills.json`）。

## Constraints

- 最小修改：仅更新 `ui-ux-spec-genome` skill 及本次变更所需文档（spec/worklog/task summary/index）。
- 可复现：不引入 vendored 目录（如 `node_modules/`），不提交本机安装时间戳/路径等私有信息。
- 工具无关：README 的安装/使用说明不绑定某一个特定 Agent 产品。

## Acceptance Criteria

- `agent/skills/ui-ux-spec-genome/` 同步完成并包含：
  - `SKILL.md`（含 `name/description/version`）
  - `README.md`、`README.zh-CN.md`（包含安装方式 + 至少一个可执行用法示例）
  - `scripts/` 下脚本可运行（至少 `--help` 可用）
  - `references/` 下参考文档保持完整
- 目标目录中不包含本地安装痕迹文件（例如 `.openskills.json`、`.DS_Store`）。
- 本次新增/变更文档已登记到 `DOCS_INDEX.md`，并在 `docs/worklog.md` 记录关键命令与结果。

## Test Plan（Offline）

- 脚本语法检查：
  - `bash -n agent/skills/ui-ux-spec-genome/scripts/scan_ui_sources.sh`
  - `bash -n agent/skills/ui-ux-spec-genome/scripts/generate_output_skeleton.sh`
  - `bash -n agent/skills/ui-ux-spec-genome/scripts/lint_replica_spec.sh`
- 脚本最小可用性（help）：
  - `bash agent/skills/ui-ux-spec-genome/scripts/scan_ui_sources.sh --help`
  - `bash agent/skills/ui-ux-spec-genome/scripts/generate_output_skeleton.sh --help`
  - `bash agent/skills/ui-ux-spec-genome/scripts/lint_replica_spec.sh --help`
- 仓库变更自检：
  - `git status` 确认只包含预期文件
  - `find agent/skills/ui-ux-spec-genome -maxdepth 2` 确认未引入大体积依赖目录与本地痕迹文件

## Risk / Rollback

- 风险：同步覆盖导致 `SKILL.md` 顶部 `version` 丢失，触发 CI/版本号规则失败。
- 回滚：回滚 `agent/skills/ui-ux-spec-genome/` 到上一个版本，并同步回滚本次新增文档条目（`DOCS_INDEX.md`、worklog、task summary、spec）。
