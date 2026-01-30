#!/usr/bin/env python3
"""
Render a Markdown report to a standalone HTML page (stdlib-only).

Goals:
- Offline-readable HTML with basic CSS and a sidebar table-of-contents
- Preserve fenced code blocks (including mermaid) as visible code blocks
- Minimal, predictable Markdown subset (headings, lists, paragraphs, blockquotes, code fences, inline code, links)

Usage:
  python render_md_to_html.py --input docs/repo_review.md --output docs/repo_review.html --title "Repo Review"
  python render_md_to_html.py --input report.md --output report.html --mermaid-cdn
"""

from __future__ import annotations

import argparse
import datetime as _dt
import html
import os
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional, Tuple


_HEADING_RE = re.compile(r"^(#{1,6})\s+(.*)\s*$")
_FENCE_RE = re.compile(r"^```(\w+)?\s*$")
_UL_RE = re.compile(r"^\s*-\s+(.*)\s*$")
_BQ_RE = re.compile(r"^\s*>\s?(.*)\s*$")
_LINK_RE = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")
_INLINE_CODE_RE = re.compile(r"`([^`]+)`")


def _slugify(text: str) -> str:
    text = text.strip().lower()
    text = re.sub(r"[^\w\u4e00-\u9fff\s-]", "", text)
    text = re.sub(r"\s+", "-", text)
    text = re.sub(r"-{2,}", "-", text)
    return text or "section"


def _escape_inline(text: str) -> str:
    text = html.escape(text, quote=False)
    text = _INLINE_CODE_RE.sub(lambda m: f"<code>{html.escape(m.group(1))}</code>", text)
    text = _LINK_RE.sub(lambda m: f'<a href="{html.escape(m.group(2), quote=True)}">{html.escape(m.group(1))}</a>', text)
    return text


@dataclass(frozen=True)
class Heading:
    level: int
    text: str
    anchor: str


def _parse_markdown(md: str) -> Tuple[str, List[Heading]]:
    lines = md.splitlines()
    out: List[str] = []
    headings: List[Heading] = []

    in_code = False
    code_lang: Optional[str] = None
    code_lines: List[str] = []

    in_ul = False
    in_bq = False
    para: List[str] = []

    def flush_para() -> None:
        nonlocal para
        if not para:
            return
        text = " ".join(s.strip() for s in para if s.strip())
        if text:
            out.append(f"<p>{_escape_inline(text)}</p>")
        para = []

    def flush_ul() -> None:
        nonlocal in_ul
        if in_ul:
            out.append("</ul>")
            in_ul = False

    def flush_bq() -> None:
        nonlocal in_bq
        if in_bq:
            out.append("</blockquote>")
            in_bq = False

    def flush_code() -> None:
        nonlocal in_code, code_lang, code_lines
        if not in_code:
            return
        content = "\n".join(code_lines)
        if code_lang == "mermaid":
            out.append(f"<pre class=\"mermaid\">{html.escape(content)}</pre>")
        else:
            lang_class = f" language-{code_lang}" if code_lang else ""
            out.append(f"<pre><code class=\"code{lang_class}\">{html.escape(content)}</code></pre>")
        in_code = False
        code_lang = None
        code_lines = []

    for raw in lines:
        fence = _FENCE_RE.match(raw)
        if fence:
            if in_code:
                flush_code()
            else:
                flush_para()
                flush_ul()
                flush_bq()
                in_code = True
                code_lang = fence.group(1) or None
                code_lines = []
            continue

        if in_code:
            code_lines.append(raw)
            continue

        heading = _HEADING_RE.match(raw)
        if heading:
            flush_para()
            flush_ul()
            flush_bq()
            level = len(heading.group(1))
            text = heading.group(2).strip()
            anchor = _slugify(text)
            # Ensure unique anchors
            existing = {h.anchor for h in headings}
            if anchor in existing:
                i = 2
                while f"{anchor}-{i}" in existing:
                    i += 1
                anchor = f"{anchor}-{i}"
            headings.append(Heading(level=level, text=text, anchor=anchor))
            out.append(f'<h{level} id="{anchor}">{_escape_inline(text)}</h{level}>')
            continue

        ul = _UL_RE.match(raw)
        if ul:
            flush_para()
            flush_bq()
            if not in_ul:
                out.append("<ul>")
                in_ul = True
            out.append(f"<li>{_escape_inline(ul.group(1))}</li>")
            continue

        bq = _BQ_RE.match(raw)
        if bq:
            flush_para()
            flush_ul()
            if not in_bq:
                out.append("<blockquote>")
                in_bq = True
            txt = bq.group(1)
            if txt.strip():
                out.append(f"<p>{_escape_inline(txt)}</p>")
            continue

        if not raw.strip():
            flush_para()
            flush_ul()
            flush_bq()
            continue

        para.append(raw)

    flush_para()
    flush_ul()
    flush_bq()
    flush_code()

    return "\n".join(out), headings


def _render_toc(headings: Iterable[Heading], max_level: int = 3) -> str:
    items = [h for h in headings if h.level <= max_level]
    if not items:
        return "<p class=\"muted\">(No headings found)</p>"

    out: List[str] = ["<ul class=\"toc\">"]
    for h in items:
        indent = (h.level - 1) * 12
        out.append(
            f'<li class="toc-item" style="margin-left:{indent}px">'
            f'<a href="#{html.escape(h.anchor, quote=True)}">{html.escape(h.text)}</a>'
            "</li>"
        )
    out.append("</ul>")
    return "\n".join(out)


def _html_page(title: str, body_html: str, toc_html: str, mermaid_cdn: bool) -> str:
    generated = _dt.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    mermaid_block = ""
    if mermaid_cdn:
        mermaid_block = """
<script type="module">
  import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs";
  mermaid.initialize({ startOnLoad: true, securityLevel: "strict" });
  mermaid.run({ querySelector: ".mermaid" });
</script>
""".strip()

    css = """
:root{
  --bg:#0b0f14; --panel:#0f1722; --text:#e6edf3; --muted:#9fb0c0;
  --link:#6cb6ff; --border:#1f2a37; --code-bg:#0a0f16; --code-border:#1b2636;
}
@media (prefers-color-scheme: light){
  :root{
    --bg:#ffffff; --panel:#f6f8fa; --text:#1f2328; --muted:#57606a;
    --link:#0969da; --border:#d0d7de; --code-bg:#f6f8fa; --code-border:#d0d7de;
  }
}
*{box-sizing:border-box}
body{margin:0;background:var(--bg);color:var(--text);font:15px/1.65 -apple-system,BlinkMacSystemFont,"Segoe UI",Helvetica,Arial,"PingFang SC","Hiragino Sans GB","Microsoft YaHei",sans-serif}
a{color:var(--link);text-decoration:none} a:hover{text-decoration:underline}
.layout{display:grid;grid-template-columns:320px 1fr;min-height:100vh}
.sidebar{border-right:1px solid var(--border);background:var(--panel);padding:18px 14px;position:sticky;top:0;height:100vh;overflow:auto}
.content{padding:28px 34px;max-width:1100px}
.brand{font-weight:700;margin-bottom:6px}
.meta{color:var(--muted);font-size:12px;margin-bottom:14px}
.toc{list-style:none;padding:0;margin:0}
.toc-item{margin:6px 0}
h1,h2,h3,h4,h5,h6{margin:22px 0 10px;line-height:1.25}
h1{font-size:28px} h2{font-size:22px} h3{font-size:18px}
p{margin:10px 0}
blockquote{margin:12px 0;padding:10px 12px;border-left:4px solid var(--border);background:rgba(255,255,255,0.03)}
pre{background:var(--code-bg);border:1px solid var(--code-border);padding:12px;border-radius:10px;overflow:auto}
code{font-family:ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,"Liberation Mono","Courier New",monospace;font-size:13px}
ul{padding-left:22px}
.muted{color:var(--muted)}
@media (max-width: 980px){.layout{grid-template-columns:1fr}.sidebar{position:relative;height:auto}}
""".strip()

    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1"/>
  <title>{html.escape(title)}</title>
  <style>{css}</style>
</head>
<body>
  <div class="layout">
    <aside class="sidebar">
      <div class="brand">{html.escape(title)}</div>
      <div class="meta">Generated: {html.escape(generated)}<br/><span class="muted">Offline, standalone</span></div>
      {toc_html}
      <hr style="border:0;border-top:1px solid var(--border);margin:16px 0"/>
      <div class="muted" style="font-size:12px">
        Tip: Mermaid blocks are kept as code fences for portability.
      </div>
    </aside>
    <main class="content">
      {body_html}
    </main>
  </div>
  {mermaid_block}
</body>
</html>
"""


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", required=True, help="Input Markdown path")
    parser.add_argument("--output", required=True, help="Output HTML path")
    parser.add_argument("--title", default="Repository Review Report", help="HTML title")
    parser.add_argument("--mermaid-cdn", action="store_true", help="Inject Mermaid CDN loader (optional)")
    args = parser.parse_args()

    md_path = Path(args.input)
    html_path = Path(args.output)

    md = md_path.read_text(encoding="utf-8")
    body_html, headings = _parse_markdown(md)
    toc_html = _render_toc(headings)

    page = _html_page(title=args.title, body_html=body_html, toc_html=toc_html, mermaid_cdn=args.mermaid_cdn)
    html_path.parent.mkdir(parents=True, exist_ok=True)
    html_path.write_text(page, encoding="utf-8")


if __name__ == "__main__":
    main()
