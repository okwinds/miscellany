# Redaction Guide: Sharing UI Source Scan Output Safely

`scripts/scan_ui_sources.sh` 的输出通常包含内部路径、组件命名、技术选型关键词命中等信息。对外分享（发到工单、外部聊天、开源 issue 等）前，建议按本文做“可复现脱敏”，并把“原始扫描报告”留在本地。

## 1) 最小脱敏清单（推荐）

在分享前，确保至少做到：

- [ ] 移除/替换绝对路径（例如 `/home/<user>/...`、`C:\Users\...`）
- [ ] 移除 `root:` 与 `generated:` 行（它们经常包含绝对路径与时间戳）
- [ ] 检查是否包含公司/项目代号、私有包名、内部组件前缀（必要时替换）
- [ ] 只分享“相对路径列表”或“目录级汇总”，不要贴整份原始报告

## 2) 快速脱敏（保留结构，去掉 root/时间戳）

假设你已有扫描输出 `ui_sources.md`：

```bash
# 1) 去掉绝对 root 与时间戳
rg -v '^(root:|generated:)' ui_sources.md > ui_sources.redacted.md
```

如果你担心报告里仍然混入了绝对路径（例如其它工具生成的路径），可以再做一次替换：

```bash
# 2) 把 home 路径归一化（示例：Linux/macOS）
sed -E 's#/home/[^/]+#/home/<user>#g' ui_sources.redacted.md > ui_sources.redacted2.md
```

## 3) 只分享“命中列表”（最安全的对外形态）

很多时候对外沟通只需要“我们大概用什么 + 文件大概在哪”，不需要完整报告。

```bash
# 只保留条目（- 开头）与 section 标题（## 开头），并去掉 root/时间戳
rg -v '^(root:|generated:)' ui_sources.md | rg -n '^(## |- )' > ui_sources.list-only.md
```

## 4) 目录级汇总（减少细粒度泄露）

把具体文件路径汇总成“目录计数”，更适合对外：

```bash
# 提取条目行 -> 去掉 "- " -> 取前两级目录 -> 计数排序
rg '^- ' ui_sources.md \
  | sed 's/^- //' \
  | awk -F/ '{print $1"/"$2"/"}' \
  | sort \
  | uniq -c \
  | sort -nr \
  > ui_sources.dir-summary.txt
```

> 注意：如果仓库目录层级不统一，上述“前两级目录”可能不合适；你可以把 `$1"/"$2"/"` 调整成 `$1"/"` 或更多层级。

## 5) 分享前复核建议

- 用肉眼快速搜一遍：项目代号、公司名、私有 npm scope、内部组件前缀
- 用 `rg` 再扫一遍明显敏感字段：

```bash
rg -n '(password|secret|token|apikey|api[-_]?key|internal|confidential|公司名|项目代号)' ui_sources.redacted.md || true
```

## 6) 常见误区

- 误区：把完整扫描报告直接贴到外部（尤其包含 `root:` 绝对路径）
- 误区：把 `package.json` / lockfile 中的私有包名命中也一起分享
- 误区：为了“证明存在”贴出带业务含义的组件名列表（建议目录汇总替代）

