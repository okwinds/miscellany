# Task Summary: `uiux-react-jsx-packager` Runtime Gate 强化（2026-02-15）

## 1) Goal / Scope

- Goal：把 `uiux-react-jsx-packager` 从“静态合并为单文件”升级为“默认可跑/不白屏/导航可用”的可回归门禁，并沉淀通用预览/排障工具链。
- In Scope：
  - `SKILL.md` 验收分层调整（MUST runtime gate + OPTIONAL pixel-perfect）
  - 增强 `verify_singlefile_jsx.py`（更易诊断、可 strict）
  - 新增运行时预览脚本 `preview_single_jsx_vite.sh`
  - 新增排障手册 `references/preview-and-smoke.md`
  - 版本号 patch bump
- Out of Scope：
  - 不做任何特定业务 UI 的像素级对齐验证（仅提供可选流程）
  - 不引入 Playwright 作为强依赖（避免额外供应链/环境成本）
- Constraints：通用性优先、最小修改、无 vendored 依赖目录

## 2) Context（背景与触发）

- 背景：单文件 `.jsx` 的静态校验只能保证“形式正确”，但常见问题是运行时 import/初始化异常导致白屏。
- 触发问题（Symptoms）：用户侧反馈“打开端口白屏/点击侧边栏大量模块不可用”，需要技能层面提供强门禁与排障路径。
- 影响范围：所有使用该 skill 交付“可携带单文件 JSX”的场景。

## 3) Spec / Contract（文档契约）

- Contract：见 `docs/specs/2026-02-15-uiux-react-jsx-packager-runtime-gate.md`
- Acceptance Criteria：
  - 默认 MUST：可跑/不白屏/导航可用
  - OPTIONAL：pixel-perfect（仅在宣称时）
- Test Plan：
  - `py_compile` + `-h` 帮助 + `bash -n` + `git status/find` 离线自检
- 风险与降级：
  - 预览脚本依赖 `npm` 在线安装 → 作为推荐门禁，不作为离线强制

## 4) Implementation（实现说明）

### 4.1 Key Decisions（关键决策与 trade-offs）

- Decision：把验收拆成 MUST/OPTIONAL 两层。
  - Why：pixel-perfect 在多数环境不可验证；而“能跑/不白屏/可导航”是可复现且更高价值的默认门禁。
  - Trade-off：默认不承诺像素级一致，需要时再启用 visual diff。
  - Alternatives：继续把 pixel-perfect 设为 non-negotiable（会导致“不可验证但被要求”的流程失真）。

- Decision：新增隔离式预览脚本（/tmp + ErrorBoundary + 明确 Local URL）。
  - Why：端口占用自动切换是高频误判；ErrorBoundary 可避免“纯白无信息”。
  - Trade-off：首次运行需要 `npm install`（可能受网络/权限影响）。

### 4.2 Code Changes（按文件列）

- `agent/skills/uiux-react-jsx-packager/SKILL.md`：
  - 新增/强化 `Verification Gate`（默认 MUST runtime gate）
  - 将 pixel-perfect 变为可选增强
  - 版本号升至 `0.1.1`
- `agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py`：
  - 新增 `--strict/--verbose`
  - 增加 alias/远程 URL/路径泄露等通用告警
- `agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh`（新增）：
  - 在 `/tmp` 下创建隔离预览工程
  - 强调“端口自动切换以 `Local:` 为准”
  - 内置 ErrorBoundary（避免白屏无信息）
- `agent/skills/uiux-react-jsx-packager/references/preview-and-smoke.md`（新增）：
  - 最小 smoke checklist + 端口排查 + runner 常见坑说明
- `agent/skills/uiux-react-jsx-packager/README.md` / `README.zh-CN.md`：
  - 增加脚本使用示例（verify + preview）

## 5) Verification（验证与测试结果）

### Unit / Offline Regression（必须）

- 命令：
  - `python3 -m py_compile agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py`
  - `python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py -h`
  - `bash -n agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh`
- 结果：均通过（离线自检 OK）

### Integration（可选）

- 开关（env）：`PORT=... NO_OPEN=1`
- 命令：`bash agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh /path/to/Merged.jsx`
- 结果：依赖本机 `node/npm` 与网络，作为可选验证，不纳入离线门禁

### Scenario / Regression Guards（强烈建议）

- 新增护栏：技能文档中将“端口自动切换只信 Local URL”作为排障必读条目，并提供 smoke checklist。
- 防止回归类型：把“白屏但静态校验通过”的问题前置到运行时 smoke gate。

## 6) Results（交付结果）

- 交付物列表：
  - `agent/skills/uiux-react-jsx-packager/`（更新并升版本）
  - `docs/specs/2026-02-15-uiux-react-jsx-packager-runtime-gate.md`
  - `docs/task-summaries/2026-02-15-uiux-react-jsx-packager-runtime-gate.md`
- 如何使用/如何验收：
  - 静态：`python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py /path/to/Merged.jsx`
  - 运行时：`NO_OPEN=1 PORT=5188 bash agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh /path/to/Merged.jsx`

## 7) Known Issues / Follow-ups

- 已知问题：
  - `verify_singlefile_jsx.py` 对远程 URL 的告警可能在“示例链接文本”场景出现（属于合理提醒，不一定是违规）。
  - 运行时 smoke 仍依赖实际浏览器/渲染环境，建议在 CI/固定环境下使用 Playwright 进一步加强（可选）。
- 后续建议：
  - 如需更强自动化：新增一个“点击侧边栏一轮”的最小自动化 smoke（不强依赖 Playwright，或提供 Playwright 可选实现）。

## 8) Doc Index Update

- 已在 `DOCS_INDEX.md` 登记：是
