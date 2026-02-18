#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  generate_output_skeleton.sh [out_root] [--force] [--replica]

Notes:
  - Default out_root is ./ui-ux-spec.
  - Creates the standard output folders and placeholder Markdown files.
  - Existing files are preserved unless --force is provided.
  - With --replica, also writes replica-grade guide/templates (pixel-clone friendly).
EOF
}

out_root="ui-ux-spec"
force=0
replica=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -f|--force)
      force=1
      shift
      ;;
    --replica)
      replica=1
      shift
      ;;
    *)
      if [[ "$1" == -* ]]; then
        echo "Unknown option: $1" >&2
        usage
        exit 2
      fi
      out_root="$1"
      shift
      ;;
  esac
done

mkdir -p "$out_root"

dirs=(
  "01_Foundation"
  "02_Components"
  "03_Patterns"
  "04_Pages"
  "05_A11y"
  "06_Assets"
  "07_Engineering_Constraints"
)

for d in "${dirs[@]}"; do
  mkdir -p "$out_root/$d"
done

write_file() {
  local path="$1"
  local content="$2"
  if [[ -f "$path" && $force -eq 0 ]]; then
    echo "skip: $path"
    return
  fi
  printf "%s\n" "$content" > "$path"
  echo "write: $path"
}

if [[ $replica -eq 1 ]]; then
  mkdir -p "$out_root/00_Guides"
  guide_path="$out_root/00_Guides/REPLICA_STANDARD.md"
  if [[ -f "$guide_path" && $force -eq 0 ]]; then
    echo "skip: $guide_path"
  else
    cat <<'EOF' > "$guide_path"
# Replica / Pixel-Clone Standard

This guide defines the stricter bar for replication-grade UI specs: a team can recreate the current UI pixel-for-pixel using the spec alone (no source code reading).

## Baseline (single baseline)
- Browser + version:
- Viewport (px) + device pixel ratio:
- Zoom level:
- OS / font rendering notes (if relevant):
- Density / resolution toggles used by the app (e.g., root font-size):
- Theme / style presets (light/dark + variants):

## Hard rules (must pass)
- No placeholders:
  - Disallow: any instruction that requires consulting source code to implement UI
  - Disallow: unfinished/task markers (work-in-progress notes)
  - Disallow: standalone ... / … used as filler (only allowed if it is literal UI copy and explicitly quoted)
  - If the literal UI copy contains an ellipsis, quote it explicitly as a literal string.
- No dependency language:
  - Disallow: any instruction that requires consulting a repo, screenshot, or reference implementation to implement UI (e.g. “参考 demo/见实现/以实现为准”).
- Exact microcopy:
  - Every UI-visible string is exact (no truncation, no paraphrase).
- Implementable details for every described UI:
  - Structure (DOM tree / slots / layout hierarchy)
  - Styles (exact class lists or explicit CSS declarations) including fixed pixel values
  - States + interactions (open/close rules, click-outside, ESC, keyboard navigation, focus)
  - Deterministic mock data for dynamic UIs (lists/logs/progress/charts)

## Suggested workflow
1) Scaffold docs with: generate_output_skeleton.sh --replica
2) Fill in foundations first (tokens + global styles + baseline).
3) Write components/pages as implementable blocks.
4) During drafting, templates start empty. Use non-strict lint first, then strict:
   - bash scripts/lint_replica_spec.sh --root <spec_root> --non-strict --warn-only
   - bash scripts/lint_replica_spec.sh --root <spec_root>
EOF
    echo "write: $guide_path"
  fi
fi

if [[ $replica -eq 1 ]]; then
  write_file "$out_root/00_Guides/COVERAGE.md" \
"# Coverage Matrix (Replica / Pixel-Clone)

Use this file to prevent missing specs. Replica lint passing is necessary but not sufficient: the goal is implementable coverage.

## 1) Pages coverage

Status values: \`Missing | Draft | Implementable | Replica\`

| Page | Spec path | Pixel structure | Interaction/keyboard | A11y | Fixtures | Regression notes | Status |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |

## 2) Components coverage

| Component | Spec path | DOM/Slots | Styles/pixels | State machine | Keyboard | A11y | Fixtures | Status |
|---|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |  |

## 3) High-risk details checklist

- [ ] Flex height chain for \`fillHeight\` UIs (who owns scroll, \`min-h-0\`, \`overflow\` boundaries)
- [ ] Scroll locking + portals (modals/drawers/popovers/tooltips)
- [ ] Focus management (trap, restore focus, focus-visible strategy)
- [ ] ESC-to-close coverage + priority (nested popover vs dialog vs drawer)
- [ ] Tooltip behavior (hover + keyboard focus)
- [ ] Density/resolution modes and their global impact
- [ ] Text overflow rules (single/multi-line, wrapping, truncation)

## 4) Known gaps

- [ ] <gap> (impact: ...; fix: ...; acceptance: ...)"
fi

if [[ $replica -eq 1 ]]; then
  write_file "$out_root/01_Foundation/FOUNDATION.md" \
"# Foundation

## Replica baseline (required for pixel-clone)
- Browser + version:
- Viewport (px) + device pixel ratio:
- Zoom level:
- Density / resolution toggles used by the app:
- Theme / style presets:

## Tokens (resolved values)
- Colors:
- Typography:
- Spacing:
- Radius:
- Shadow:
- Z-index:
- Motion:

## Global styles
- Reset/normalize:
- Body defaults:
- Links/forms:
- Focus-visible:
- Scrollbar/selection:
"
else
  write_file "$out_root/01_Foundation/FOUNDATION.md" \
"# Foundation

## Tokens
- Colors:
- Typography:
- Spacing:
- Radius:
- Shadow:
- Z-index:
- Motion:

## Global styles
- Reset/normalize:
- Body defaults:
- Links/forms:
- Focus-visible:
- Scrollbar/selection:
"
fi

if [[ $replica -eq 1 ]]; then
  write_file "$out_root/02_Components/COMPONENTS.md" \
"# Components

## Inventory
- Component list:

## Per component template (replica / pixel-clone)
- Purpose:
- Placement (where used):
- Structure (DOM tree / slots):
- Styles (class list or CSS declarations, include fixed px values):
- Content (exact microcopy + icons):
- Data (deterministic mock examples):
- Variants:
- States:
- Interaction (click/keyboard/focus/close rules):
- A11y (role/aria, focus order, live regions):
- Responsive:
- Motion:
- Theming hooks:
- Edge cases:
"
else
  write_file "$out_root/02_Components/COMPONENTS.md" \
"# Components

## Inventory
- Component list:

## Per component template
- Purpose:
- Structure/slots:
- Variants:
- States:
- Interaction:
- A11y:
- Responsive:
- Motion:
- Theming hooks:
- Edge cases:
"
fi

write_file "$out_root/03_Patterns/PATTERNS.md" \
"# Patterns

- Search/filter:
- Pagination/table:
- Form submit/validation:
- Confirm/destructive:
- Empty/loading/error:
"

if [[ $replica -eq 1 ]]; then
  write_file "$out_root/04_Pages/PAGES.md" \
"# Pages

- List page skeleton:
- Detail page skeleton:
- Form page skeleton:
- Dashboard skeleton:

Replica add-ons:
- Modules ordering (top-to-bottom) + spacing rules
- Key container widths/heights (fixed px values)
- Scroll regions and overflow rules
- Exact microcopy for headings/empty states
"
else
  write_file "$out_root/04_Pages/PAGES.md" \
"# Pages

- List page skeleton:
- Detail page skeleton:
- Form page skeleton:
- Dashboard skeleton:
"
fi

write_file "$out_root/05_A11y/A11Y.md" \
"# Accessibility

- Keyboard navigation:
- Focus management:
- ARIA roles/labels:
- Contrast:
- Reduced motion:
"

write_file "$out_root/06_Assets/ASSETS.md" \
"# Assets

- Logo variants:
- Icons:
- Illustrations:
- Image rules:
- Fonts:
"

write_file "$out_root/07_Engineering_Constraints/ENGINEERING.md" \
"# Engineering Constraints

- CSS architecture:
- Naming conventions:
- Theming mechanism:
- Lint/style rules:
- Storybook/visual tests:
"
