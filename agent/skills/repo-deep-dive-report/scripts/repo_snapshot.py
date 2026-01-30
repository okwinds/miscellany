#!/usr/bin/env python3
"""
Create a lightweight Markdown "repo snapshot" for evidence-based reviews (stdlib-only).

Usage:
  python repo_snapshot.py --repo . --output docs/_repo_snapshot.md
"""

from __future__ import annotations

import argparse
import os
import subprocess
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Dict, Iterable, List, Optional, Tuple


_DEFAULT_IGNORES = {
    ".git",
    ".hg",
    ".svn",
    "node_modules",
    ".venv",
    "venv",
    "__pycache__",
    ".pytest_cache",
    "dist",
    "build",
    "target",
    ".next",
    ".turbo",
    ".cache",
    ".mypy_cache",
}


_KEY_FILES = [
    "README.md",
    "README",
    "AGENTS.md",
    "CONTRIBUTING.md",
    "LICENSE",
    "pyproject.toml",
    "requirements.txt",
    "Pipfile",
    "package.json",
    "pnpm-lock.yaml",
    "yarn.lock",
    "package-lock.json",
    "go.mod",
    "Cargo.toml",
    "pom.xml",
    "build.gradle",
    "build.gradle.kts",
    "Makefile",
    "docker-compose.yml",
    "Dockerfile",
]


def _run(cmd: List[str], cwd: Path) -> Optional[str]:
    try:
        p = subprocess.run(cmd, cwd=str(cwd), stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, check=False, text=True)
        out = p.stdout.strip()
        return out or None
    except Exception:
        return None


def _iter_files(repo: Path) -> Iterable[Path]:
    for root, dirs, files in os.walk(repo):
        root_path = Path(root)
        dirs[:] = [d for d in dirs if d not in _DEFAULT_IGNORES]
        for f in files:
            yield root_path / f


def _ext_language(ext: str) -> str:
    ext = ext.lower()
    return {
        ".py": "Python",
        ".ipynb": "Jupyter",
        ".js": "JavaScript",
        ".ts": "TypeScript",
        ".tsx": "TypeScript",
        ".jsx": "JavaScript",
        ".go": "Go",
        ".rs": "Rust",
        ".java": "Java",
        ".kt": "Kotlin",
        ".cs": "C#",
        ".cpp": "C++",
        ".c": "C",
        ".h": "C/C++ Header",
        ".php": "PHP",
        ".rb": "Ruby",
        ".swift": "Swift",
        ".scala": "Scala",
        ".sql": "SQL",
        ".yml": "YAML",
        ".yaml": "YAML",
        ".json": "JSON",
        ".toml": "TOML",
        ".md": "Markdown",
        ".sh": "Shell",
    }.get(ext, ext or "(no ext)")


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--repo", required=True, help="Repo path")
    ap.add_argument("--output", required=True, help="Output markdown path")
    ap.add_argument("--max-files", type=int, default=200000, help="Safety cap")
    args = ap.parse_args()

    repo = Path(args.repo).resolve()
    out_path = Path(args.output)

    head = _run(["git", "rev-parse", "HEAD"], cwd=repo)
    branch = _run(["git", "rev-parse", "--abbrev-ref", "HEAD"], cwd=repo)

    files = []
    for i, p in enumerate(_iter_files(repo), 1):
        if i > args.max_files:
            break
        if p.is_file():
            files.append(p)

    rels = [p.relative_to(repo) for p in files]
    top_dirs = Counter([r.parts[0] if len(r.parts) > 1 else "(root)" for r in rels])
    exts = Counter([p.suffix.lower() for p in rels])
    langs: Counter[str] = Counter()
    for ext, cnt in exts.items():
        langs[_ext_language(ext)] += cnt

    key_present = [kf for kf in _KEY_FILES if (repo / kf).exists()]

    lines = []
    lines.append("# Repo Snapshot\n")
    lines.append(f"- Repo: `{repo}`")
    if head:
        lines.append(f"- Git HEAD: `{head}`")
    if branch:
        lines.append(f"- Git branch: `{branch}`")
    lines.append(f"- Total files (after ignores): `{len(rels)}`\n")

    lines.append("## Top-level directories\n")
    for name, cnt in top_dirs.most_common(20):
        lines.append(f"- `{name}`: {cnt}")
    lines.append("")

    lines.append("## Detected languages (by extension count)\n")
    for name, cnt in langs.most_common(20):
        lines.append(f"- {name}: {cnt}")
    lines.append("")

    lines.append("## Key files found\n")
    if key_present:
        for kf in key_present:
            lines.append(f"- `{kf}`")
    else:
        lines.append("- (none of the common key files were found)")
    lines.append("")

    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")


if __name__ == "__main__":
    main()
