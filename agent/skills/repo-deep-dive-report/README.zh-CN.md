# Repo Deep Dive Report（代码仓库深度走读报告）

一套“证据驱动”的代码仓库走读流程，用于产出结构化交付物（Markdown + 离线可打开的 HTML），包含 Mermaid 图、可操作的改进建议以及评分表。

## 包含内容

- `SKILL.md`：完整流程与质量门槛
- `references/`：报告大纲、Mermaid 模板、评分口径
- `scripts/repo_snapshot.py`：生成仓库快照（仅标准库）
- `scripts/render_md_to_html.py`：将 Markdown 报告渲染为离线 HTML（仅标准库）

## 安装

> 这一份目录本身就是“技能包”。安装的本质是：让你的编码工具/Agent 运行器能找到这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或用工具的“从 Git 安装 skill”能力）。

### 方式 A：复制安装

在本仓库根目录执行，把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（例如 `~/.codex/skills` / `~/.claude/skills` / `~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
cp -R agent/skills/repo-deep-dive-report "$SKILLS_DIR/repo-deep-dive-report"
```

### 方式 B：软链接安装

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/repo-deep-dive-report"
ln -s "$(pwd)/agent/skills/repo-deep-dive-report" "$SKILLS_DIR/repo-deep-dive-report"
```

### 方式 C：用 openskills 从 GitHub/Git 安装

用 `openskills install` 指向本仓库的 GitHub 地址（或任意 Git URL），在交互界面选择要安装的 skill：

```bash
npx openskills install <git-url>
```

例如（本仓库；注意：这里是**仓库 URL**，不是 GitHub 的 `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany
```

安装时在列表里选择 `repo-deep-dive-report`（其在仓库内的路径是 `agent/skills/repo-deep-dive-report`）。

常用选项：
- `-g`：全局安装
- `-u`：安装到 `.agent/skills/`（便于在不同工具/项目里通用）
- `-y`：跳过交互，安装检测到的全部技能

安装后，可用以下命令验证/读取：

```bash
npx openskills list
npx openskills read repo-deep-dive-report
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，直接把本仓库链接给它即可（并让它选择/指向 `agent/skills/repo-deep-dive-report` 这一子目录）；若不支持，请用上面的复制/软链接/`openskills install`。

### 安装完成后怎么用

一般需要重启/新开会话，让工具重新扫描 skills；之后在对话里直接描述诉求即可，例如：“请按 repo-deep-dive-report 的流程为这个仓库产出一份深度走读报告（MD + HTML）”。

## 推荐用法

1) 先生成仓库快照（辅助走读与引用证据）：

```bash
python3 agent/skills/repo-deep-dive-report/scripts/repo_snapshot.py --repo . --output docs/_repo_snapshot.md
```

2) 按 `references/report_outline.md` 的结构在 `docs/repo_review.md` 编写报告。

3) 渲染成离线 HTML：

```bash
python3 agent/skills/repo-deep-dive-report/scripts/render_md_to_html.py \
  --input docs/repo_review.md \
  --output docs/repo_review.html \
  --title "Repo Review"
```

## 说明

- 两个脚本均为标准库实现，无额外 Python 依赖。
- Mermaid 默认以代码块形式保留，适合离线阅读与迁移。
