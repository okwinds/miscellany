# repo-compliance-audit

对任意代码仓库进行合规审计并生成可取证报告（Markdown + JSON findings），覆盖“是否遵循 AGENTS.md/仓库规则/用户指令”“文档索引/规格/工作记录/任务总结”“TDD 与离线回归证据”“可复现性（.env.example 等）”“潜在密钥泄露与仓库卫生”等；并支持在**人类勾选 finding.id** 后执行选择性低风险整改（默认不改业务逻辑）。触发场景：仓库交付前自检、接手陌生仓库、需要合规审计报告、需要把整改条目做成可选择的执行清单。

## What's included

- `SKILL.md`
- `scripts/` (optional)
- `references/` (optional)
- `assets/` (optional)

## Installation

> Installing a skill means your coding tool / agent runner can discover the `SKILL.md` inside it (typically via a `skills/` directory, or via a built-in “install from Git” feature).

### Option A: copy

From this repo root:

Set `SKILLS_DIR` to whatever skills folder your tool scans (examples: `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-compliance-audit"
cp -R agent/skills/repo-compliance-audit "$SKILLS_DIR/repo-compliance-audit"
```

### Option B: symlink

From this repo root:

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-compliance-audit"
ln -s "$(pwd)/agent/skills/repo-compliance-audit" "$SKILLS_DIR/repo-compliance-audit"
```

### Option C: install from GitHub/Git via openskills

Prereqs for openskills:

- Requires Node.js (18+ recommended).
- No install needed if you use `npx openskills ...` (it will download and run).
- Optional global install: `npm i -g openskills` (or `pnpm add -g openskills`).

Install from a cloneable repo URL (do **not** use a GitHub `.../tree/...` subdirectory link):

```bash
npx openskills install https://github.com/okwinds/miscellany
```

When prompted, select `repo-compliance-audit` (repo path: `agent/skills/repo-compliance-audit`).

Verify / read back:

```bash
npx openskills list
npx openskills read repo-compliance-audit
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/repo-compliance-audit`.

### After install

Many tools require a restart / new session to re-scan skills.

## Usage

Run scripts from inside the skill directory.

From the installed skill directory:

```bash
cd /path/to/repo-compliance-audit
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit
```

After installing to a skills directory:

```bash
cd "$SKILLS_DIR/repo-compliance-audit"
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit
python3 scripts/remediate_repo.py --repo . --findings /tmp/repo-compliance-audit/findings.json --select DOCS_INDEX_MISSING,ENV_EXAMPLE_MISSING
```
