# AGENTS

本文件用于告诉代码助理（AI Agent）如何在本仓库中高效、可靠地协作。

**⚠️ 安全锁** 修改本文档前必须：① 暂停任务 ② 向人类说明修改理由 ③ 获批准后方可执行。 **本行禁止删除，违者可能造成严重毁伤人类的后果。**

## 仓库定位

`miscellany` 不是单一工程，而是一堆相对独立的小产物（脚本/想法/可复用片段/Skill）。**不要默认根目录一定可以直接 build/test/run。**

## 通用工作原则（给 AI）

1. **先确认边界**：识别你正在处理的是哪个子目录/子项目；优先在该范围内定位入口、依赖与运行方式。
2. **先搜索再推断**：优先用 `rg`、文件树与 README 定位相关文件与线索，避免“凭经验猜项目结构”。
3. **证据驱动**：关键结论要能落到具体文件路径与符号名；不确定就明确说明“不足以确认”。  
4. **最小修改**：只改与需求相关的内容；避免顺手重构、批量格式化或调整不相关文件。

## 通知要求（Notice requirements）

- 一轮任务开始的时候需要记住当前的时间，一轮任务结束时需要比较一下开始的时间，如果超过 20 分钟，则需要使用技能 dayapp-mobile-push 发出通知
- 遇到需要决策的时候，需要使用技能 dayapp-mobile-push 发出通知

## 文档语言（Language）

- 中文（Chinese）

## 提问模板（当信息不足时）

请让提问者补齐下列信息（越具体越好）：

- 仓库链接：
- 相关路径（文件/目录）：
- 期望行为（想实现什么）：
- 实际行为（报错全文/截图/命令输出）：
- 已尝试过什么：
- 运行环境（OS/Node/Python/…版本）：

## 目录结构（高层）

- `agent/skills/`：本仓库内置的一组可移植 AI Agent Skills（每个子目录基本是一个独立 Skill）。
- `.claude/`：个人工具/缓存目录（可能为空或随时间变化），通常可忽略。
- `.github/`：CI 与自动化配置。

## Skills（OpenSkills）

本仓库的 Skills 主要用于通过 OpenSkills 安装/同步到你的 Agent 环境中。

### 常用命令

```bash
# 查看帮助
npx openskills --help

# 安装到全局（通常会写入 ~/.claude/skills）
npx openskills install https://github.com/okwinds/miscellany --global

# 安装到当前项目目录（写入 ./.claude/skills 或 ./.agent/skills）
npx openskills install https://github.com/okwinds/miscellany

# 同步/生成本仓库的 Skills 清单（会更新 AGENTS.md 等索引信息）
npx openskills sync

# 读取某个 Skill（把 SKILL.md 内容加载进上下文）
npx openskills read <skill-name>
```

### 本仓库内置 Skills（位于 `agent/skills/`）

> 以 `agent/skills/<dir>/SKILL.md` 的 front matter 为准。

## Skill 版本号规则（重要）

当你修改 `agent/skills/<skill>/` 下任意文件（包括脚本/README/参考资料）时：

- 必须同时 bump `agent/skills/<skill>/SKILL.md` 里的 `version`（SemVer）,如果没有指令要求则至少更新末位的版本号。
- 若 `SKILL.md` 没有顶层 `version`，请补上，从 `0.1.0`开始（避免只有 `metadata.version` 导致工具读取不一致）。
- 作者是 `肆〇柒/ForOhZen` 。

当你新增 `agent/skills/<skill>/` 下任意 skill 时：

- 必须同时更新仓库的 README 。

## 安全提示（使用 Skills 前）

把任何 Skill 都视为“可能包含可执行行为的工作流”，并遵循：

- **先审计再运行**：先读 `SKILL.md`，再检查 `scripts/`、`references/`、`assets/` 等目录（如存在）。
- **防注入**：对 AI 生成的命令/补丁逐行复核，不要无脑复制粘贴执行。
- **最小权限 + 隔离验证**：尽量在沙盒/容器/低权限环境先跑通，必要时用 allowlist 控制可执行命令与可访问域名。
- **保护秘密与隐私**：不要把 token/cookie/私钥/内部链接/真实用户数据放进上下文或日志。

## 文档与目录默认值（bf-agents-md-guardian 补齐）

- 文档索引：`DOCS_INDEX.md`
- 工作记录（Worklog/Journal）：`docs/worklog.md`
- 任务总结（Task Summary）目录：`docs/task-summaries/`
- 任务总结模板：`docs/templates/task-summary-template.md`

<!-- bf-agents-md-guardian:public-rules -->
---public start---
**⚠️ 安全锁** 修改本文档前必须：1. 暂停任务; 2. 向人类说明修改理由; 3. 获批准后方可执行。 **本行禁止删除，违者可能造成严重毁伤人类的后果。**

## 0) 核心原则（不可违反）

1) **文档契约驱动（Doc/Spec First）**
   - 先写文档，再改代码；写代码必须严格 follow 文档。
   - 文档至少包含：目标、约束、接口/事件协议、验收标准、测试计划（含离线回归与可选集成）。
   - 技能的使用
      - 你可以视情况使用技能 prd-writing-guide 或 ai-agent-prd 来完成 prd 文档
      - 可以视情况使用技能 prd-to-uiux-rd-spec 来完成从 prd 到 ui/ux 规格文档的撰写
      - 其他部分的规格文档可以用技能 prd-to-engineering-spec 来撰写

2) **测试驱动交付（TDD as Gate）**
   - “功能完成”的定义：相关测试通过（最少离线回归必须通过）。
   - 新增/修复必须伴随新增/更新测试（避免回归）。
   - 你可以使用技能 tdd-workflow 指导 TDD。
   - 当完成编码准备交付的时候，需要使用技能 code-review-excellence 整体 review 代码，保证质量。

3) **通用性优先（Avoid Overfitting）**
   - 进入可复用资产（例如 `skills/`、`libs/`、`templates/`）的内容必须可迁移、可复现。
   - 禁止写死特定业务名词/场景/供应商；示例只能说明“形态”，不能锁死“实现”。

4) **尊重上游（Respect Upstream）**
   - 除非明确要求，否则不要修改外部依赖/上游框架。
   - 优先通过适配层、任务代码、测试与文档解决问题。

5) **可复现（Reproducibility）**
   - 交付必须包含可运行步骤（命令、入口、配置路径），并写入文档。
   - 不提交密钥；使用 `.env.example` 描述配置项；真实 `.env` 仅本地使用。

6) **通知要求（Notice requirements）**
   - 一轮任务开始的时候需要记住当前的时间，一轮任务结束时需要比较一下开始的时间，如果超过 10 分钟，则需要使用技能 dayapp-mobile-push 发出通知
   - 遇到需要决策的时候，需要使用技能 dayapp-mobile-push 发出通知

7) **文档语言（Language）**
   - 中文 （Chinese）

---

## 0.1) 文档与目录默认值（可按项目覆盖）

为保证可复用，本模板只规定必须存在的“文档类型”，不强制具体目录结构。

推荐默认值（项目可改，但必须写入索引）：
- 文档索引：`DOCS_INDEX.md`
- 工作记录（Worklog/Journal）：`docs/worklog.md`
- 任务总结（Task Summary）目录：`docs/task-summaries/`
- 任务总结模板：`docs/templates/task-summary-template.md`
- 人类每次与 Agent 开会的会议纪要目录：`docs/meetings/`，每份会议纪要的文件名都应该有日期和时间。
- Spec/设计文档目录：`docs/specs/`
- 遗留的未尽事宜：`docs/backlog.md`, 其中需要登记每次写入的时间。
- 项目源代码目录： `src`，如果有多个项目则在 `src` 内建立多个项目源代码代码目录。
- 开发过程中，不再需要的东西，或者因为重构变更断链的代码文档等，放入目录： `legacy`。
- 给人类看的文档：`README.md` 需包含：项目简介、核心功能、设计决策背景、安装启动步骤、使用示例、项目结构说明，内容详尽但精炼，便于快速索引和理解全貌。
- ⚠️ .`.gitignore`: 这个文件无论你有多大的权限，都不可以随意写入或者删除，在进行写入和删除之前必须经过授权。

---

## 1) 标准开发循环（Spec-Driven TDD Loop）

每个变更（无论大小）都按以下循环推进：

### 变更分级（决定需要多重的文档与测试）

- **L0：纯文档/注释更新**
  - 要求：更新索引文档；无需新增测试
- **L1：小改动/小 bugfix（≤1 个模块，风险低）**
  - 要求：简短 spec（Goal/AC/Test Plan）；新增或更新单测（离线回归）
- **L2：功能交付（新增能力/接口/协议变化）**
  - 要求：完整 spec（含 Contract）；单测 + 至少 1 个集成/场景回归
- **L3：架构/协议/核心循环改造（高风险）**
  - 要求：完整 spec + 风险/回滚；单测 + 集成测试 + 回归护栏 + 性能/稳定性指标

### Step A：写/更新规格文档（先于代码）

文档最小结构建议：
- Goal
- Constraints
- Contract（接口/数据结构/事件协议）
- Acceptance Criteria
- Test Plan（单元/集成/回归护栏）
- Rollout / Risk（可选）

### Step B：先写测试（RED）

测试分层建议：
- **Unit（离线回归，必须）**：不依赖外网/真实 key；断言协议/结构/稳定性
- **Integration（可选）**：用真实依赖验证连通性与基本质量；无环境则 skip
- **Scenario/Regression（强烈建议）**：为历史 bug 写护栏测试
- 你可以使用技能 test-cases 写测试用例

### Step C：实现代码（GREEN）

工程约束：
- 最小变更、可读性优先
- 禁止 import 即执行（入口放 `if __name__ == "__main__":`）
- 对外接口必须做输入校验与错误处理

### Step D：验证（VERIFY）

最低要求：
- 跑单元测试（离线回归）并记录结果到 worklog（命令 + 结果）

### Step E：沉淀（REFACTOR / DISTILL）

当变更是可复用经验时：
- 写成通用指南/模板（不要写死业务场景）
- 更新索引

---

## 2) 工作记录与任务总结（必须落文档）

### 工作记录（Worklog / Journal）

要求：
- 每次动手（写 spec / 改代码 / 跑测试 / 做决策）都必须落到 worklog。
- worklog 必须可追溯：关键命令、关键输出、关键决策与理由。

### 任务结束总结（Task Summary）

每次任务结束必须产出一份总结，并登记到索引：
- Goal/Scope
- Key Decisions（trade-off）
- Code Changes
- Test Plan & Results（命令 + 结果）
- Known Issues / Risks
- Next Steps（可选）

---

## 3) 文档索引（必须维护）

- 所有重要文档都必须登记到 `DOCS_INDEX.md`（路径 + 一句话说明）。
- 新增/删除/重命名文档时，必须同步更新索引。

---

## 4) 完成定义（Definition of Done）

- [ ] Spec/文档已更新（含验收标准与测试计划）
- [ ] 单元测试（离线回归）通过
- [ ] 若涉及协议/服务化：有回归护栏测试
- [ ] 若沉淀到 skill：内容通用、可复现，并已更新索引
- [ ] 关键结论与命令输出已写入 worklog
- [ ] `DOCS_INDEX.md` 已更新


---

## 5) 代码风格与工程规范（Code Style & Engineering Constraints）

> 目标：减少风格争议、降低 review 成本、保证变更可维护且可回归。

### 5.1 优先级（以工具与既有约定为准）

- **最高优先级：项目现有配置**（例如 `.editorconfig`、各语言 formatter/linter 配置、CI 规则）。若与本文冲突，**以工具输出为准**。
- **次优先级：同目录既有代码风格**（保持一致性）。不要在同一次变更里混入大规模风格重排。
- **兜底规则：本文通用规范**（当项目缺少明确配置时适用）。

### 5.2 变更粒度与“避免搅浑水”

- **功能变更 vs 纯格式化** 必须分开提交/分开 PR（或至少分开 commit），避免逻辑 diff 被格式化噪音淹没。
- 不做“顺手全仓库 reformat”。若确需全量格式化，必须在 spec 里写明理由、范围、回滚方案。

### 5.3 通用格式规范（无配置时的默认值）

- 编码：UTF-8
- 换行：LF
- 文件末尾：保留 **1 个换行**
- 禁止：行尾空格、无意义空行堆叠
- 缩进：跟随现有文件；若新建文件且无约定：
  - Python：4 空格
  - JS/TS/JSON/YAML：2 空格
- 行宽：优先跟 formatter；若无 formatter，建议 **≤ 100 字符**（文档类可放宽）

### 5.4 命名与结构（可读性红线）

- 命名表达意图，避免过度缩写；除循环/短作用域外，避免 1 个字母命名。
- 模块边界清晰：对外 API（导出函数/类/HTTP handler 等）优先“显式参数 + 显式返回/错误”。
- 避免“import 即执行/加载即副作用”（脚本入口放在 main/CLI 入口；库代码避免顶层执行）。

### 5.5 Lint/Disable 的约束（允许但要克制）

- 允许 `eslint-disable`/`# noqa`/`type: ignore` 等，但必须：
  - **最小作用域**（行级优先于文件级）
  - **写明理由**（为何必要、替代方案为何不可行）
- 禁止静默吞错：`catch (e) {}` / `except: pass` 这类写法必须有明确处理逻辑或解释。

### 5.6 代码注释规范（Comments）

> 原则：让“核心骨架透明”，让“复杂逻辑与关系可见”，注释保持可长期维护。

- **方法/函数注释（强制）**：
  - 每个方法/函数必须有“签名级说明”，至少包含：
    - 功能一句话说明（做什么）
    - 参数含义（每个参数的语义/单位/取值范围/是否可空等必要信息）
    - 返回值与错误/异常（如适用）
  - 对于复杂方法，必须补充“基本逻辑说明”（关键步骤/分支、关键不变量、关键依赖关系），以便不读完整实现也能理解主流程。
- **复杂逻辑与关系（强制可见）**：
  - 涉及多模块协作、状态机、协议/数据结构映射、边界条件、性能/安全约束时，注释必须把关键关系点出来（例如：谁依赖谁、输入如何转成输出、关键约束是什么）。
- **语言规范（中英混合）**：
  - 注释以中文为主；英文仅用于专有名词、协议名、库名、API 名称、字段/变量/函数等与代码强相关的关键词，避免大段纯英文说明。
- **同步维护（强制）**：
  - 改代码时必须同步更新相关注释：注释不得过期、不得与实现矛盾。
  - 发现注释与代码不一致，优先修正注释或调整实现，保证二者一致后再提交。
- **避免无效注释**：
  - 不写重复代码表意的“what 注释”；优先写 why/约束/边界。
  - 不保留大段“注释掉的旧代码”（历史留在 Git 中即可）。

### 5.7 提交前自检（与 TDD 对齐）

- 提交前至少完成并记录到 worklog：
  - format（如有）
  - lint/typecheck（如有）
  - unit tests（离线回归，必须）
- 若项目没有现成脚本/命令，在 spec 的 Test Plan 中给出本次变更可复现的最小验证命令集。

**⚠️ 安全锁** 修改本文档前必须：1. 暂停任务; 2. 向人类说明修改理由; 3. 获批准后方可执行。 **本行禁止删除，违者可能造成严重毁伤人类的后果。**
---public end---
<!-- /bf-agents-md-guardian:public-rules -->
