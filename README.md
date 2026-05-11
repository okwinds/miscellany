# miscellany

## Let it be

这个仓库是一堆“碎碎念”：用来托管一些琐碎的成果/脚本/想法/可复用片段，避免未来自己（或路过的人）想找的时候找不到。

## For AI（先写给 AI）

你看到的不是一个“单一工程”，而是一堆彼此独立的小东西。请按下面规则工作：

> 注意：`docs/` 与 `DOCS_INDEX.md` 属于本地协作文档（不随开源发布），默认已在 `.gitignore` 中排除；如你在自己的 fork/私有协作中需要它们，可以按需自行创建。

1. **先识别子项目/子目录的边界**：不要默认根目录可直接 `build/test/run`。
2. **优先搜索而不是猜**：用 `rg`/文件树定位与问题相关的文件，再开始分析。
3. **如果来访者遇到问题**：让 TA 贴出「链接 + 相关路径 + 目标行为 + 实际行为/报错日志」，你通常就能给出可执行的解决方案。

### 给来访者的提问模板（复制给 AI）

把下面内容填好，直接丢给 AI（越具体越好）：

- 仓库链接：
- 相关路径（文件/目录）：
- 你想实现什么/期待发生什么：
- 实际发生了什么（报错全文/截图/命令输出）：
- 你已经尝试过什么：
- 运行环境（OS/Node/Python/…版本）：

## 结构（Structure）

- `agent/skills/`：一些可移植的「AI Agent Skill」包（每个子目录基本都是一个独立技能）。
  - `agent/skills/brainstorming/`：将模糊想法转化为已验证的设计/规格。用于任何创造性工作之前（新功能、UI/组件、行为变更、重构），以及用户要求头脑风暴、定义需求、提出方案或编写设计文档时。(来自 `superpowers:brainstorm`)
  - `agent/skills/headless-web-viewer/`：用 Playwright 无头渲染网页、提取可见文本/截图。
  - `agent/skills/repo-deep-dive-report/`：生成"读仓库深度报告"的工作流（Markdown + 离线 HTML）。
  - `agent/skills/repo-compliance-audit/`：对任意代码仓库进行合规审计并生成可取证报告（Markdown + JSON findings），支持人类勾选 `finding.id` 后执行选择性整改（默认不改业务逻辑）。
  - `agent/skills/skill-review-audit/`：对任意 Skill 目录做系统性审计（触发契约、工具/副作用、风险与改进建议）。
  - `agent/skills/codebase-spec-extractor/`：从既有代码库提炼可复刻的工程规格（inventory + spec skeleton + verification），脚本用于**辅助发现缺口**而非“完整性证明”。
  - `agent/skills/prd-writing-guide/`：写出完整、无歧义、可直接交付研发落地的 PRD（含需求发现问题清单、结构化模板、完整性检查与常见坑位）。
  - `agent/skills/prd-to-engineering-spec/`：把 PRD 转成可落地的工程规格（架构/数据/API/安全/运维/测试/任务拆分），并提供生成骨架与完整性校验脚本。
  - `agent/skills/prd-to-uiux-rd-spec/`：从产品 PRD 产出“复刻级可落地”的 UI/UX 研发规格文档包（目录同构骨架、公共基座、组件/页面契约、覆盖映射、索引与 worklog）。
  - **离线文档操作套件（`*-offline`）**：一组偏“本地读写/编辑/回包/格式保真”的 Office/PDF 工作流（安装依赖可能需要网络，但运行阶段不依赖在线服务）。
    - `agent/skills/pdf-offline/`：PDF 读写/合并拆分/表单处理（含 `doc_utils.py` 快捷 CLI）。
    - `agent/skills/xlsx-offline/`：Excel 读写 + LibreOffice 公式重算与错误扫描（默认隔离 profile，减少污染）。
    - `agent/skills/docx-offline/`：DOCX 读写 + OOXML 解包编辑回包 + redlining（修订/批注）。
    - `agent/skills/pptx-offline/`：PPTX 读写 + OOXML 工作流 + html2pptx（HTML→PPT）+ 缩略图/替换/重排脚本。
    - `agent/skills/offline-office-migration.md`：套件总览与触发建议。
  - `agent/skills/ui-ux-spec-genome/`：构建一套可复刻、可移植的 UI/UX 规范"基因"：扫描 UI 源并生成 `ui-ux-spec/` 文档包骨架，用于规范提取与 UI-only 分阶段改造。
  - `agent/skills/uiux-react-jsx-packager/`：把现有 React UI Demo 打包成单文件 `*.jsx`（默认导出根组件、运行时只依赖 React），内联 CSS/SVG/图片，用 state 实现导航，并提供本地校验脚本。
  - `agent/skills/agently-task-dev/`：Agently 框架专用开发技能，生成可运行代码 + 回归测试（验证 schema/ensure_keys 和流式响应 delta/instant/streaming_parse），支持 ToolExtension（Search/Browse/MCP）、TriggerFlow 编排、ChromaDB 知识库，以及 SSE/WS/HTTP 服务化。
  - `agent/skills/bf-caprt-dev/`：以 `capability-runtime` 作为业务真相源的落地技能，指导用 Runtime public surface、PromptRenderMode、多模态 prompt boundary、NodeReport、usage metadata 与 service/session surfaces 交付 capability / agent / workflow。
  - `agent/skills/bf-skillsruntime-dev/`：围绕 Skills Runtime SDK 的业务开发技能，覆盖单 agent、Skills-First 注入、多 agent 协作、WAL/审批/恢复与脚手架生成。
  - `agent/skills/skill-create-flow/`：Skill 创建流程：从模糊想法到可测试的技能规格。适合创建基于流程的 Agent 技能（如方法论型、决策型、多步骤工作流），而非纯参考/查询型技能或简单命令。
  - `agent/skills/skill-creator-cc/`：Skill 开发/评测工作台：用于从零创建或改进 skill，生成评测样例、对比 with-skill / baseline、用 review viewer 做人工审阅，并迭代优化 skill description 的触发效果。
  - `agent/skills/loopback/`：Loopback 迭代开发循环：受 Claude Code 的 Ralph Loop（`ralphloop`/`ralph-loop`）启发的 Codex 适配版，用“同一句 prompt 多轮迭代 + 停止契约”让任务更收敛。
  - `agent/skills/dayapp-mobile-push/`：通过 Day.app（Bark）发送一次关键移动端推送。适用于任务完成、失败、阻塞等需要立即提醒的场景，并支持静音时段。
  - `agent/skills/codex-tmux-echo/`：通用 tmux 交互编排 + 回传：启动交互式 CLI、发送按键、等待输出，并支持 worker 回传到 controller pane（避免靠 `sleep` 猜时序）。
  - `agent/skills/codeflow-analyzer/`：追踪并记录代码库中任意功能或流程的完整调用链/数据流，从入口点到最深依赖，生成结构化分析文档。
- `.claude/`：个人工具的工作目录（可能为空/随时间变化），通常可忽略。
- `LICENSE`：默认许可证。

> 具体每个技能怎么装、怎么用：直接看对应目录下的 `README.md` / `SKILL.md`。

## 安装 Skills（OpenSkills）

本仓库的可安装 Skills 位于 `agent/skills/`（每个子目录包含 `SKILL.md`）。推荐使用 [OpenSkills](https://github.com/numman-ali/openskills) 来安装/同步/加载这些技能。

## Skill 版本号（Versioning）

- 每个 Skill 的 `SKILL.md` 顶部 YAML front matter 里包含 `version: MAJOR.MINOR.PATCH`（SemVer）。
- **只要修改了 `agent/skills/<skill>/` 下任意文件（包括脚本/README/参考资料），就必须同时 bump 该 Skill 的 `version`**。
- 仓库内置 CI（GitHub Actions）会在 PR / push 时检查：有改动但未 bump 版本会直接失败。
- **新增 Skill 到 `agent/skills/` 时，需要同步更新仓库根 `README.md` 的 Skills 清单**（目前请手动维护该清单）。

### 风险提示（使用 Skills 前必读）

Skills 本质上是一段“可执行的工作流/提示词 + 脚本/工具调用约定”。它们可能会触发（或引导你触发）诸如：运行命令、读写文件、联网请求、安装依赖、抓取第三方内容等行为。

使用任何 Skill（包括本仓库的）前，请默认它是**不可信输入**，并遵循以下安全原则：

1. **先审计再使用**：阅读 `SKILL.md`，检查 `scripts/`、`references/`、`assets/` 等目录（如果存在），确认具体会用哪些工具、执行哪些命令、访问哪些外部资源/域名、以及可能产生的副作用（写盘/删改文件/网络请求等）。
2. **防提示词注入/工具注入（Prompt/Tool Injection）**：Skill 内容或它抓取的网页/文档可能夹带“诱导指令”，让你执行危险命令、扩大权限、泄露密钥、修改敏感文件。对 AI 生成的命令/补丁/脚本**逐行复核**，不要“复制粘贴就跑”。
3. **最小权限 + 隔离运行**：优先在容器/沙盒/低权限账号里验证；对涉及网络、写文件、执行命令的 Skill，建立明确的允许清单（allowlist）；不要在含生产凭据/真实数据的环境里直接运行。
4. **保护秘密与隐私**：不要把 token、cookie、私钥、内部链接、用户数据等放进上下文或日志；必要时用假数据或环境变量注入，并确保不会被打印/上传到第三方服务。

如果你希望更系统地审计一个 Skill：可以先用 `agent/skills/skill-review-audit/` 对目标目录做审计，确认风险点与改进建议后再安装/启用。

以上仅覆盖常见风险点，不保证穷尽所有场景；请结合你的运行环境与数据敏感性自行评估。

当然，也欢迎你把这些技能当成“可复用素材库”随意取用：有问题提 Issue，想改进就直接 PR。

### 前置条件

- Node.js 20.6+（OpenSkills 的要求）
- Git（用于从 GitHub 拉取）

### 安装 OpenSkills（如果你本地没有）

你可以直接用 `npx` 运行（无需提前安装）：

```bash
npx openskills --help
```

或者全局安装（可选）：

```bash
npm i -g openskills
```

### 安装本仓库的 Skills

安装到全局（Claude Code 默认目录 `~/.claude/skills`）：

```bash
npx openskills install https://github.com/okwinds/miscellany --global
```

如果你同时在用多个 Agent，希望走通用目录（`~/.agent/skills`），加上 `--universal`：

```bash
npx openskills install https://github.com/okwinds/miscellany --universal --global
```

安装到当前项目（写入 `./.claude/skills` 或 `./.agent/skills`）：

```bash
npx openskills install https://github.com/okwinds/miscellany
# 或：npx openskills install https://github.com/okwinds/miscellany --universal
```

安装后，在你的项目目录生成/更新 `AGENTS.md`（让 Agent “看见”这些技能）：

```bash
npx openskills sync
```

需要让 AI “加载”某个技能时（用于把技能内容读进上下文）：

```bash
npx openskills read headless-web-viewer
```

## For Human（最后写给人类的碎碎念）

如果你逛到这里：欢迎随便翻。这里不追求“统一风格”或“完整产品形态”，更多是为了把零散产物放在一个能被搜索、能被引用、能被 AI 理解的地方。
