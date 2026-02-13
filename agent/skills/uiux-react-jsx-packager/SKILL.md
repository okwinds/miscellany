---
name: uiux-react-jsx-packager
description: Package an existing React UI/UX demo into a single self-contained .jsx file with default-export root component, zero third-party runtime dependencies (no react-router/lucide/echarts/etc.), in-file styles (style tag or inline style objects), inline SVG icons, embedded or placeholder images, and state-based navigation. Use when asked to “合并为单文件 JSX/单文件打包/one-file React/零外部依赖/内联 CSS/替换图标库/用 state 做路由/把 demo 打包成独立 JSX 文件”.
version: 0.1.0
author: 肆〇柒/ForOhZen
---

# uiux-react-jsx-packager

## Output Contract

- Create **one new** `*.jsx` file (do not overwrite existing files unless explicitly requested).
- Export the **root component** via `export default`.
- Keep runtime dependencies to **React only** (no `react-router`, `lucide-react`, `echarts`, `classnames`, `zustand`, etc.).
- Keep styles **in-file** via `<style>` injection and/or inline `style={{...}}`.
- Replace icon libraries with **inline SVG** components.
- Replace images with **base64-inlined** data URLs or deterministic placeholders.
- Implement navigation via **component state** (optionally sync to `location.hash` for shareable URLs).
- Preserve **all interactions/animations/state logic**; do not simplify behavior.
- Preserve **pixel-perfect visual fidelity** (spacing/colors/typography/shadows/radius) by embedding the compiled CSS whenever possible.

### Pixel-perfect definition (non-negotiable)

“像素级一致 / pixel-perfect”在工程上必须限定条件，否则不可验证。默认按以下条件验收：

- **同一台机器**、同一 OS 与同一浏览器版本（建议固定 Chrome 版本）
- 固定 viewport（宽高）与 `deviceScaleFactor`（DPR）
- 字体必须一致（包含字重）：不要依赖系统字体差异；必要时把字体文件以 `@font-face` 形式内联进 CSS（base64 data URL）
- 截图对比时必须处于“稳定态”：避免进行中动画/过渡影响像素 diff（见 Verification）

## Workflow (do in order)

### 1) Discover structure and runtime surface

- Find and follow any `AGENTS.md` instructions that apply to the target directory tree.
- Locate the actual app entry (`src/main.*`, `src/index.*`, `App.*`) and identify:
  - Router entrypoints (hash router / react-router / custom)
  - Pages and module switch logic
  - Global providers (theme/style/toast/auth)
  - Global CSS + theme tokens (CSS variables, dark mode attribute, etc.)
  - Third-party runtime deps that must be removed (icons, charts, router, utilities)
- Prefer reading the **demo source** plus the **built output CSS** (if it exists) to lock visuals.

### 2) Choose a “visual parity” strategy for styles (pick one)

- **Preferred**: Embed production/built CSS (e.g. `dist/assets/index-*.css`) into `const APP_CSS = String.raw\`...\`;` and inject via `<style>`.
  - Keep existing `className` strings unchanged.
  - This is the most reliable way to keep spacing/colors/shadows identical without Tailwind tooling.
- Otherwise: Inline/merge source CSS files into one `<style>` block (still in-file).

Pixel-perfect 强依赖样式与字体，请额外确认：

- CSS variables / theme tokens（暗色模式 attribute/class）与原工程一致
- 所有外部字体/图标资源都已本地化/内联（不要依赖远程 URL）
- 截图对比用同一套 reset / `box-sizing` 规则（建议直接使用构建后 CSS）

### 3) Create the merge target file

- Create `YourNameMerged.jsx` with:
  - A single React import (`import React, { ... } from 'react';`)
  - `APP_CSS` string + a `AppStyleTag()` that injects exactly one `<style>` node
  - Helpers you will need (clamp, download, clipboard, etc.)

### 4) Merge code into one file (no module imports)

- Copy code for components/pages/hooks/utils into the single file.
- Remove all non-React imports; replace with local definitions.
- Remove TypeScript syntax:
  - Delete `interface`, `type`, generics (`useState<string>()`), and annotations (`x: string`)
  - Remove `as T` assertions
- Keep behavior identical:
  - Same default state values
  - Same reducers/actions
  - Same animations (CSS-based or requestAnimationFrame-based)

### 5) Replace third-party runtime dependencies (patterns)

#### Router → state router

- Implement a tiny state router (context + `navigate(module, subPath)`).
- Optionally keep hash sync for shareable URLs, but the **source of truth must be React state**.

Minimal pattern (adapt, do not paste blindly):

```jsx
const RouterContext = React.createContext();
function RouterProvider({ children }) {
  const [route, setRoute] = React.useState({ module_key: 'text_workbench', subPath: '' });
  const navigate = React.useCallback((module_key, subPath = '') => setRoute({ module_key, subPath }), []);
  return <RouterContext.Provider value={{ route, navigate }}>{children}</RouterContext.Provider>;
}
function useRouter() { return React.useContext(RouterContext); }
```

#### Icons (lucide-react etc.) → inline SVG

- Replace icon imports with local React components that return `<svg ...>` + `<path ...>`.
- Keep size/stroke defaults consistent with the original icon system.

#### Charts (echarts etc.) → SVG/Canvas + fallback table

- Re-implement charts with pure SVG/Canvas.
- Preserve:
  - Tooltips
  - Click/hover actions (emit the same callbacks)
  - Accessible labels (aria where relevant)
  - Data table fallback (for regressions and accessibility)

### 6) Images and external assets

- Replace runtime-loaded images with:
  - `data:image/...;base64,...` (preferred when you need fidelity)
  - Or deterministic placeholders (solid blocks, initials avatars, etc.)
- Never leave remote URLs in the final file unless explicitly allowed.

### 7) Wire the root component to real pages

- Ensure the default export renders the real module pages (not placeholders).
- Wrap providers in the same order as the original app (style/theme/toast/auth).
- Keep module-level side effects intact (e.g. console events, reducers, mock async flows).

### 8) Verification (must run before “done”)

- Confirm only one import remains and it is from `react`.
- Confirm `export default` exists.
- Confirm no `.css`/`.svg`/`.png` imports remain.
- **Pixel-perfect required**: run a visual regression screenshot diff between the original app and the merged component, under the same deterministic environment.
- Optionally do a parse/bundle sanity check:
  - `npx esbuild merged.jsx --bundle --format=esm --external:react --outfile=/tmp/merged.js`

Use the bundled verifier:

```bash
python3 scripts/verify_singlefile_jsx.py /path/to/YourMerged.jsx
```

### Pixel-perfect visual regression (recommended, required if you claim pixel-perfect)

最稳妥的办法是把 `YourMerged.jsx` 暂时放回原 demo 工程里，用原工程的构建链路渲染它（保证字体/CSS 环境一致），然后用截图做像素 diff：

1) 在原工程增加一个“对照页/对照路由”（只用于本地验证）：
   - `OriginalApp`：原始页面
   - `MergedApp`：渲染 `YourMerged.jsx` 的默认导出
2) 用同一套 Playwright 配置跑截图：
   - 固定 viewport / `deviceScaleFactor`
   - `prefers-reduced-motion: reduce`
   - 注入一个 snapshot CSS（仅测试环境）来禁用过渡与动画，例如：
     - `*,*::before,*::after{animation:none!important;transition:none!important;}`
3) 用像素级阈值为 0（或极小阈值）做对比；若有差异，回到 CSS/字体/布局来源排查。

注意：`npx playwright install` 等命令可能会下载浏览器二进制（供应链与联网风险）。如果你的环境要求离线/固定版本，请使用已安装的 Playwright 与固定浏览器版本。

## Bundled Scripts

- `scripts/verify_singlefile_jsx.py`: Heuristic gate to catch non-React imports, `require()`, missing default export, and common TS residue.
