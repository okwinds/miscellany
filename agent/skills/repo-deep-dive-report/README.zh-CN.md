# Repo Deep Dive Report（代码仓库深度走读报告）

一套“证据驱动”的代码仓库走读流程，用于产出结构化交付物（Markdown + 离线可打开的 HTML），包含 Mermaid 图、可操作的改进建议以及评分表。

## 包含内容

- `SKILL.md`：完整流程与质量门槛
- `references/`：报告大纲、Mermaid 模板、评分口径
- `scripts/repo_snapshot.py`：生成仓库快照（仅标准库）
- `scripts/render_md_to_html.py`：将 Markdown 报告渲染为离线 HTML（仅标准库）

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

