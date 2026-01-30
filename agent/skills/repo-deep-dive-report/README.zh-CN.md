# Repo Deep Dive Report（代码仓库深度走读报告）

一套“证据驱动”的代码仓库走读流程，用于产出结构化交付物（Markdown + 离线可打开的 HTML），包含 Mermaid 图、可操作的改进建议以及评分表。

## 包含内容

- `SKILL.md`：完整流程与质量门槛
- `references/`：报告大纲、Mermaid 模板、评分口径
- `scripts/repo_snapshot.py`：生成仓库快照（仅标准库）
- `scripts/render_md_to_html.py`：将 Markdown 报告渲染为离线 HTML（仅标准库）

## 安装到 Codex / Claude Code

> 这一份目录本身就是“技能包”。安装的本质是：把整个目录放进你的工具会扫描的 `skills/` 目录里（保持目录名不变、保留 `SKILL.md`）。

### 方式 A：复制安装（推荐给新手）

在本仓库根目录执行（二选一：`~/.codex/skills` 或 `~/.claude/skills`）：

```bash
SKILLS_DIR=~/.codex/skills   # 或 ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
cp -R agent/skills/repo-deep-dive-report "$SKILLS_DIR/repo-deep-dive-report"
```

### 方式 B：软链接安装（适合开发/同步更新）

```bash
SKILLS_DIR=~/.codex/skills   # 或 ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
ln -s "$(pwd)/agent/skills/repo-deep-dive-report" "$SKILLS_DIR/repo-deep-dive-report"
```

### 安装完成后怎么“用”

- 通常需要**重启/新开** Codex 或 Claude Code 会话，让它重新扫描 skills。
- 然后在对话里直接描述诉求即可，例如：“请按 repo-deep-dive-report 的流程为这个仓库产出一份深度走读报告（MD + HTML）”。

## 推荐用法

1) 先生成仓库快照（辅助走读与引用证据）：

```bash
python3 agent/skills/repo-deep-dive-report/scripts/repo_snapshot.py --repo . --output docs/_repo_snapshot.md
```

2) 按 `references/report_outline.md` 的结构在 `docs/repo_review.md` 编写报告。

3) 渲染成离线 HTML：

```bash
python3 agent/skills/repo-deep-dive-report/scripts/render_md_to_html.py \
  --input docs/repo_review.md \
  --output docs/repo_review.html \
  --title "Repo Review"
```

## 说明

- 两个脚本均为标准库实现，无额外 Python 依赖。
- Mermaid 默认以代码块形式保留，适合离线阅读与迁移。
