---
name: repo-compliance-audit
version: 0.1.1
description: 对任意代码仓库进行合规审计并生成可取证报告（Markdown + JSON findings），覆盖“是否遵循 AGENTS.md/仓库规则/用户指令”“文档索引/规格/工作记录/任务总结”“TDD 与离线回归证据”“可复现性（.env.example 等）”“潜在密钥泄露与仓库卫生”等；并支持在**人类勾选 finding.id** 后执行选择性低风险整改（默认不改业务逻辑）。触发场景：仓库交付前自检、接手陌生仓库、需要合规审计报告、需要把整改条目做成可选择的执行清单。
---

# Repo Compliance Audit

本 skill 提供一个两阶段工作流：**先审计出报告，再由人类勾选需要整改的条目，最后执行选择性整改**。核心目标是“合规审查可取证”和“整改最小化、默认不改业务逻辑”。

## 工作流（Audit → 人类勾选 → Remediation）

### 1) Audit（只读审计，默认不改仓库）

在目标仓库根目录运行（或用 `--repo` 指定）：

```bash
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit
```

输出：
- `report.md`：人类可读审计报告（结论摘要、风险分级、证据、整改清单）
- `findings.json`：机器可读发现列表（包含 `finding.id`、证据与建议修复）

CI / 门禁用法（可选）：

```bash
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit --fail-on high
```

推荐门禁策略（面向“执行过程对齐 AGENTS.md”）

- **最小门禁（推荐默认）**：用 `--fail-on high`，主要拦截：
  - 规则文件完整性高风险：`AGENTS_MD_DELETED` / `AGENTS_MD_MODIFIED`
  - 过程证据高风险：`AGENTS_EXECUTION_TEST_EVIDENCE_MISSING`
  - 明显安全风险：`POSSIBLE_SECRET_FOUND`
- **严格门禁（按需启用）**：用 `--fail-on medium`，会额外拦截：
  - Spec-first 证据缺失类（例如 `SPEC_ENTRYPOINT_MISSING`、`AGENTS_EXECUTION_SPEC_FIRST_EVIDENCE_MISSING`）
  - worklog 过程证据缺失类（例如 `AGENTS_EXECUTION_WORKLOG_EVIDENCE_MISSING`）

输出脱敏（共享报告时建议开启）：

```bash
# 仅脱敏 report.md（保留 findings.json 供系统编排/整改使用）
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit --redact report

# report.md + findings.json 均脱敏（对外共享）
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit --redact all
```

降低泄露/噪声（可选）：

```bash
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit --no-git-meta
python3 scripts/audit_repo.py --repo . --out /tmp/repo-compliance-audit --no-secret-scan
```

### 2) 人类勾选要整改的条目

从 `report.md` 或 `findings.json` 里选择 `finding.id`，用逗号分隔或写入文件。

### 3) Remediation（选择性整改，默认只跑 safe-to-autofix）

```bash
python3 scripts/remediate_repo.py \
  --repo . \
  --findings /tmp/repo-compliance-audit/findings.json \
  --select DOCS_INDEX_MISSING,ENV_EXAMPLE_MISSING
```

约束：
- 默认仅执行 `safe_to_autofix=true` 的修复项
- 默认不覆盖已有文件（除非显式 `--overwrite`）
- 默认不改业务逻辑（只做“合规骨架/证据/仓库卫生”类修复）

## 输出如何被系统使用（强结构 vs 生态兼容）

- **控制面强结构**：`findings.json` 用于系统级交互（可编排、可审计、可做门禁）。
- **对人类生态友好**：`report.md` 以可读性优先，不强制结构化 JSON。
- **避免每个节点都强制结构化**：仅在“门禁/节点确实需要机器可读判断”时启用 `--fail-on` 或只对某些 finding 做 gate。
- **规则文件完整性优先**：如果你关注编码智能体的规则被“删除/篡改”，可以重点关注审计输出中的 `AGENTS_MD_DELETED/AGENTS_MD_MODIFIED/AGENTS_MD_UNTRACKED`（基于 git 取证，若非 git 仓库则仅能提示）。

## 资源

- `./scripts/audit_repo.py`：审计入口
- `./scripts/remediate_repo.py`：整改入口（按 `finding.id` 选择性执行）
- `./references/finding-catalog.md`：finding ID 目录（扩展/对齐口径用）
