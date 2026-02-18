#!/usr/bin/env bash
set -euo pipefail

if ! command -v rg >/dev/null 2>&1; then
  echo "rg (ripgrep) is required." >&2
  exit 2
fi

usage() {
  cat <<'EOF'
Usage:
  scan_ui_sources.sh [repo_root] [out_file] [extra_glob ...]
  scan_ui_sources.sh --root <repo_root> [--out <out_file>] [--force] [--ignore <csv>] [--no-default-ignore] [extra_glob ...]
  scan_ui_sources.sh --out <out_file> [extra_glob ...]

Notes:
  - If repo_root is omitted, the current working directory (or git root) is scanned.
  - No directory layout is assumed; the scan covers the repo root with ignores applied.
  - Default ignores include common build/cache dirs and extraction output folders.
  - If --out already exists, the script refuses to overwrite it unless --force is provided.
  - Use --ignore to add extra ignore patterns (comma-separated). Whitespace around patterns is trimmed.
  - You can pass --ignore multiple times; patterns are merged.
EOF
}

tmp_files=()
mktemp_track() {
  local t
  t="$(mktemp)"
  tmp_files+=("$t")
  echo "$t"
}
cleanup_tmp_files() {
  if ((${#tmp_files[@]})); then
    rm -f "${tmp_files[@]}" 2>/dev/null || true
  fi
}
trap cleanup_tmp_files EXIT

root="."
out=""
force_out=0
root_set=0
use_default_ignore=1
ignore_csv=""
extra_globs=()

trim() {
  local s="$1"
  # Leading trim
  s="${s#"${s%%[![:space:]]*}"}"
  # Trailing trim
  s="${s%"${s##*[![:space:]]}"}"
  printf "%s" "$s"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --root)
      root="$2"
      root_set=1
      shift 2
      ;;
    --out)
      out="$2"
      shift 2
      ;;
    --force)
      force_out=1
      shift
      ;;
    --ignore)
      ignore_csv="${ignore_csv:+$ignore_csv,}$2"
      shift 2
      ;;
    --no-default-ignore)
      use_default_ignore=0
      shift
      ;;
    --)
      shift
      extra_globs+=("$@")
      break
      ;;
    *)
      if [[ $root_set -eq 0 && -d "$1" ]]; then
        root="$1"
        root_set=1
      elif [[ -z "$out" ]]; then
        out="$1"
      else
        extra_globs+=("$1")
      fi
      shift
      ;;
  esac
done

if [[ ! -d "$root" ]]; then
  echo "Repo root not found: $root" >&2
  exit 1
fi

root="$(cd "$root" && pwd)"
if [[ $root_set -eq 0 ]] && command -v git >/dev/null 2>&1; then
  if git -C "$root" rev-parse --show-toplevel >/dev/null 2>&1; then
    root="$(git -C "$root" rev-parse --show-toplevel)"
  fi
fi

if [[ -n "$out" ]]; then
  if [[ -d "$out" ]]; then
    echo "--out points to a directory, expected a file: $out" >&2
    exit 1
  fi
  if [[ -e "$out" && $force_out -eq 0 ]]; then
    echo "Refusing to overwrite existing output file: $out (use --force to overwrite)" >&2
    exit 1
  fi
  mkdir -p "$(dirname "$out")"
  exec > "$out"
fi

section() {
  printf "\n## %s\n" "$1"
}

default_ignores=(
  ".git/**"
  "node_modules/**"
  "dist/**"
  "build/**"
  "coverage/**"
  ".next/**"
  ".nuxt/**"
  ".output/**"
  ".turbo/**"
  ".cache/**"
  "out/**"
  "storybook-static/**"
  ".idea/**"
  ".vscode/**"
  "tmp/**"
  "temp/**"
  "vendor/**"
  "**/skills/**"
  "ui-ux-spec/**"
)

rg_ignore_args=()
if [[ $use_default_ignore -eq 1 ]]; then
  for pat in "${default_ignores[@]}"; do
    rg_ignore_args+=("-g" "!$pat")
  done
fi

if [[ -n "$ignore_csv" ]]; then
  IFS=',' read -r -a extra_ignores <<< "$ignore_csv"
  for pat in "${extra_ignores[@]}"; do
    pat="$(trim "$pat")"
    [[ -z "$pat" ]] && continue
    rg_ignore_args+=("-g" "!$pat")
  done
fi

scan_roots=("$root")

list_globs() {
  local tmp
  tmp="$(mktemp_track)"
  for g in "$@"; do
    rg --files "${rg_ignore_args[@]}" -g "$g" "${scan_roots[@]}" >> "$tmp" 2>/dev/null || true
  done
  if [[ -s "$tmp" ]]; then
    sort -u "$tmp" | sed "s|^$root/||"
  else
    echo "(none)"
  fi
  rm -f "$tmp"
}

list_matches() {
  local pattern
  local tmp
  local args=()
  pattern="$1"
  shift
  for g in "$@"; do
    args+=("-g" "$g")
  done
  tmp="$(mktemp_track)"
  rg -l --no-messages "${rg_ignore_args[@]}" "${args[@]}" "$pattern" "${scan_roots[@]}" >> "$tmp" 2>/dev/null || true
  if [[ -s "$tmp" ]]; then
    sort -u "$tmp" | sed "s|^$root/||"
  else
    echo "(none)"
  fi
  rm -f "$tmp"
}

echo "# UI Source Scan"
echo "root: $root"
echo "scan_roots:"
for p in "${scan_roots[@]}"; do
  if [[ "$p" == "$root" ]]; then
    echo "- ."
  else
    echo "- ${p#"$root/"}"
  fi
done
echo "generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"

section "Design tokens / themes / styles"
list_globs \
  "**/tokens/**" \
  "**/*token*.*" \
  "**/theme/**" \
  "**/*theme*.*" \
  "**/*palette*.*" \
  "**/*design-system*.*" \
  "**/*styleguide*.*" \
  "**/*style-guide*.*"

section "Keyword hits (themes/tokens/providers)"
list_matches \
  "(ThemeProvider|createTheme|createMuiTheme|defineTheme|extendTheme|theme\\s*:|tokens?|designTokens?|semanticColors?|colorScheme|colorMode|darkMode|lightMode)" \
  "*.ts" "*.tsx" "*.js" "*.jsx" "*.mjs" "*.cjs" "*.json" "*.css" "*.scss" "*.less" "*.styl" "*.mdx"

section "Keyword hits (CSS variables / theming)"
list_matches \
  "(:root\\b|\\[data-theme|prefers-color-scheme|--[a-zA-Z0-9-]+\\s*:)" \
  "*.css" "*.scss" "*.less" "*.styl"

section "Keyword hits (styling systems)"
list_matches \
  "(styled\\(|@emotion|styled-components|chakra|@mui|antd|mantine|radix|headlessui|tailwindcss)" \
  "*.ts" "*.tsx" "*.js" "*.jsx" "*.mjs" "*.cjs" "*.css" "*.scss" "*.less" "*.styl"

section "Global styles / resets"
list_globs \
  "**/global*.css" \
  "**/global*.scss" \
  "**/global*.less" \
  "**/global*.styl" \
  "**/index.css" \
  "**/index.scss" \
  "**/index.less" \
  "**/index.styl" \
  "**/app.css" \
  "**/app.scss" \
  "**/app.less" \
  "**/app.styl" \
  "**/styles.css" \
  "**/styles.scss" \
  "**/styles.less" \
  "**/styles.styl" \
  "**/reset*.css" \
  "**/reset*.scss" \
  "**/reset*.less" \
  "**/reset*.styl" \
  "**/normalize*.css" \
  "**/normalize*.scss" \
  "**/normalize*.less" \
  "**/normalize*.styl"

section "Tailwind / PostCSS"
list_globs \
  "tailwind.config.*" \
  "postcss.config.*" \
  "**/tailwind.css" \
  "**/globals.css"

section "Component sources"
list_globs \
  "**/components/**" \
  "**/ui/**" \
  "**/shared/components/**" \
  "**/packages/ui/**" \
  "**/design-system/**"

section "Pages / routes / layouts"
list_globs \
  "**/pages/**" \
  "**/routes/**" \
  "**/layouts/**" \
  "**/views/**"

section "Storybook / stories"
list_globs \
  ".storybook/**" \
  "**/*.stories.*"

section "Assets (icons/images)"
list_globs \
  "**/assets/**" \
  "**/public/**" \
  "**/icons/**" \
  "**/images/**" \
  "**/illustrations/**"

section "i18n / copy"
list_globs \
  "**/locales/**" \
  "**/i18n/**" \
  "**/*messages*.json" \
  "**/*translations*.json" \
  "**/*i18n*.ts" \
  "**/*i18n*.js" \
  "**/*i18n*.json"

section "A11y / visual regression / tests"
list_globs \
  "**/*a11y*.*" \
  "**/*accessib*.*" \
  "**/*visual*test*.*" \
  "**/*percy*.*" \
  "**/*chromatic*.*" \
  "**/*playwright*.*"

if [[ ${#extra_globs[@]} -gt 0 ]]; then
  section "Extra globs (user-provided)"
  list_globs "${extra_globs[@]}"
fi
