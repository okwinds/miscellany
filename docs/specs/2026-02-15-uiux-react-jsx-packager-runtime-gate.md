# Spec: `uiux-react-jsx-packager` Runtime Gate 强化（2026-02-15）

## Goal

- 将 `uiux-react-jsx-packager` 的默认交付标准从“宣称 pixel-perfect”调整为更可验证的**默认门禁**：
  - 可携带可跑（拿走 `.jsx` 仍可运行）
  - 首屏不白屏
  - 导航可用（至少能切换主要模块/页面）
- 补齐一个通用的运行时 smoke 预览脚本与排障手册，用于快速定位“白屏/端口误判/runner import 失败”等高频问题。
- 在仓库内 skill 目录升小版本（patch bump）。

## Constraints

- 通用性优先：文档与脚本不得绑定某个具体项目路径、某个私有预览脚本或某个业务域名。
- 最小修改：仅修改 `agent/skills/uiux-react-jsx-packager/` 下相关文件与必要文档索引。
- 可复现：不提交 `node_modules/` 等 vendored 依赖；脚本默认在临时目录工作。

## Contract（输出契约）

- Skill 目录：`agent/skills/uiux-react-jsx-packager/`
- 必须包含（或保持）：
  - `SKILL.md`（含 `name/description/version/author`）
  - `README.md` / `README.zh-CN.md`（包含至少一个可执行脚本用法示例）
  - `scripts/verify_singlefile_jsx.py`（静态门禁）
- 新增（本次交付）：
  - `scripts/preview_single_jsx_vite.sh`（运行时 smoke 预览脚本）
  - `references/preview-and-smoke.md`（通用排障与最小回归 checklist）

## Acceptance Criteria

- `SKILL.md` 明确分层验收：
  - MUST：可跑/不白屏/导航可用（作为默认门禁）
  - OPTIONAL：pixel-perfect（仅在宣称时才要求）
- `README.md` 与 `README.zh-CN.md` 均包含：
  - 安装方式（工具无关）
  - `verify_singlefile_jsx.py` 与 `preview_single_jsx_vite.sh` 的可复制命令示例
- `SKILL.md` 的 `version` 相对上一版做 patch bump（例如 `0.1.0` → `0.1.1`）。

## Test Plan（Offline）

- Python 语法检查：
  - `python3 -m py_compile agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py`
- CLI 帮助输出存在（确保参数可发现）：
  - `python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py -h`
- Shell 语法检查：
  - `bash -n agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh`
- 仓库变更自检：
  - `git status` 确认只包含预期文件
  - `find agent/skills/uiux-react-jsx-packager -maxdepth 3` 确认无 vendored 目录（如 `node_modules`）

## Risk / Rollback

- 风险：预览脚本首次运行需要 `npm install`，在离线/受限环境可能失败。
  - 缓解：把预览脚本定义为“运行时门禁的推荐工具”，不作为离线强制项；离线只要求静态门禁与文档说明完整。
- 回滚：
  - 回滚 `agent/skills/uiux-react-jsx-packager/` 到上一版，并将 `version` 回退（或继续 bump 并恢复行为）。

