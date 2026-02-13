#!/usr/bin/env python3
"""
Verify a "single-file React .jsx" bundle meets the packaging constraints.

This script is intentionally heuristic: it catches the most common violations
without requiring a JS parser or third-party Python deps.
"""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


RE_IMPORT_STMT_LINE = re.compile(r"^\s*import\b.*$", re.M)
# Allow matching across newlines to catch rare multi-line imports.
RE_IMPORT_FROM = re.compile(r"^\s*import\s+[\s\S]*?\s+from\s+['\"]([^'\"]+)['\"]", re.M)
RE_IMPORT_BARE = re.compile(r"^\s*import\s+['\"]([^'\"]+)['\"]\s*;?\s*$", re.M)
RE_DYNAMIC_IMPORT = re.compile(r"\bimport\s*\(", re.M)
RE_REQUIRE = re.compile(r"\brequire\s*\(", re.M)
RE_EXPORT_DEFAULT = re.compile(r"\bexport\s+default\b", re.M)

# Heuristic TS syntax checks (warn-level)
RE_TS_INTERFACE = re.compile(r"^\s*interface\s+[A-Za-z0-9_]+\s*", re.M)
RE_TS_TYPE_ALIAS = re.compile(r"^\s*(export\s+)?type\s+[A-Za-z0-9_]+\s*=", re.M)
RE_TS_ANNOTATION = re.compile(
    r"^\s*(export\s+)?(const|let|var|function)\s+[A-Za-z0-9_]+\s*:\s*",
    re.M,
)
RE_TS_AS = re.compile(r"\s+as\s+[A-Za-z0-9_.<>\[\]\|&]+\b", re.M)


def _print(title: str, ok: bool, detail: str = "") -> None:
    status = "OK" if ok else "FAIL"
    line = f"[{status}] {title}"
    if detail:
        line += f": {detail}"
    print(line)


def verify(path: Path) -> int:
    if not path.exists():
        _print("Input file exists", False, str(path))
        return 2

    text = path.read_text(encoding="utf-8", errors="replace")

    failures: list[str] = []

    # 1) Imports: exactly one import statement; only allow module 'react'
    import_stmt_lines = RE_IMPORT_STMT_LINE.findall(text)
    import_from = RE_IMPORT_FROM.findall(text)
    import_bare = RE_IMPORT_BARE.findall(text)
    import_modules = import_from + import_bare
    non_react = [m for m in import_modules if m != "react"]

    if len(import_stmt_lines) == 0:
        failures.append("No `import ...` statement found (expected exactly one import from 'react').")
    elif len(import_stmt_lines) != 1:
        failures.append(
            f"Found {len(import_stmt_lines)} import statements (expected exactly 1 import from 'react')."
        )

    if non_react:
        failures.append(f"Found non-React imports: {sorted(set(non_react))}")

    # Some bundlers omit semicolons; still catch any "from '<x>'" that's not react.
    # Also catch dynamic require().
    if RE_DYNAMIC_IMPORT.search(text):
        failures.append("Found dynamic import(...), which is treated as an external dependency risk.")
    if RE_REQUIRE.search(text):
        failures.append("Found require(...), which is treated as an external dependency risk.")

    # 2) No asset/style imports
    banned_import_hint = []
    for m in import_modules:
        if any(
            m.endswith(ext)
            for ext in (
                ".css",
                ".scss",
                ".sass",
                ".less",
                ".svg",
                ".png",
                ".jpg",
                ".jpeg",
                ".gif",
                ".webp",
                ".ico",
                ".ttf",
                ".otf",
                ".woff",
                ".woff2",
                ".json",
            )
        ):
            banned_import_hint.append(m)
    if banned_import_hint:
        failures.append(f"Found asset/style imports: {sorted(set(banned_import_hint))}")

    # 3) Default export
    if not RE_EXPORT_DEFAULT.search(text):
        failures.append("Missing `export default` (root component must be default-exported).")

    # 4) Heuristic TS residue warnings (do not fail hard by default)
    warnings: list[str] = []
    if RE_TS_INTERFACE.search(text):
        warnings.append("Possible TypeScript `interface` found.")
    if RE_TS_TYPE_ALIAS.search(text):
        warnings.append("Possible TypeScript `type` alias found.")
    if RE_TS_ANNOTATION.search(text):
        warnings.append("Possible TypeScript type annotation `const x: T` found.")
    if RE_TS_AS.search(text):
        warnings.append("Possible TypeScript `as T` assertion found.")

    _print("Single import statement", ok=(len(import_stmt_lines) == 1))
    _print("Only React imports", ok=(len(non_react) == 0))
    _print("No dynamic import()", ok=(not RE_DYNAMIC_IMPORT.search(text)))
    _print("No require()", ok=(not RE_REQUIRE.search(text)))
    _print("Has default export", ok=bool(RE_EXPORT_DEFAULT.search(text)))
    _print("No asset/style imports", ok=(len(banned_import_hint) == 0))

    if warnings:
        for w in warnings:
            _print("TypeScript residue (warn)", True, w)

    if failures:
        for f in failures:
            _print("Violation", False, f)
        return 1

    # Extra info
    print("")
    print(f"Import statements detected: {len(import_stmt_lines)}")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify single-file React .jsx packaging constraints")
    parser.add_argument("jsx_path", help="Path to merged .jsx file")
    args = parser.parse_args()
    return verify(Path(args.jsx_path))


if __name__ == "__main__":
    raise SystemExit(main())
