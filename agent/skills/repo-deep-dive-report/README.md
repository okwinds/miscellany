# Repo Deep Dive Report

An end-to-end “read the repo” workflow that produces an evidence-based review report (Markdown + offline standalone HTML), with Mermaid diagrams, actionable recommendations, and a scorecard.

## What’s included

- `SKILL.md`: workflow + quality gates
- `references/`: report outline, Mermaid templates, scoring rubric
- `scripts/repo_snapshot.py`: generate a lightweight repo snapshot (stdlib-only)
- `scripts/render_md_to_html.py`: convert Markdown report to offline HTML (stdlib-only)

## Install into Codex / Claude Code

> This folder is the “skill package”. Installing it simply means placing the whole directory (including `SKILL.md`) into your tool’s `skills/` directory, keeping the folder name unchanged.

### Option A: copy (recommended)

From this repo root (pick one: `~/.codex/skills` or `~/.claude/skills`):

```bash
SKILLS_DIR=~/.codex/skills   # or ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
cp -R agent/skills/repo-deep-dive-report "$SKILLS_DIR/repo-deep-dive-report"
```

### Option B: symlink (best for development)

```bash
SKILLS_DIR=~/.codex/skills   # or ~/.claude/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
ln -s "$(pwd)/agent/skills/repo-deep-dive-report" "$SKILLS_DIR/repo-deep-dive-report"
```

### After install

- Restart / open a new Codex or Claude Code session so it re-scans skills.
- Then ask for it in natural language, e.g. “produce a deep-dive repo review report (MD + HTML) following repo-deep-dive-report”.

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
