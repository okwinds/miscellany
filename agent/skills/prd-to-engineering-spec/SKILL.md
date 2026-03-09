---
name: prd-to-engineering-spec
description: "Transform PRD (Product Requirements Document) into actionable engineering specifications. Creates detailed technical specs that developers can implement step-by-step without ambiguity. Covers data modeling, API design, business logic, security architecture, deployment, and agent system design. Use when: converting product requirements to technical specs, validating PRD completeness, planning technical implementation, creating task breakdowns, or defining test specifications. Triggers: 'PRD to spec', 'convert requirements', 'technical spec from PRD', 'engineering doc from requirements', 'validate PRD'."
license: MIT
version: "0.1.2"
compatibility: "Requires bash for validation scripts. No external dependencies."
metadata:
  author: 肆〇柒/ForOhZen
  version: "0.1.1"
  category: engineering
  tags: "specification, prd, requirements, technical-design, planning, agent"
---

# PRD to Engineering Spec

## Overview

Transform product requirements into engineering specifications so complete that developers can implement the entire system **step-by-step without ambiguity**, and the resulting system can be **replicated or migrated without information loss**.

### Skill Workflow Context

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ prd-writing-    │────►│ prd-to-         │     │ reverse-        │
│ guide           │     │ engineering-    │     │ engineering-    │
│ Write PRD       │     │ spec            │     │ spec            │
│                 │     │ [THIS SKILL]   │     │ Code→Spec       │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │
         ▼  For AI Agent products:
┌─────────────────┐
│ ai-agent-prd    │────► This skill handles Agent PRD conversion too
└─────────────────┘
```

**Input:** Complete PRD (from `prd-writing-guide` or `ai-agent-prd`)
**Output:** Engineering specifications at replicability-grade detail

**Core Principle:** Validate PRD first, design second. Incomplete requirements → incomplete specs.

## Quick Start

1. Validate PRD against [prd-validation-checklist.md](references/prd-validation-checklist.md)
2. For Agent systems, also validate with [agent-system-spec.md](references/agent-system-spec.md)
3. Generate defect report; do NOT proceed until all ❌ resolved
4. Run `bash scripts/generate_spec_skeleton.sh`
5. Apply the **Engineering Lenses** to every component
6. Fill specs using [spec-templates.md](references/spec-templates.md)
7. Validate with `bash scripts/validate_spec.sh`

---

## The Engineering Lenses

Apply these seven lenses to **every component** during Phases 2-3. They are the engineering equivalent of `prd-writing-guide`'s Seven Lenses.

```
┌──────────────────────────────────────────────────────────────────┐
│                    The Engineering Lenses                         │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. ARCHITECTURE  How does it fit? Layers, modules, comms.       │
│  2. DATA          How modeled, validated, stored, migrated?      │
│  3. CONTRACT      Interfaces? Versioning? What breaks?           │
│  4. FAILURE       How does it fail? Detect, recover, cascade?    │
│  5. SECURITY      Auth, authz, encryption, audit, secrets?       │
│  6. OPERATIONS    Deploy, configure, monitor, scale, rollback?   │
│  7. REPLICABILITY All configs, deps, assumptions documented?     │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

For every major component (service, module, API, data store, integration):

| Lens | Key Question | Spec Output |
|------|-------------|-------------|
| Architecture | Where does it sit? What depends on it? | Module diagram, dependency graph |
| Data | What data does it own? Shape? Consistency? | Entity definitions, schemas |
| Contract | What's the interface? What can't change? | API specs, event schemas |
| Failure | What can go wrong? What then? | Error catalog, retry policies |
| Security | Who accesses? How protected? | Auth rules, encryption spec |
| Operations | How deployed and observed? | Config, metrics, alerts |
| Replicability | Any implicit knowledge not captured? | Env setup, all dependencies |

---

## Workflow

```
Phase 0: PRD Validation ──────► Defect Report ──────► PRD Complete
         ↓
Phase 1: Decomposition ──► User Stories, Requirements Matrix
         ↓
Phase 2: Technical Design (Interactive) ──► Decision Log
         ↓
Phase 3: Detailed Specs ──► Engineering Lenses on every component
         ↓
Phase 4: Test Specs ──► Unit, Integration, E2E, Acceptance
         ↓
Phase 5: Task Breakdown ──► Tasks, Milestones, Risks
         ↓
Phase 6: Assembly & Replicability Review
```

---

## Phase 0: PRD Validation

**Goal:** Ensure PRD completeness before technical work begins.

1. Review against [prd-validation-checklist.md](references/prd-validation-checklist.md)
2. **Agent systems:** Also validate against [agent-system-spec.md](references/agent-system-spec.md) §PRD Validation
3. Mark: ✅ Present | ⚠️ Unclear | ❌ Missing
4. **Do NOT proceed until all ❌ resolved**

### Defect Report Template

```markdown
# PRD Validation Report
**PRD:** [title] | **Status:** [PASS / NEEDS REVISION]

## Critical Gaps (Must Fix)
| # | Category | Issue | Impact | Resolution |
|---|----------|-------|--------|------------|

## Warnings (Should Clarify)
## Assumptions (Document explicitly with risk-if-wrong)
```

---

## Phase 1: Requirements Decomposition

**Goal:** Break PRD into structured, implementable requirements.

### User Story Format

```markdown
## US-001: [Title]
**Priority:** P0/P1/P2
As a [role], I want [action], so that [benefit].
**Acceptance Criteria:** (Given/When/Then)
**Business Rules:** BR-001, BR-002
**Dependencies:** US-002
```

### Requirements Matrix

| ID | Requirement | Source | Type | Priority |
|----|-------------|--------|------|----------|
| FR-001 | [description] | US-001 | CRUD/Logic | P0 |
| NFR-001 | API response <200ms P95 | PRD §7 | Performance | P0 |

---

## Phase 2: Technical Design (Interactive)

**Goal:** Make architectural decisions with explicit user confirmation.

### Decision Process

For each significant decision:
1. Present 2-3 options with **pros, cons, effort, risk, and operational cost**
2. Recommend with rationale
3. **Wait for user confirmation**
4. Record in Decision Log

### Decision Log

| ID | Decision | Options | Chosen | Rationale | Trade-offs | Date |
|----|----------|---------|--------|-----------|------------|------|
| D-001 | Database | PG, Mongo | PostgreSQL | ACID, JSON support | Higher ops complexity | [date] |

### Tech Stack

| Component | Choice | Version | Rationale | Alternatives |
|-----------|--------|---------|-----------|-------------|
| Language | | | | |
| Framework | | | | |
| Database | | | | |
| Cache | | | | |
| Queue | | | | |
| Infra | | | | |

---

## Phase 3: Detailed Specification

**Goal:** Specs detailed enough for implementation without questions. Apply **Engineering Lenses** to every component.

Templates: [spec-templates.md](references/spec-templates.md), [feature-spec-template.md](references/feature-spec-template.md)

### 3.1 Data Model

Per entity: purpose, all fields (type, nullable, default, constraints, description), indexes with rationale, relationships with cascade rules, validation rules, lifecycle (create/update/delete behavior).

### 3.2 API Specification

Per endpoint: method + path, auth/authz, request (params, body, validation rules), response (structure, all status codes with conditions), business logic steps, side effects, rate limits, idempotency.

### 3.3 Business Logic

Per complex rule: interface (inputs/outputs/errors), algorithm in pseudocode, decision table for branching, concrete edge case examples, transaction boundaries, rollback behavior.

### 3.4 Security Architecture ⭐

See [security-spec-guide.md](references/security-spec-guide.md). Specify:

| Area | Must Document |
|------|--------------|
| Authentication | Protocol (OAuth2/JWT/session), token lifecycle, refresh flow, MFA |
| Authorization | Permission model (RBAC/ABAC), role-permission matrix, enforcement points |
| Data Security | Classification levels, encryption (at-rest, in-transit), PII handling |
| Input Security | Validation strategy, injection prevention, file upload rules |
| Audit | Events to log, format, retention period, tamper protection |
| Secrets | Storage method, rotation policy, access control |

### 3.5 Operations & Deployment ⭐

See [operations-spec.md](references/operations-spec.md). Specify:

| Area | Must Document |
|------|--------------|
| Environments | Dev, staging, prod differences; how to provision |
| Deployment | CI/CD pipeline, container spec, rollout strategy |
| Configuration | Every env var / config param with type, default, description, allowed values |
| Monitoring | Key metrics, alert thresholds, dashboard definitions |
| Logging | Format, levels, correlation IDs, PII redaction |
| Scaling | Triggers, resource limits, auto-scale rules |
| Recovery | Backup schedule, RTO/RPO, failover procedure, data restore process |

### 3.6 AI/Agent Components

For AI features: [ai-feature-spec.md](references/ai-feature-spec.md)
For Agent systems: [agent-system-spec.md](references/agent-system-spec.md), covering:
- Agent orchestration (reasoning loop, tool dispatch, state management)
- System prompt as versioned artifact (with testing strategy)
- Skills/Tools registration and dispatch mechanism
- Memory system (working, session, long-term storage design)
- RAG pipeline (embedding → chunking → indexing → retrieval → reranking)
- Evaluation infrastructure and continuous feedback loops
- Cost model per interaction

### 3.7 Migration & Compatibility

If replacing existing system. See [spec-templates.md](references/spec-templates.md) §Migration:
- Data migration strategy (ETL pipeline, validation steps, rollback)
- API backward compatibility (versioning scheme, deprecation timeline)
- Feature parity matrix (old → new mapping, intentional gaps)
- Cutover plan (strategy, rollback trigger, coexistence period)

---

## Phase 4: Test Specification

**Goal:** Tests that verify all requirements are met.

### Traceability Matrix

| Requirement | Unit | Integration | E2E | Acceptance | Performance | Security |
|-------------|------|-------------|-----|------------|-------------|----------|
| FR-001 | UT-001 | IT-001 | E2E-001 | AT-001 | - | - |
| NFR-001 | - | - | - | - | PERF-001 | - |

### Test Types

**Unit:** Per function—happy path, validation, edge cases, error handling.
**Integration:** Module interactions—API contracts, DB operations, external services.
**E2E:** Complete user journeys—critical paths with variations.
**Acceptance:** Given/When/Then—maps to acceptance criteria.
**Performance:** Load/stress under specified conditions—verify NFRs.
**Security:** Auth bypass, injection, permission escalation—verify security spec.

Templates in [spec-templates.md](references/spec-templates.md).

---

## Phase 5: Task Breakdown

### Task Template

```markdown
## TASK-001: [Title]
**Implements:** FR-001, US-001 | **Estimate:** 4h
**Description:** [what to do]
**Done Criteria:** [how to verify]
**Dependencies:** TASK-000 | **Blocks:** TASK-002
```

### Milestones

| Milestone | Tasks | Target | Deliverable | Verification |
|-----------|-------|--------|-------------|--------------|
| M1: Data | 001-003 | [date] | Schema + migrations | Runs clean |
| M2: API | 004-008 | [date] | Endpoints + tests | Integration tests pass |
| M3: Security | 009-011 | [date] | Auth + audit | Security review pass |
| M4: Deploy | 012-014 | [date] | CI/CD + monitoring | Health checks green |

### Risk Register

| Risk | Prob | Impact | Mitigation | Contingency |
|------|------|--------|------------|-------------|
| [risk] | H/M/L | H/M/L | [prevent] | [if happens] |

---

## Phase 6: Assembly & Replicability Review ⭐

### Cross-Reference Check

- [ ] Every user story → functional requirement(s)
- [ ] Every requirement → technical spec section(s)
- [ ] Every spec → test case(s)
- [ ] Every test → traces back to requirement
- [ ] All external dependencies documented with versions

### Replicability Verification

**The bar:** Could a competent team rebuild this system from the spec alone?

- [ ] **Environment:** All dependencies listed with pinned versions. Build + run commands.
- [ ] **Configuration:** Every env var, feature flag, config param documented (type, default, range).
- [ ] **Data:** Schema definitions, seed data specs, migration scripts referenced.
- [ ] **Infrastructure:** Deploy architecture, container specs, resource requirements.
- [ ] **Integrations:** Every external dep has connection details, auth, failure handling.
- [ ] **Business Logic:** No implicit knowledge—every "obvious" rule written down.
- [ ] **Security:** Auth flow, permissions, encryption, secrets handling fully specified.
- [ ] **Monitoring:** Metrics, alerts, dashboards defined—operable from day one.
- [ ] **No TODOs/TBDs:** Every placeholder resolved.

Run: `bash scripts/validate_spec.sh <spec_root>`

---

## Output Structure

```
engineering-spec/
├── 00_Overview/
│   ├── SUMMARY.md, REQUIREMENTS_MATRIX.md, DECISION_LOG.md, TECH_STACK.md
├── 01_Requirements/
│   ├── USER_STORIES.md, FUNCTIONAL_REQS.md, NON_FUNCTIONAL_REQS.md
├── 02_Technical_Design/
│   ├── ARCHITECTURE.md, DATA_MODEL.md, API_SPEC.md
│   ├── BUSINESS_LOGIC.md, AI_COMPONENTS.md (if applicable)
├── 03_Security/
│   ├── AUTH_DESIGN.md, DATA_SECURITY.md, AUDIT_SPEC.md
├── 04_Operations/
│   ├── DEPLOYMENT.md, CONFIGURATION.md, MONITORING.md, RUNBOOK.md
├── 05_Testing/
│   ├── TEST_PLAN.md, ACCEPTANCE_TESTS.md
├── 06_Implementation/
│   ├── TASK_BREAKDOWN.md, MILESTONES.md, RISKS.md, MIGRATION.md
└── SPEC_INDEX.md
```

---

## Resources

- `scripts/generate_spec_skeleton.sh` - Create output structure
- `scripts/validate_spec.sh` - Validate spec completeness
- `references/prd-validation-checklist.md` - PRD validation checklist
- `references/spec-templates.md` - Specification templates
- `references/feature-spec-template.md` - Feature spec template
- `references/ai-feature-spec.md` - AI feature specification
- `references/agent-system-spec.md` - Agent system engineering spec ⭐
- `references/security-spec-guide.md` - Security architecture spec ⭐
- `references/operations-spec.md` - Operations & deployment spec ⭐
- `references/worked-example.md` - **End-to-end worked example** (HelpBot PRD→Spec) ⭐

---

## Critical Reminders

1. **Validate PRD first** — Incomplete requirements = incomplete specs
2. **Apply Engineering Lenses** — Every component through all 7 lenses
3. **Confirm decisions** — Document rationale, not just choices
4. **Trace everything** — Requirement → Spec → Test → Requirement
5. **Security is architecture** — Not a checkbox; design it explicitly
6. **Operations from day one** — Deploy/monitor/debug specs are not optional
7. **Replicability is the bar** — If it can't be rebuilt from the spec, it's incomplete
