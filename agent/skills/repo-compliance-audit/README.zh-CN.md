# repo-compliance-audit

对任意代码仓库进行合规审计并生成可取证报告（Markdown + JSON findings），覆盖“是否遵循 AGENTS.md/仓库规则/用户指令”“文档索引/规格/工作记录/任务总结”“TDD 与离线回归证据”“可复现性（.env.example 等）”“潜在密钥泄露与仓库卫生”等；并支持在**人类勾选 finding.id** 后执行选择性低风险整改（默认不改业务逻辑）。触发场景：仓库交付前自检、接手陌生仓库、需要合规审计报告、需要把整改条目做成可选择的执行清单。

## 包含内容

- `SKILL.md`
- `scripts/`（可选）
- `references/`（可选）
- `assets/`（可选）

## 安装

> 安装 skill 的本质是：让你的编码工具 / Agent 运行器能发现这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或使用工具内置的“从 Git 安装”能力）。

### 方式 A：复制安装

在仓库根目录执行：

把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（示例：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-compliance-audit"
cp -R agent/skills/repo-compliance-audit "$SKILLS_DIR/repo-compliance-audit"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-compliance-audit"
ln -s "$(pwd)/agent/skills/repo-compliance-audit" "$SKILLS_DIR/repo-compliance-audit"
```

### 方式 C：用 openskills 从 GitHub/Git 安装

先准备 openskills：

- 需要 Node.js（建议 18+）。
- 不想安装：直接用 `npx openskills ...`（会自动下载并运行）。
- 想全局安装：`npm i -g openskills`（或 `pnpm add -g openskills`）。

从**可 clone 的仓库 URL** 安装（不要用 GitHub 的 `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany
```

安装时选择 `repo-compliance-audit`（仓库内路径：`agent/skills/repo-compliance-audit`）。

验证/读取：

```bash
npx openskills list
npx openskills read repo-compliance-audit
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/repo-compliance-audit`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 用法

建议在 skill 目录内运行脚本。

在已安装的 skill 目录中：

```bash
cd /path/to/repo-compliance-audit
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit
```

安装到 skills 目录后：

```bash
cd "$SKILLS_DIR/repo-compliance-audit"
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit
python3 scripts/remediate_repo.py --repo . --findings /tmp/repo-compliance-audit/findings.json --select DOCS_INDEX_MISSING,ENV_EXAMPLE_MISSING
```
