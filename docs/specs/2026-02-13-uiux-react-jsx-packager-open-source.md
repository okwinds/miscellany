# Spec: Open-source `uiux-react-jsx-packager`（2026-02-13）

## Goal

- 将本地 skill `uiux-react-jsx-packager` 以可复用方式发布到本仓库 `agent/skills/uiux-react-jsx-packager/`。
- 补齐该 skill 的 `README.md` / `README.zh-CN.md`（工具无关、可独立阅读）。
- 更新仓库根 `README.md` 的 Skills 清单（新增 skill 时必须）。

## Constraints

- 最小修改：仅提交与该 skill 发布相关的文件与文档更新。
- 可复现：不引入 `node_modules/` 等 vendored 依赖目录；不提交任何密钥/隐私数据。
- 一致性：`SKILL.md` 顶部 YAML front matter 必须包含 `version`（SemVer）与 `author`。

## Acceptance Criteria

- `agent/skills/uiux-react-jsx-packager/` 存在且包含：
  - `SKILL.md`（含 `name/description/version/author`）
  - `README.md`、`README.zh-CN.md`（包含安装方式 + 至少一个可执行的脚本用法示例）
  - `scripts/verify_singlefile_jsx.py`
- 仓库根 `README.md` 的 skills 清单已添加 `agent/skills/uiux-react-jsx-packager/` 条目。
- 本次新增/变更文档已登记到 `DOCS_INDEX.md`，并在 `docs/worklog.md` 记录关键命令与结果。

## Test Plan（Offline）

- Python 语法检查：
  - `python3 -m py_compile agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py`
- 仓库变更自检：
  - `git status` 确认只包含预期文件
  - `find agent/skills/uiux-react-jsx-packager -maxdepth 2` 确认未引入大体积依赖目录（如 `node_modules`）

## Risk / Rollback

- 风险：README 中的安装/路径示例与使用者工具扫描目录不一致。
- 回滚：删除 `agent/skills/uiux-react-jsx-packager/` 与本次新增文档条目，并回滚 `README.md` 的清单更新。

