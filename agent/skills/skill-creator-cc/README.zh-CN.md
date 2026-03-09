# skill-creator-cc

Create new skills, modify and improve existing skills, and measure skill performance. Use when users want to create a skill from scratch, update or optimize an existing skill, run evals to test a skill, benchmark skill performance with variance analysis, or optimize a skill's description for better triggering accuracy.

## 包含内容

- `SKILL.md`
- `scripts/`（可选）
- `references/`（可选）
- `assets/`（可选）
- `agents/`（基准测试/评审流程使用的专用子代理提示）
- `eval-viewer/`（用于人工查看输出结果的自包含评审页生成器）

## 安装

> 安装 skill 的本质是：让你的编码工具 / Agent 运行器能发现这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或使用工具内置的“从 Git 安装”能力）。

### 方式 A：复制安装

在仓库根目录执行：

把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（示例：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/skill-creator-cc"
cp -R agent/skills/skill-creator-cc "$SKILLS_DIR/skill-creator-cc"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/skill-creator-cc"
ln -s "$(pwd)/agent/skills/skill-creator-cc" "$SKILLS_DIR/skill-creator-cc"
```

### 方式 C：用 openskills 从 GitHub/Git 安装

先准备 openskills：

- 需要 Node.js（建议 18+）。
- 不想安装：直接用 `npx openskills ...`（会自动下载并运行）。
- 想全局安装：`npm i -g openskills`（或 `pnpm add -g openskills`）。

从**可 clone 的仓库 URL** 安装（不要用 GitHub 的 `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany.git
```

安装时选择 `skill-creator-cc`（仓库内路径：`agent/skills/skill-creator-cc`）。

验证/读取：

```bash
npx openskills list
npx openskills read skill-creator-cc
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/skill-creator-cc`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 使用示例

skill 的主入口仍然是 `SKILL.md`，但它同时附带了几个可直接运行的辅助脚本，方便做校验、打包和结果评审。

校验已复制/发布的 skill：

```bash
python3 ./scripts/quick_validate.py .
```

打包成 `.skill` 分发文件：

```bash
python3 -m scripts.package_skill .
```

从评测 workspace 生成静态评审页：

```bash
python3 ./eval-viewer/generate_review.py \
  /path/to/skill-workspace/iteration-1 \
  --skill-name skill-creator-cc \
  --static /tmp/skill-creator-cc-review.html
```
