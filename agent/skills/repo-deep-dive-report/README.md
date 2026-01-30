# Repo Deep Dive Report

An end-to-end “read the repo” workflow that produces an evidence-based review report (Markdown + offline standalone HTML), with Mermaid diagrams, actionable recommendations, and a scorecard.

## What’s included

- `SKILL.md`: workflow + quality gates
- `references/`: report outline, Mermaid templates, scoring rubric
- `scripts/repo_snapshot.py`: generate a lightweight repo snapshot (stdlib-only)
- `scripts/render_md_to_html.py`: convert Markdown report to offline HTML (stdlib-only)

## Suggested usage

1) Create a repo snapshot:

```bash
python3 agent/skills/repo-deep-dive-report/scripts/repo_snapshot.py --repo . --output docs/_repo_snapshot.md
```

2) Write your report in `docs/repo_review.md` (see `references/report_outline.md`).

3) Render to standalone HTML:

```bash
python3 agent/skills/repo-deep-dive-report/scripts/render_md_to_html.py \
  --input docs/repo_review.md \
  --output docs/repo_review.html \
  --title "Repo Review"
```

## Notes

- Both scripts are stdlib-only (no extra Python dependencies).
- Mermaid code blocks are preserved as code fences by default (offline-friendly).

