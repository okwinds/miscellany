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
# Reduce false positives by requiring an identifier before `as`.
RE_TS_AS = re.compile(r"\b[A-Za-z_$][\w$]*\s+as\s+[A-Za-z0-9_.<>\[\]\|&]+\b", re.M)

# Optional runtime-risk heuristics (warn by default; can be fatal with --strict)
RE_REMOTE_URL = re.compile(r"https?://[^\s\"'<>]+", re.M)
RE_REMOTE_URL_NON_W3 = re.compile(r"https?://(?!www\.w3\.org/)[^\s\"'<>]+", re.M)
RE_ABS_PATH = re.compile(r"(/Users/[^\\s\"']+|[A-Za-z]:\\\\[^\\s\"']+)", re.M)

# Bundler-alias risk: identifiers like Fragment6 / jsx25 / useId3.
# These often appear after minification/merge; missing declarations frequently cause "white screen".
# NOTE: Keep patterns specific to reduce false positives from unrelated libs.
RE_ALIAS_CALL = re.compile(
    r"\b((?:jsx|jsxs|jsxDEV|createContext|useContext|useEffect|useMemo|useCallback|useRef|useReducer|useState|useId)\d+)\s*\(",
    re.M,
)
RE_ALIAS_VALUE = re.compile(r"\b((?:React|Fragment)\d+)\b", re.M)
RE_DECL_SIMPLE = re.compile(r"^\s*(?:export\s+)?(?:const|let|var|function|class)\s+([A-Za-z_$][\w$]*)\b", re.M)
RE_DECL_MULTI_ASSIGN = re.compile(r"(?:^|,)\s*([A-Za-z_$][\w$]*)\s*=", re.M)
RE_REACT_DESTRUCTURE = re.compile(r"^\s*const\s*{\s*([\s\S]*?)\s*}\s*=\s*React\s*;?\s*$", re.M)


def _print(title: str, ok: bool, detail: str = "") -> None:
    status = "OK" if ok else "FAIL"
    line = f"[{status}] {title}"
    if detail:
        line += f": {detail}"
    print(line)

def _find_lines(text: str, pattern: re.Pattern[str], *, limit: int = 5) -> list[tuple[int, str]]:
    out: list[tuple[int, str]] = []
    for i, line in enumerate(text.splitlines(), start=1):
        if pattern.search(line):
            s = line.strip()
            if len(s) > 220:
                s = s[:220] + "…"
            out.append((i, s))
            if len(out) >= limit:
                break
    return out


def _extract_declared_identifiers(text: str, *, scan_lines: int = 400) -> set[str]:
    """
    Heuristically extract declared identifiers near the top of the file.
    This helps catch "alias used but not declared" which commonly becomes ReferenceError at runtime.
    """
    head = "\n".join(text.splitlines()[:scan_lines])
    declared: set[str] = set()

    for m in RE_DECL_SIMPLE.finditer(head):
        declared.add(m.group(1))

    # Capture multi-assign declarations on the same line:
    #   const a = 1, b = 2, c = 3;
    for line in head.splitlines():
        if not re.match(r"^\s*(?:export\s+)?(?:const|let|var)\b", line):
            continue
        for m in RE_DECL_MULTI_ASSIGN.finditer(line):
            declared.add(m.group(1))

    # Handle: const { Fragment: Fragment6, useId: useId2, useId } = React;
    # We accept both renamed and direct destructures.
    for m in RE_REACT_DESTRUCTURE.finditer(head):
        inside = m.group(1)
        # renamed: Foo: Bar
        for _, name in re.findall(r"\b([A-Za-z_$][\w$]*)\s*:\s*([A-Za-z_$][\w$]*)\b", inside):
            declared.add(name)
        # direct: Foo
        for name in re.findall(r"\b([A-Za-z_$][\w$]*)\b", inside):
            declared.add(name)

    return declared


def verify(
    path: Path,
    *,
    strict: bool = False,
    verbose: bool = False,
    check_aliases: bool = True,
    check_remote_urls: bool = True,
    check_path_leaks: bool = True,
) -> int:
    if not path.exists():
        _print("Input file exists", False, str(path))
        return 2

    text = path.read_text(encoding="utf-8", errors="replace")

    failures: list[str] = []
    warnings: list[str] = []

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
    if RE_TS_INTERFACE.search(text):
        warnings.append("Possible TypeScript `interface` found.")
    if RE_TS_TYPE_ALIAS.search(text):
        warnings.append("Possible TypeScript `type` alias found.")
    if RE_TS_ANNOTATION.search(text):
        warnings.append("Possible TypeScript type annotation `const x: T` found.")
    if RE_TS_AS.search(text):
        warnings.append("Possible TypeScript `as T` assertion found.")

    # 5) Optional checks: runtime-risk heuristics
    if check_remote_urls and RE_REMOTE_URL.search(text):
        # Filter out common XML namespace constants (these are not "remote assets").
        urls = [
            u
            for u in RE_REMOTE_URL.findall(text)
            if not u.startswith(("http://www.w3.org/", "https://www.w3.org/"))
        ]
        if urls:
            examples = _find_lines(text, RE_REMOTE_URL_NON_W3, limit=3)
            detail = "; ".join([f"L{ln}: {s}" for ln, s in examples])
            warnings.append(f"Remote URL(s) found (prefer inlining assets): {detail}")

    if check_path_leaks and RE_ABS_PATH.search(text):
        examples = _find_lines(text, RE_ABS_PATH, limit=3)
        detail = "; ".join([f"L{ln}: {s}" for ln, s in examples])
        warnings.append(f"Possible absolute path leak found: {detail}")

    if check_aliases:
        declared = _extract_declared_identifiers(text, scan_lines=450)
        used_aliases = sorted(set([*RE_ALIAS_CALL.findall(text), *RE_ALIAS_VALUE.findall(text)]))
        missing = [t for t in used_aliases if t not in declared]
        if missing:
            missing_preview = ", ".join(missing[:12]) + ("..." if len(missing) > 12 else "")
            warnings.append(
                "Bundler alias token(s) used but not declared (high risk of runtime ReferenceError / white screen): "
                + missing_preview
            )
        elif used_aliases:
            # Not an error, but it's a signal that runtime smoke testing is mandatory.
            warnings.append(
                "Bundler alias tokens detected (e.g. Fragment6/jsx25). Static checks passed, but runtime smoke is still required."
            )

    _print("Single import statement", ok=(len(import_stmt_lines) == 1))
    _print("Only React imports", ok=(len(non_react) == 0))
    _print("No dynamic import()", ok=(not RE_DYNAMIC_IMPORT.search(text)))
    _print("No require()", ok=(not RE_REQUIRE.search(text)))
    _print("Has default export", ok=bool(RE_EXPORT_DEFAULT.search(text)))
    _print("No asset/style imports", ok=(len(banned_import_hint) == 0))

    if warnings:
        for w in warnings:
            _print("Warn", True, w)

    if strict and warnings:
        # Strict mode turns warnings into failures.
        failures.append(f"--strict enabled: {len(warnings)} warning(s) must be addressed.")

    if failures:
        for f in failures:
            _print("Violation", False, f)
        return 1

    # Extra info
    print("")
    print(f"Import statements detected: {len(import_stmt_lines)}")
    if verbose:
        if import_stmt_lines:
            print("")
            print("Import line(s):")
            for ln, s in _find_lines(text, RE_IMPORT_STMT_LINE, limit=5):
                print(f"  L{ln}: {s}")

    print("")
    print("Next suggested step:")
    print("  - Run a runtime smoke preview (Vite port may auto-switch; trust the `Local:` URL).")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Verify single-file React .jsx packaging constraints")
    parser.add_argument("jsx_path", help="Path to merged .jsx file")
    parser.add_argument("--strict", action="store_true", help="Treat warnings as failures (strong gate).")
    parser.add_argument("--verbose", action="store_true", help="Print extra diagnostics (line hints, etc.).")
    parser.add_argument(
        "--no-check-aliases",
        action="store_true",
        help="Disable bundler-alias risk heuristics (e.g. Fragment6/jsx25).",
    )
    parser.add_argument(
        "--no-check-remote-urls",
        action="store_true",
        help="Disable remote URL detection (https://...).",
    )
    parser.add_argument(
        "--no-check-path-leaks",
        action="store_true",
        help="Disable absolute path leak detection (/Users/... or C:\\\\...).",
    )
    args = parser.parse_args()
    return verify(
        Path(args.jsx_path),
        strict=bool(args.strict),
        verbose=bool(args.verbose),
        check_aliases=not bool(args.no_check_aliases),
        check_remote_urls=not bool(args.no_check_remote_urls),
        check_path_leaks=not bool(args.no_check_path_leaks),
    )


if __name__ == "__main__":
    raise SystemExit(main())
