#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "rg (ripgrep) is required." >&2
  exit 2
fi

usage() {
  cat <<'EOF'
Usage:
  lint_replica_spec.sh [--root <spec_root>] [--allow-ellipsis] [--include-assets] [--non-strict] [--warn-only]
  lint_replica_spec.sh <spec_root>

Purpose:
  Fail-fast lint for "replica / pixel-clone" UI specs:
  - disallow "see source"/TODO placeholders
  - disallow dependency language that makes specs non-self-contained (e.g. “参考 demo/见实现/align with demo”)
  - disallow standalone ellipsis placeholders
  - optionally flag empty generated-template fields (strict by default)

Notes:
  - This script is intentionally heuristic. It should catch the common ways specs become non-implementable.
  - Ellipses are allowed only when they are the literal UI copy and are explicitly quoted in the spec.
  - By default, this script prefers rg --pcre2 when available, but it can fall back to rg's default regex engine.
  - The "empty generated-template fields" check requires python3 (disable via --no-python).
EOF
}

root="ui-ux-spec"
allow_ellipsis=0
strict=1
warn_only=0
include_assets=0
use_python=1
prefer_pcre2=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --root)
      root="$2"
      shift 2
      ;;
    --allow-ellipsis)
      allow_ellipsis=1
      shift
      ;;
    --include-assets)
      include_assets=1
      shift
      ;;
    --non-strict)
      strict=0
      shift
      ;;
    --warn-only)
      warn_only=1
      shift
      ;;
    --no-python)
      use_python=0
      shift
      ;;
    --no-pcre2)
      prefer_pcre2=0
      shift
      ;;
    *)
      if [[ "$1" == -* ]]; then
        echo "Unknown option: $1" >&2
        usage
        exit 2
      fi
      root="$1"
      shift
      ;;
  esac
done

if [[ ! -d "$root" ]]; then
  echo "Spec root not found: $root" >&2
  exit 1
fi

root="$(cd "$root" && pwd)"

err_count=0
warn_count=0

rg_globs=(--glob "*.md")
if [[ $include_assets -eq 0 ]]; then
  rg_globs+=(--glob "!**/06_Assets/**")
fi

rg_supports_pcre2() {
  # Exit codes:
  # - 0/1: ok (match/no match)
  # - 2: rg runtime/config error (e.g. --pcre2 unsupported)
  rg --pcre2 -n "a" /dev/null >/dev/null 2>&1
  local code=$?
  [[ $code -ne 2 ]]
}

rg_cmd=(rg -n -S "${rg_globs[@]}")
if [[ $prefer_pcre2 -eq 1 ]]; then
  if rg_supports_pcre2; then
    rg_cmd+=(--pcre2)
  else
    printf "\n== NOTE ==\nrg does not support --pcre2; falling back to the default regex engine.\n" >&2
  fi
fi

print_block() {
  local title="$1"
  shift
  printf "\n== %s ==\n" "$title"
  printf "%s\n" "$@"
}

run_check() {
  local title="$1"
  local pattern="$2"
  local mode="${3:-error}" # error|warn
  shift 3 || true
  local extra_rg_args=("$@")

  local out
  out="$("${rg_cmd[@]}" "${extra_rg_args[@]}" "$pattern" "$root" || true)"
  if [[ -n "$out" ]]; then
    print_block "$title" "$out"
    if [[ "$mode" == "warn" ]]; then
      warn_count=$((warn_count + 1))
    else
      err_count=$((err_count + 1))
    fi
  fi
}

# 1) "See source" / "as in code" placeholders
run_check \
  "Disallowed: see-source placeholders" \
  "(见源码|参考源码|源码片段|详见源码|见代码|see\\s+(the\\s+)?source|refer\\s+to\\s+source|as\\s+in\\s+code)" \
  "error"

# 1b) Dependency language that makes specs non-self-contained
# In replica mode, specs must not require consulting a demo, a repo, a screenshot, or an "implementation" to be implemented.
# Strict: error. Non-strict: warning.
dep_mode="error"
if [[ $strict -eq 0 ]]; then
  dep_mode="warn"
fi
run_check \
  "Disallowed: dependency language (demo/implementation references)" \
  "(参考\\s*demo|见\\s*demo|对齐\\s*demo|以\\s*demo\\s*为准|参照\\s*demo|对标\\s*demo|demo\\s*(口径|规则|源码)|以\\s*(实现|工程)\\s*为准|参考\\s*(实现|工程)|见\\s*(实现|工程)|align\\s+(with|to)\\s+demo|see\\s+demo|refer\\s+to\\s+demo|reference\\s+implementation)" \
  "$dep_mode"

# 2) TODO-style placeholders
run_check \
  "Disallowed: TODO/TBD/FIXME/WIP placeholders" \
  "\\b(TODO|TBD|FIXME|WIP)\\b" \
  "error" \
  "-i"

# 3) Standalone ellipsis placeholders (common '...' / '…' filler)
if [[ $allow_ellipsis -eq 0 ]]; then
  run_check \
    "Disallowed: standalone ellipsis placeholders" \
    "^\\s*(?:[-*]\\s*)?(?:\\.\\.\\.|…)\\s*$" \
    "error"
fi

# 4) Empty generated-template fields (strict by default)
# These are the common “skeleton left unfilled” markers in our default templates.
python_check_empty_templates() {
  python3 - <<'PY'
import os
import re
import sys

root = os.environ["SPEC_ROOT"]
include_assets = os.environ.get("INCLUDE_ASSETS", "0") == "1"

field_patterns = [
  re.compile(r"^\s*-\s*(Colors|Typography|Spacing|Radius|Shadow|Z-index|Motion):\s*$"),
  re.compile(r"^\s*-\s*(Reset/normalize|Body defaults|Links/forms|Focus-visible|Scrollbar/selection):\s*$"),
  re.compile(r"^\s*-\s*Component list:\s*$"),
  re.compile(r"^\s*-\s*(Logo variants|Icons|Illustrations|Image rules|Fonts):\s*$"),
  re.compile(r"^\s*-\s*(CSS architecture|Naming conventions|Theming mechanism|Lint/style rules|Storybook/visual tests):\s*$"),
]

md_paths = []
for dirpath, _, filenames in os.walk(root):
  if not include_assets and ("/06_Assets/" in dirpath.replace("\\", "/") or dirpath.replace("\\", "/").endswith("/06_Assets")):
    continue
  for name in filenames:
    if name.lower().endswith(".md"):
      md_paths.append(os.path.join(dirpath, name))

def next_non_empty(lines, start):
  i = start
  while i < len(lines) and lines[i].strip() == "":
    i += 1
  return i

issues = []
for path in sorted(md_paths):
  try:
    text = open(path, "r", encoding="utf-8").read()
  except Exception:
    continue
  lines = text.splitlines()
  for idx, line in enumerate(lines):
    if not any(p.match(line) for p in field_patterns):
      continue

    field_indent = len(line) - len(line.lstrip(" "))
    j = next_non_empty(lines, idx + 1)
    if j >= len(lines):
      issues.append((path, idx + 1, line))
      continue
    nxt = lines[j]
    nxt_indent = len(nxt) - len(nxt.lstrip(" "))

    # Consider filled if the next meaningful line is more indented (nested bullets/blocks).
    if nxt_indent > field_indent:
      continue

    # Consider filled if the next line is a continuation paragraph (not a new bullet/heading).
    if not nxt.lstrip().startswith(("-", "*", "#")):
      continue

    # Otherwise it's almost certainly left as an empty template field.
    issues.append((path, idx + 1, line))

if issues:
  for path, lineno, line in issues:
    rel = os.path.relpath(path, root)
    print(f"{rel}:{lineno}:{line}")
  sys.exit(1)
sys.exit(0)
PY
}

if [[ $use_python -eq 1 ]]; then
  if ! command -v python3 >/dev/null 2>&1; then
    msg="python3 is required for the \"empty generated-template fields\" check. Install python3 or re-run with --no-python."
    if [[ $strict -eq 1 ]]; then
      print_block "Missing dependency (strict): python3" "$msg"
      err_count=$((err_count + 1))
    else
      print_block "Missing dependency (non-strict): python3" "$msg"
      warn_count=$((warn_count + 1))
    fi
  else
    tmp_empty_templates_out="$(mktemp)"
    trap 'rm -f "${tmp_empty_templates_out}" 2>/dev/null || true' EXIT
    if ! SPEC_ROOT="$root" INCLUDE_ASSETS="$include_assets" python_check_empty_templates >"${tmp_empty_templates_out}" 2>&1; then
      if [[ $strict -eq 1 ]]; then
        print_block "Disallowed (strict): empty generated-template fields" "$(cat "${tmp_empty_templates_out}")"
        err_count=$((err_count + 1))
      else
        print_block "Warning: empty generated-template fields" "$(cat "${tmp_empty_templates_out}")"
        warn_count=$((warn_count + 1))
      fi
    fi
    rm -f "${tmp_empty_templates_out}" 2>/dev/null || true
  fi
fi

if [[ $err_count -eq 0 && $warn_count -eq 0 ]]; then
  echo "OK: replica spec lint passed ($root)"
  exit 0
fi

if [[ $warn_only -eq 1 ]]; then
  echo "WARN-ONLY: lint reported issues (errors=$err_count warnings=$warn_count), but exiting 0."
  exit 0
fi

echo "FAIL: replica spec lint reported issues (errors=$err_count warnings=$warn_count)."
exit 1
