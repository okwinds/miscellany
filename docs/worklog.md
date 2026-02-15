# Worklog Template (Universal)

> 用途：通用工作记录模板（可复制到任意仓库）。  
> 推荐落地路径：`docs/worklog.md`（或 `docs/journal.md`），并在 `DOCS_INDEX.md` 登记。

规则：
- 按时间顺序追加（append-only），不要频繁重写历史。
- 记录必须可追溯：命令、关键输出、关键决策与理由。
- 不记录敏感信息（API key、token、私密数据）；必要时用占位符 `***`。

---

## Log Entry (copy/paste per step)

### Timestamp

- When: `YYYY-MM-DD HH:MM`
- Who: `human / agent`
- Context: `short description`

### Goal (this step)

- Goal:
- Constraints:

### Action

- Files touched:
  - `path/to/file`
- Commands run:
  - `...`

### Result

- Outcome:
- Key output/snippet (optional, short):

### Decision (if any)

- Decision:
- Why:
- Alternatives considered:

### Next

- Next step:
- Risks/Notes:

---

## Suggested Sections (optional)

如果你希望 worklog 更易检索，可以在文件顶部加一个简短目录：
- `## 2026-02-03`（按日期分段）
- `### Feature: ...` / `### Bugfix: ...`

---

## 2026-02-13

### Task: open-source uiux-react-jsx-packager

#### Timestamp

- When: `2026-02-13 18:58` (+0800)
- Who: `agent`
- Context: 将本地 `uiux-react-jsx-packager` skill 发布到仓库 `agent/skills/` 并补齐文档索引

#### Goal (this step)

- Goal：发布 skill + 更新 README/索引
- Constraints：最小修改、可复现、不提交敏感信息

#### Action

- Files touched:
  - `agent/skills/uiux-react-jsx-packager/`（新增）
  - `README.md`
  - `DOCS_INDEX.md`
  - `docs/worklog.md`
  - `docs/specs/2026-02-13-uiux-react-jsx-packager-open-source.md`
  - `docs/task-summaries/2026-02-13-uiux-react-jsx-packager-open-source.md`
- Commands run:
  - `python3 /Users/okwinds/.claude/skills/skill-open-source/scripts/publish_skill.py --source /Users/okwinds/.claude/skills/uiux-react-jsx-packager --dest agent/skills/uiux-react-jsx-packager --overwrite --write-readmes --normalize-paths`
  - `python3 -m py_compile agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py`

#### Result

- Outcome：skill 已复制到 `agent/skills/uiux-react-jsx-packager/`，并补齐 `SKILL.md` 的 `version/author` 与双语 README 的 Usage 段落。
- Key output/snippet (optional, short)：`py_compile ok`

#### Decision (if any)

- Decision：使用 `publish_skill.py` 自动发布，再进行少量人工补齐（version/author、Usage）。
- Why：减少手工遗漏（排除 vendored 目录、路径归一化、README 骨架）。

#### Next

- Next step：更新 `DOCS_INDEX.md` 登记新增文档；检查 `git status`；通过 Day.app 推送通知。
- Risks/Notes：注意 README 的安装路径示例保持工具无关。

---

## 2026-02-15

### Task: uiux-react-jsx-packager runtime gate hardening

#### Timestamp

- When: `2026-02-15 19:05` (+0800)
- Who: `agent`
- Context: 将 `uiux-react-jsx-packager` 的“可携带可跑/不白屏/导航可用”作为默认门禁，并补齐运行时 smoke 预览脚本与排障手册

#### Goal (this step)

- Goal：提升 skill 的可复现性与“白屏”排障效率；补齐 runtime gate；升小版本
- Constraints：变更必须通用，不绑定具体项目/脚本；最小修改；不引入 vendored 依赖目录

#### Action

- Files touched:
  - `agent/skills/uiux-react-jsx-packager/SKILL.md`
  - `agent/skills/uiux-react-jsx-packager/README.md`
  - `agent/skills/uiux-react-jsx-packager/README.zh-CN.md`
  - `agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py`
  - `agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh`（新增）
  - `agent/skills/uiux-react-jsx-packager/references/preview-and-smoke.md`（新增）
- Commands run:
  - `python3 /Users/okwinds/.claude/skills/skill-open-source/scripts/publish_skill.py --source /Users/okwinds/.claude/skills/uiux-react-jsx-packager --dest agent/skills/uiux-react-jsx-packager --overwrite --write-readmes --normalize-paths`
  - `python3 -m py_compile agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py`
  - `python3 agent/skills/uiux-react-jsx-packager/scripts/verify_singlefile_jsx.py -h`
  - `bash -n agent/skills/uiux-react-jsx-packager/scripts/preview_single_jsx_vite.sh`

#### Result

- Outcome：
  - `SKILL.md` 默认门禁分层：MUST=可跑/不白屏/导航可用；pixel-perfect 改为“宣称时才要求”的可选增强。
  - `verify_singlefile_jsx.py` 增强：支持 `--strict/--verbose`，并加入 alias/远程 URL/路径泄露等通用告警。
  - 新增预览脚本 `preview_single_jsx_vite.sh` 与排障手册 `references/preview-and-smoke.md`（强调“端口自动切换只信 Local URL”）。
  - `agent/skills/uiux-react-jsx-packager/SKILL.md` 版本号升至 `0.1.1`。
- Key output/snippet (optional, short)：`py_compile ok`

#### Decision (if any)

- Decision：把“运行时 smoke gate + 端口误判排障”写进 skill 的默认验收与脚本工具链。
- Why：静态校验无法覆盖“import/初始化抛错导致白屏”等问题；端口占用自动切换是高频误判来源。

#### Next

- Next step：补齐本次 spec/task summary 到 `docs/` 并更新 `DOCS_INDEX.md`；检查 `git status`。
- Risks/Notes：预览脚本依赖 `node/npm`，且首次运行会安装 Vite（可选门禁，不作为离线强制项）。
