#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  bash scripts/preview_single_jsx_vite.sh path/to/Merged.jsx

Description:
  Create an isolated Vite+React dev server under /tmp and preview ONE single-file React component.
  This avoids modifying your repo and helps catch "white screen" runtime issues early.

Environment variables:
  PORT=5188           Preferred port (may auto-switch if in use; trust Vite's `Local:` output)
  NO_OPEN=1           Do not auto-open the browser
  PREVIEW_ROOT=/tmp/...  Override the temp preview directory (default: unique dir)
  NPM_CACHE=/tmp/...  Override npm cache dir (default: /tmp/npm-cache-$UID)
  USE_LAZY=1          Use React.lazy(import()) (to simulate some runners)

Notes:
  - If Vite prints: "Port XXXX is in use, trying another one...", DO NOT assume failure.
    Always open the URL in the `Local:` line.
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

root_dir="$(pwd)"
target_rel="${1:-}"

if [[ -z "${target_rel}" ]]; then
  echo "Missing argument: path/to/Merged.jsx" >&2
  echo "" >&2
  usage >&2
  exit 1
fi

if [[ ! -f "${target_rel}" ]]; then
  echo "File not found: ${root_dir}/${target_rel}" >&2
  exit 1
fi

if ! command -v node >/dev/null 2>&1; then
  echo "Missing dependency: node" >&2
  exit 1
fi
if ! command -v npm >/dev/null 2>&1; then
  echo "Missing dependency: npm" >&2
  exit 1
fi

target_abs="$(node -e "console.log(require('path').resolve(process.argv[1]))" "${target_rel}")"
target_dir="$(node -e "console.log(require('path').dirname(process.argv[1]))" "${target_abs}")"
target_dir_real="$(node -e "console.log(require('fs').realpathSync(process.argv[1]))" "${target_dir}")"

preview_root_default="${TMPDIR:-/tmp}/single-jsx-preview-$(date +%Y%m%d-%H%M%S)-$$"
preview_root="${PREVIEW_ROOT:-${preview_root_default}}"
mkdir -p "${preview_root}/src"

preview_root_real="$(node -e "console.log(require('fs').realpathSync(process.argv[1]))" "${preview_root}")"

npm_cache="${NPM_CACHE:-${TMPDIR:-/tmp}/npm-cache-${UID:-0}}"
mkdir -p "${npm_cache}"

prototype_fs_path="$(node -e "console.log('/@fs' + require('path').resolve(process.argv[1]))" "${target_abs}")"
prototype_import_json="$(node -e "console.log(JSON.stringify(process.argv[1]))" "${prototype_fs_path}")"
use_lazy="${USE_LAZY:-0}"

cat >"${preview_root}/package.json" <<EOF
{
  "name": "single-jsx-preview",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite"
  },
  "dependencies": {
    "react": "^18.2.0",
    "react-dom": "^18.2.0"
  },
  "devDependencies": {
    "@vitejs/plugin-react": "^4.2.1",
    "vite": "^5.0.8"
  }
}
EOF

cat >"${preview_root}/index.html" <<'EOF'
<!doctype html>
<html lang="zh-CN">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Single JSX Preview</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.jsx"></script>
  </body>
</html>
EOF

cat >"${preview_root}/src/main.jsx" <<'EOF'
import React from 'react'
import ReactDOM from 'react-dom/client'
import App from './App.jsx'

ReactDOM.createRoot(document.getElementById('root')).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
)
EOF

cat >"${preview_root}/vite.config.js" <<EOF
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    host: '127.0.0.1',
    port: Number(process.env.PORT || 5173),
    strictPort: false,
    fs: { allow: ['${target_dir}', '${target_dir_real}', '${preview_root}', '${preview_root_real}'] },
  },
})
EOF

if [[ "${use_lazy}" == "1" ]]; then
  cat >"${preview_root}/src/App.jsx" <<EOF
import React from 'react'

const prototypePath = ${prototype_import_json}

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props)
    this.state = { error: null }
  }
  static getDerivedStateFromError(error) {
    return { error }
  }
  componentDidCatch(error) {
    // keep visible in console for debugging
    console.error('[single-jsx-preview] render error:', error)
  }
  render() {
    if (this.state.error) {
      return (
        <div style={{ padding: 16, fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace' }}>
          <div style={{ fontWeight: 700, marginBottom: 8 }}>Render crashed</div>
          <pre style={{ whiteSpace: 'pre-wrap' }}>{String(this.state.error && (this.state.error.stack || this.state.error))}</pre>
        </div>
      )
    }
    return this.props.children
  }
}

const Prototype = React.lazy(() => import(/* @vite-ignore */ prototypePath))

export default function App() {
  return (
    <ErrorBoundary>
      <React.Suspense fallback={<div style={{ padding: 16 }}>Loading…</div>}>
        <Prototype />
      </React.Suspense>
    </ErrorBoundary>
  )
}
EOF
else
  cat >"${preview_root}/src/App.jsx" <<EOF
import React from 'react'
import Prototype from ${prototype_import_json}

class ErrorBoundary extends React.Component {
  constructor(props) {
    super(props)
    this.state = { error: null }
  }
  static getDerivedStateFromError(error) {
    return { error }
  }
  componentDidCatch(error) {
    console.error('[single-jsx-preview] render error:', error)
  }
  render() {
    if (this.state.error) {
      return (
        <div style={{ padding: 16, fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace' }}>
          <div style={{ fontWeight: 700, marginBottom: 8 }}>Render crashed</div>
          <pre style={{ whiteSpace: 'pre-wrap' }}>{String(this.state.error && (this.state.error.stack || this.state.error))}</pre>
        </div>
      )
    }
    return this.props.children
  }
}

export default function App() {
  return (
    <ErrorBoundary>
      <Prototype />
    </ErrorBoundary>
  )
}
EOF
fi

if [[ ! -x "${preview_root}/node_modules/.bin/vite" ]]; then
  echo "Installing preview dependencies under: ${preview_root}" >&2
  (cd "${preview_root}" && npm_config_cache="${npm_cache}" npm install)
fi

echo "Previewing: ${target_abs}" >&2
echo "Preview root: ${preview_root}" >&2
echo "Tip: If port is in use, always open the URL in Vite's 'Local:' line." >&2

if [[ "${NO_OPEN:-}" != "1" ]]; then
  (cd "${preview_root}" && npm_config_cache="${npm_cache}" npm run dev -- --open)
else
  (cd "${preview_root}" && npm_config_cache="${npm_cache}" npm run dev)
fi
