# UI/UX Spec Genome

构建一套可复刻、可移植的 UI/UX 规范“基因”：扫描前端仓库中的 UI 相关源文件，并生成标准化的 `ui-ux-spec/` 文档包骨架（tokens、全局样式、组件、模式、页面模板、可访问性）。同时支持“基于已有 `ui-ux-spec/` 的计划驱动、分阶段 UI-only 重构”。

## 包含内容

- `SKILL.md`：工作流 + prompt 模板
- `scripts/scan_ui_sources.sh`：用 globs + 关键字命中对仓库做启发式扫描，定位 UI 相关文件
- `scripts/generate_output_skeleton.sh`：生成标准的 `ui-ux-spec/` 文档目录骨架
- `scripts/lint_replica_spec.sh`：复刻级规格文档 lint（禁止占位符）
- `references/design-extraction-checklist.md`：更细的提取检查清单

## 安装

> 安装一个 skill 的意思是：让你的编码工具 / Agent Runner 能发现这个目录中的 `SKILL.md`（通常是把目录放进某个 `skills/` 目录里，或使用工具的 “install from Git” 功能）。

### 方式 A：复制（copy）

在本仓库根目录执行，把 `SKILLS_DIR` 设置为你的工具会扫描的 skills 目录（例如 `~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
case "$SKILLS_DIR" in
  ""|"/") echo "拒绝执行：SKILLS_DIR 为空或为 /" >&2; exit 2 ;;
esac
case "$SKILLS_DIR" in
  */skills|*/skills/) ;;
  *) echo "拒绝执行：SKILLS_DIR 通常应以 /skills 结尾（当前：$SKILLS_DIR）" >&2; exit 2 ;;
esac
mkdir -p "$SKILLS_DIR"
rm -rf -- "$SKILLS_DIR/ui-ux-spec-genome"
cp -R agent/skills/ui-ux-spec-genome "$SKILLS_DIR/ui-ux-spec-genome"
```

### 方式 B：软链接（symlink）

```bash
SKILLS_DIR=~/.codex/skills
case "$SKILLS_DIR" in
  ""|"/") echo "拒绝执行：SKILLS_DIR 为空或为 /" >&2; exit 2 ;;
esac
case "$SKILLS_DIR" in
  */skills|*/skills/) ;;
  *) echo "拒绝执行：SKILLS_DIR 通常应以 /skills 结尾（当前：$SKILLS_DIR）" >&2; exit 2 ;;
esac
mkdir -p "$SKILLS_DIR"
rm -rf -- "$SKILLS_DIR/ui-ux-spec-genome"
ln -s "$(pwd)/agent/skills/ui-ux-spec-genome" "$SKILLS_DIR/ui-ux-spec-genome"
```

### 方式 C：通过 openskills 从 GitHub/Git 安装

openskills 前置条件：

- 需要 Node.js（建议 18+）。
- 直接用 `npx openskills ...` 无需提前安装。
- 可选全局安装：`npm i -g openskills`（或 `pnpm add -g openskills`）。

从可 clone 的仓库 URL 安装（不要用 GitHub 的 `.../tree/...` 子目录链接）：

```bash
# 建议固定版本，降低供应链漂移风险
# 示例固定版本：1.5.0
npx openskills@1.5.0 install https://github.com/okwinds/miscellany
```

按提示选择 `ui-ux-spec-genome`（仓库路径：`agent/skills/ui-ux-spec-genome`）。

验证 / 回读：

```bash
npx openskills@1.5.0 list
npx openskills@1.5.0 read ui-ux-spec-genome
```

### 方式 D：让工具直接使用 GitHub 链接

一些工具支持直接从 GitHub/Git URL 加载 skills。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/ui-ux-spec-genome` 即可；否则用 copy/symlink 或 openskills。

### 安装后

很多工具需要重启 / 新开会话才能重新扫描 skills。

## 使用方法

### 依赖

- `bash`
- `rg`（ripgrep）：`scripts/scan_ui_sources.sh` 必需
- 可选：`git`（用于自动解析仓库根目录）
- 复刻级 lint：`python3`（`scripts/lint_replica_spec.sh` 会用到）

### 扫描 UI 来源

```bash
bash agent/skills/ui-ux-spec-genome/scripts/scan_ui_sources.sh --root /path/to/repo --out /tmp/ui_sources.md
```

### 生成 `ui-ux-spec/` 文档骨架

```bash
bash agent/skills/ui-ux-spec-genome/scripts/generate_output_skeleton.sh ./ui-ux-spec
```

如果要写“复刻级 / 像素级 1:1”的规格文档：

```bash
bash agent/skills/ui-ux-spec-genome/scripts/generate_output_skeleton.sh ./ui-ux-spec --replica
# 草稿阶段模板字段通常为空：先用非严格模式
bash agent/skills/ui-ux-spec-genome/scripts/lint_replica_spec.sh --root ./ui-ux-spec --non-strict
# 交付前必须通过严格 lint
bash agent/skills/ui-ux-spec-genome/scripts/lint_replica_spec.sh --root ./ui-ux-spec
```

## 注意事项

- 扫描输出通常包含内部路径、技术选型、组件命名等信息，建议对外分享前先脱敏/摘要。
- `scripts/scan_ui_sources.sh --out ...` 默认不会覆盖已存在文件；如确需覆盖请使用 `--force`。
- 不要盲目执行扫描到的仓库文档（README/CONTRIBUTING 等）里的命令/脚本；先审查，再在隔离环境运行。
