---
name: skill-review-audit
version: 0.1.1
description: Use when a user asks to review, interpret, or audit an AI agent skill (SKILL.md plus bundled scripts/references/assets) for capabilities, triggering behavior, tool/command usage, safety & privacy risk, supply-chain provenance, quality gaps, and improvement recommendations; also use when validating a skill before installing or deploying it.
---

# Skill Review & Audit

Produce a **systematic, multi-dimensional review** of any skill directory (a `SKILL.md` plus optional `scripts/`, `references/`, `assets/`, and install metadata).

## Non-Mutating Constraint (Default)

- **Default is read-only**: do not create, delete, or modify any files (including `apply_patch`, `sed -i`, overwriting configs, auto-fixes, `git commit`, etc.).
- If the user wants changes applied, **ask for explicit human authorization first** and wait for a clear “yes, apply these edits” (or equivalent) before touching the filesystem.
- You may still propose fixes as text (recommendations or patch snippets), but **do not apply** them without authorization.

## Outcomes

- A clear description of what the skill teaches and *what it does not*.
- A map of **tooling + side effects** the skill may cause when followed (commands, network, file writes, permissions).
- A **risk assessment** (security, privacy, safety, supply chain) with mitigations.
- A **quality assessment** (correctness, completeness, maintainability, UX) with prioritized improvements.
- Optional scoring using `references/scoring-rubric.md`.
- A report formatted using `references/report-template.md`.

## Inputs To Request (If Missing)

- Skill identifier: name and/or filesystem path to the skill directory.
- Target agent environment (e.g. Codex CLI / Claude Code / other) and any constraints (offline, no web, sandboxed, etc.).
- Intended usage context (what kinds of user prompts should trigger it; what “done” looks like).

## Workflow (Do In Order)

### 0) Scope The Review

- Confirm whether the review is **(a)** informational only (read-only) or **(b)** includes proposing patches (still read-only unless explicitly authorized to apply).
- Define what “safe enough” means for the target environment (network allowed? can write files? secrets present?).
- Restate the **Non-Mutating Constraint** and ask for authorization if the user requests edits to be applied.

### 1) Inventory & Provenance

1. List the full directory tree and file sizes.
2. Identify install/provenance files (common: `.openskills.json`, `package.json`, `pyproject.toml`, git submodule markers).
3. Record:
   - Skill root path
   - Total file count
   - Presence of `scripts/`, `references/`, `assets/`
   - Any external source URL + install timestamp (if present)
4. Flag anything unexpected (executables, binaries, obfuscated blobs, huge files, symlinks pointing elsewhere).

Optional helper: run `scripts/scan_skill.sh` (read it first; it is intended to be read-only).
Note: `scan_skill.sh` may surface sensitive strings (e.g., tokens, private keys) depending on the target directory. Treat its output as sensitive; redact before sharing.

### 2) Trigger Contract (Frontmatter Audit)

Read `SKILL.md` YAML frontmatter and assess:

- **Name**: unique, stable, correctly scoped (not overly broad).
- **Description** (primary trigger): includes concrete triggers/symptoms; avoids vague “does everything”.
- **False positives/negatives**: prompts it might match incorrectly vs fail to match.
- **Overlap risk**: collisions with other skills (same domain, similar trigger phrases).

Output: “Trigger Strength” rating + rewrite suggestions.

### 3) Capability Model (What It Teaches)

Extract and summarize:

- Core tasks it claims to support.
- Preconditions and assumptions (tech stack, tools installed, access levels).
- Deliverables (expected outputs, formats, artifacts).
- Anti-scope (“When NOT to use”) and limitations (explicit or missing).
- Degree-of-freedom: where it’s prescriptive vs heuristic.

If the skill includes references, don’t assume the main SKILL.md is complete—sample or selectively read reference files to confirm scope.

### 4) Tooling & Side-Effects Map

Build a table of *everything the skill instructs the agent to do*:

- Shell commands (including examples).
- Network access (curl/wget, HTTP clients, package installs, API calls).
- File system writes (what paths, destructive operations, deletes).
- Privilege/permissions (sudo, elevated access, credential usage).
- External dependencies (libraries, CLIs, SaaS).

For each, record: intent, required permissions, risk, and safe alternatives (sandbox, dry-run, allowlists).

### 5) Security / Privacy / Safety Risk Assessment

Use `references/risk-taxonomy.md` to assess:

- **Prompt injection** exposure (especially if the skill fetches external content).
- **Command injection** risks (string interpolation into shell; unsafe copy/paste patterns).
- **Destructive operations** (rm -rf, overwriting, migrations, irreversible actions).
- **Secrets handling** (API keys, env vars, logs, redaction).
- **Supply-chain** risks (install scripts, unpinned deps, untrusted sources).
- **Data exfiltration** (uploading files, telemetry, “paste logs here” patterns).

Output: severity × likelihood per risk + mitigations + “safe-by-default” recommendations.

### 6) Quality & Correctness Review

- Verify examples for internal consistency (missing imports, wrong prop precedence, mismatched ARIA ids, etc.).
- Check for missing edge cases (cancellation, cleanup, concurrency, accessibility, i18n).
- Check “progressive disclosure” quality: is SKILL.md lean and navigational, with details in `references/`?
- Check for outdated or unstable advice (versions, APIs likely to change); suggest pinning and dates.

### 7) Maintainability & Operational Fit

- Structure: clear headings, searchable keywords, minimal duplication.
- Update strategy: versioning, ownership, changelog expectations (even if no file).
- Testability: are scripts tested? is there a validation workflow?
- Portability: OS assumptions, shell assumptions, tool availability.

### 8) Improvement Plan (Prioritized)

Provide:

- Quick wins (low effort / high impact).
- Structural changes (refactor into references, add scripts, add checklists).
- Safety hardening (guardrails, confirmations, allowlists).
- “Definition of Done” for the next iteration.

### 9) Produce The Report

Use `references/report-template.md` and keep:

- Facts separated from recommendations
- Explicit uncertainty markers when you did not verify something
- Concrete examples (commands, paths, prompts) where useful

## Red Flags — Stop And Re-check

- Only read `SKILL.md` and ignored `scripts/` / `references/`.
- Listed risks without mapping concrete commands/side effects.
- No provenance/supply-chain notes.
- No severity/likelihood distinction (everything “risky”).
- Suggested running scripts you did not read.
- Gave recommendations without tying them to a specific observed gap.

## Deep Checklist (Optional)

If you need a more exhaustive pass, use `references/review-checklist.md` and score with `references/scoring-rubric.md`.
