# Repo Deep Dive Report

An end-to-end “read the repo” workflow that produces an evidence-based review report (Markdown + offline standalone HTML), with Mermaid diagrams, actionable recommendations, and a scorecard.

## What’s included

- `SKILL.md`: workflow + quality gates
- `references/`: report outline, Mermaid templates, scoring rubric
- `scripts/repo_snapshot.py`: generate a lightweight repo snapshot (stdlib-only)
- `scripts/render_md_to_html.py`: convert Markdown report to offline HTML (stdlib-only)

## Installation

> This folder is the “skill package”. Installing it means your coding tool/agent runner can discover the `SKILL.md` inside it (commonly by placing the directory into a `skills/` folder, or by using the tool’s “install from Git” feature).

### Option A: copy

From this repo root, set `SKILLS_DIR` to whatever skills folder your tool scans (e.g. `~/.codex/skills`, `~/.claude/skills`, `~/.config/opencode/skills`, etc):

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
cp -R agent/skills/repo-deep-dive-report "$SKILLS_DIR/repo-deep-dive-report"
```

### Option B: symlink

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
ln -s "$(pwd)/agent/skills/repo-deep-dive-report" "$SKILLS_DIR/repo-deep-dive-report"
```

### Option C: install from GitHub/Git via openskills

Use `openskills install` with this repo’s GitHub URL (or any Git URL), then select which skill(s) to install:

```bash
npx openskills install <git-url>
```

Example (this repo):

```bash
npx openskills install https://github.com/okwinds/miscellany
```

Common options:
- `-g`: install globally
- `-u`: install into `.agent/skills/` (portable across tools/projects)
- `-y`: skip prompts, install all detected skills

Verify / read back:

```bash
npx openskills list
npx openskills read repo-deep-dive-report
```

### Option D: give your tool the GitHub link

Many coding tools can install/load skills directly from a GitHub/Git URL. If yours supports it, point it at this repo and select/target `agent/skills/repo-deep-dive-report`. If it doesn’t, use copy/symlink or `openskills install`.

### After install

Restart / open a new session so your tool re-scans skills, then ask in natural language (e.g. “produce a deep-dive repo review report (MD + HTML) following repo-deep-dive-report”).

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
