# Design Extraction Checklist

Use this checklist to avoid missing UI/UX details. Keep notes tied to file paths and component names. Exclude business logic, business rules, and domain workflows.

## 0. Replica / pixel-clone baseline (when “1:1 from docs” is required)
Use this section when the spec must enable pixel-level replication without reading source code.

- Single baseline only (do not mix):
  - Browser + version
  - Viewport size (px), device pixel ratio, zoom
  - OS font rendering notes (if relevant)
  - App density/resolution toggles (e.g., root font-size changes)
  - Theme/style presets (light/dark + any style variants)
- Hard rule: no placeholders
  - Disallow: “见源码/参考源码/源码片段”, TODO/TBD/FIXME, standalone `...`/`…`
  - If the literal UI copy contains an ellipsis, quote it explicitly as a literal string in the spec
- Hard rule: no dependency language
  - Disallow: “参考 demo/见 demo/对齐 demo/以实现为准/align with demo/reference implementation”
  - The spec must be self-contained: a team should not need a repo, screenshot, or any external reference to implement UI.
- Deterministic inputs for dynamic UI
  - Provide mock data examples (JSON or tables) so list density, wrapping, and ordering match the current UI
- Coverage matrix (recommended for replica)
  - Include a page/component coverage matrix and a “known gaps” checklist so reviewers can see what is missing at a glance.

## 1. Foundations (tokens)
- Colors: base, semantic, states, dark mode mapping, overlays, charts, contrast notes
- Typography: font stacks, scale, weights, line-height, letter spacing, smoothing, mono font
- Spacing & sizing: scale, layout padding/gaps, component padding, min hit targets, max content width
- Radius/border/shadow/z-index: scale, divider colors, focus ring strategy, elevation levels, z-index map
- Motion: duration tokens, easing, patterns (fade/slide/scale), reduced-motion support, skeleton

## 2. Global styles & base elements
- reset/normalize
- html/body defaults (font, background, line-height)
- links, lists, images, tables
- form control resets
- scrollbar, selection, focus-visible

## 3. Layout & IA
- breakpoints and containers
- grid system and column rules
- layout shells (header/sidebar/footer)
- navigation patterns and active state
- page skeleton conventions

## 4. Component inventory
For each component: purpose, structure/slots, variants, states, interactions, a11y, responsive behavior, motion, theming hooks, edge cases.

## 5. Page-level composition
- page types and modules ordering
- search/filter panels, tables, detail sections
- action hierarchy and destructive flows
- permissions and role-based UI

Replica add-ons (recommended):
- Provide DOM tree / layout hierarchy for each page region
- Provide exact class lists or explicit CSS declarations for key containers
- Provide exact microcopy (no truncation)

## 6. Microcopy & i18n
- button verbs and confirmation language
- validation error patterns and tone
- empty states: reason + guidance + CTA
- date/number/currency formats, plural rules

## 7. Behavior & state machines
- loading strategies (global/local/button)
- error strategies (retry, inline, full-page)
- submit rules (debounce, prevent double-submit)
- optimistic update/undo
- long-running tasks

## 8. Responsive & input modes
- breakpoints and layout changes
- touch targets and gesture behavior
- safe-area handling
- hover alternatives on mobile
- high-DPI images and srcset

## 9. Accessibility
- keyboard navigation and focus order
- focus-visible styles and focus trap
- aria roles/labels and live regions
- color contrast and non-color signals
- reduced-motion

## 10. Assets & branding
- logo variants, sizes, clear space
- icon sets, stroke weight, default sizes
- illustrations/empty state style
- image cropping/placeholder/fallback
- font hosting/subsets

## 11. Theming & white-label
- theme switch mechanism and scope
- customizable vs locked tokens
- transition strategy when switching

## 12. Engineering constraints
- CSS architecture (BEM, CSS modules, Tailwind, CSS-in-JS)
- naming conventions for tokens/classes/components
- lint/style rules that enforce UI constraints
- storybook and visual regression setup

## 13. Hard-to-miss details
- text overflow (single/multi-line)
- date/time format (12h/24h, relative time)
- required field markers and error placement
- IME composition behavior in search
- scroll locking and portal containers
- ESC-to-close coverage and priority
- table density and column behavior
- density modes (compact/comfortable)
- RTL support and browser-specific hacks
- Flex height chain (fillHeight / “占满剩余高度”)
  - For any UI that must “fill remaining height + internal scroll”, specify the full height chain explicitly:
    - which parent owns the height (`flex` container) and must include `min-h-0`
    - which child is `flex-1 min-h-0`
    - which node owns scrolling (`overflow-auto`) and which nodes must be `overflow-hidden` to prevent border-radius bleed
  - Add an acceptance check: no “half-blank viewport”, no overflow outside card/dialog bounds.

## 14. Recommended output folders
- 01_Foundation
- 02_Components
- 03_Patterns
- 04_Pages
- 05_A11y
- 06_Assets
- 07_Engineering_Constraints
