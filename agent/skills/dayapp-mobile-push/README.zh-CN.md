# dayapp-mobile-push

Send a critical mobile push through Day.app (Bark) with one GET request. Use when a task finishes, fails, is blocked, or needs immediate alerting, and you should summarize task name and summary from current task context before sending.

## 包含内容

- `SKILL.md`
- `scripts/`（可选）
- `references/`（可选）
- `assets/`（可选）

## 安装

> 安装 skill 的本质是：让你的编码工具 / Agent 运行器能发现这个目录里的 `SKILL.md`（通常是放进某个 `skills/` 目录，或使用工具内置的“从 Git 安装”能力）。

### 方式 A：复制安装

在仓库根目录执行：

把 `SKILLS_DIR` 改成你的工具会扫描的 skills 目录（示例：`~/.codex/skills`、`~/.claude/skills`、`~/.config/opencode/skills` 等）：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/dayapp-mobile-push"
cp -R agent/skills/dayapp-mobile-push "$SKILLS_DIR/dayapp-mobile-push"
```

### 方式 B：软链接安装

在仓库根目录执行：

```bash
SKILLS_DIR=~/.codex/skills
mkdir -p "$SKILLS_DIR"
rm -rf "$SKILLS_DIR/dayapp-mobile-push"
ln -s "$(pwd)/agent/skills/dayapp-mobile-push" "$SKILLS_DIR/dayapp-mobile-push"
```

### 方式 C：用 openskills 从 GitHub/Git 安装

先准备 openskills：

- 需要 Node.js（建议 18+）。
- 不想安装：直接用 `npx openskills ...`（会自动下载并运行）。
- 想全局安装：`npm i -g openskills`（或 `pnpm add -g openskills`）。

从**可 clone 的仓库 URL** 安装（不要用 GitHub 的 `.../tree/...` 子目录链接）：

```bash
npx openskills install https://github.com/okwinds/miscellany
```

安装时选择 `dayapp-mobile-push`（仓库内路径：`agent/skills/dayapp-mobile-push`）。

验证/读取：

```bash
npx openskills list
npx openskills read dayapp-mobile-push
```

### 方式 D：直接给工具一个 GitHub 链接

不少编码工具支持“从 GitHub/Git URL 安装/加载 skill”。如果你的工具支持，指向本仓库并选择/定位到 `agent/skills/dayapp-mobile-push`。

### 安装完成后

不少工具需要重启/新开会话，才会重新扫描 skills。

## 使用

发送一次通知：

```bash
python3 scripts/send_dayapp_push.py --task-name "构建完成" --task-summary "CLI 构建与测试全部通过"
```

仅预览请求 URL（不发送）：

```bash
python3 scripts/send_dayapp_push.py --task-name "部署阻塞" --task-summary "发布被策略拦截" --dry-run
```
