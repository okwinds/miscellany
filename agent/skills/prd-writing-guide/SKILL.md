---
name: prd-writing-guide
version: "0.1.1"
description: "Write complete, unambiguous PRDs that development teams can implement without guesswork. Includes requirement discovery framework, structured documentation methodology, completeness checklists, and common pitfall avoidance. Use when: writing new PRDs, reviewing PRD drafts, validating requirement completeness, preparing for engineering handoff. Triggers: 'write PRD', '写PRD', '产品需求文档', '需求文档', '需求规格', '需求评审', '完善需求', 'create requirements doc', 'product requirements', 'feature spec', 'requirements document'. Anti-triggers: 'technical design doc', 'architecture design', 'implementation plan', 'API design', '架构设计', '技术方案', '实现方案', '接口设计'."
license: MIT
compatibility: "No system dependencies. Bash scripts optional for skeleton generation."
metadata:
  author: 肆〇柒/ForOhZen
  version: "0.1.0"
  category: product-management
  tags: "prd, requirements, product-management, documentation"
---

# PRD Writing Guide

## Overview

Write PRDs so complete that development teams can implement the entire product **without asking a single clarifying question**.

### Skill Workflow Context

This skill is part of a 3-skill pipeline:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│ prd-writing-    │────►│ prd-to-         │     │ reverse-        │
│ guide           │     │ engineering-    │     │ engineering-    │
│                 │     │ spec            │     │ spec            │
│ [THIS SKILL]    │     │ PRD→Eng Spec   │     │ Code→Spec       │
└─────────────────┘     └─────────────────┘     └─────────────────┘

For AI Agent products, use `ai-agent-prd` instead (which extends this skill).
```

**Handoff contract:** The PRD this skill produces must be complete enough to pass `prd-to-engineering-spec`'s Phase 0 validation without any ❌ items.

### The PRD Quality Test

```
┌─────────────────────────────────────────────────────────────────┐
│                     The Developer Test                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  Give your PRD to a developer who knows nothing about the      │
│  project. Can they:                                            │
│                                                                 │
│  □ Understand WHY we're building this?                         │
│  □ Know exactly WHAT to build (and what NOT to)?               │
│  □ Handle EVERY edge case without guessing?                    │
│  □ Write test cases for EVERY requirement?                     │
│  □ Estimate the work with confidence?                          │
│                                                                 │
│  If any answer is "no", your PRD is incomplete.                │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Core Principle: Eliminate Ambiguity

**Every sentence in a PRD should have exactly one interpretation.**

| Ambiguous (❌) | Precise (✅) |
|----------------|--------------|
| "Fast response time" | "API response < 200ms at P95" |
| "User-friendly interface" | "New users complete task in < 2 minutes without help" |
| "Handle errors gracefully" | "Show error toast with retry button; log to monitoring" |
| "Support large datasets" | "Handle up to 1M records with < 3s query time" |
| "Secure authentication" | "OAuth 2.0 with JWT, 24h token expiry, refresh tokens" |

## Quick Start

1. Use the [Discovery Questions](#phase-1-requirement-discovery) to gather requirements
2. Structure with the [PRD Template](references/prd-template.md)
3. Apply the [Seven Lenses](#the-seven-lenses) to each requirement
4. Validate with the [Completeness Checklist](references/completeness-checklist.md)
5. Verify with the [Developer Handoff Checklist](#developer-handoff-checklist)

### Sensitive Information & Confidentiality (Required)

PRDs often contain information that should **not** leak outside your organization.

- **Do not** paste secrets (API keys, tokens, passwords), customer PII, private endpoints, internal credentials, or confidential incident details into the PRD.
- Use **placeholders** instead (e.g., `OPENAI_API_KEY`, `[INTERNAL_URL]`, `[CUSTOMER_ID]`) and keep the real values in your secret manager / internal docs.
- Before sharing a PRD externally (vendors, community, public issues), do a quick **redaction pass**:
  - Replace internal URLs, private repo links, Jira/Linear IDs (if sensitive), and customer names.
  - Remove exact budgets/cost ceilings if they are confidential (or mark them as ranges).

### Product Type Emphasis

Different products require different PRD emphasis. Adjust depth accordingly:

| Product Type | Emphasize | De-emphasize |
|-------------|-----------|--------------|
| **Mobile/Web App** | UX flows, states, responsive design, accessibility | Infrastructure details |
| **API Service** | Interface contracts, data schemas, error codes, rate limits | UI/UX flows |
| **Data Pipeline** | Data flow diagrams, transformation rules, quality checks, SLAs | User interaction |
| **B2B SaaS** | Multi-tenancy, permissions, billing, onboarding | Consumer UX patterns |
| **AI-Powered Product** | See [ai-features-prd.md](references/ai-features-prd.md); for Agents use `ai-agent-prd` | N/A |
| **Internal Tool** | Workflow efficiency, integration with existing systems | Scalability, marketing |

---

## Workflow Overview

```
Phase 1: Discovery ────► Understand the problem space
         ↓
Phase 2: Structure ────► Organize requirements systematically
         ↓
Phase 3: Detail ───────► Fill in every edge case
         ↓
Phase 4: Validate ─────► Check completeness
         ↓
Phase 5: Review ───────► Confirm with stakeholders & dev
```

---

## Phase 1: Requirement Discovery

**Goal:** Ask the right questions to uncover all requirements.

### The Discovery Framework

For every feature, systematically explore these dimensions:

#### 1. Problem Space
- What problem are we solving?
- Who has this problem? How severe is it?
- How do they solve it today? What's painful?
- Why solve it now? What's the business driver?
- How will we know we've solved it? (Metrics)

#### 2. User Space
- Who are ALL the users? (Don't forget admins, support, etc.)
- What are their goals? Motivations?
- What's their technical proficiency?
- What context are they in? (Mobile? Rushed? Multitasking?)
- How often will they use this?

#### 3. Functional Space
- What must the system DO?
- What must it NOT do? (Explicit scope boundaries)
- What's the MVP vs. nice-to-have?
- What's the complete happy path?
- What's every unhappy path?

#### 4. Data Space
- What data is needed?
- Where does it come from?
- How is it created, updated, deleted?
- How long must it be retained?
- Who can see/modify it?

#### 5. Integration Space
- What systems does this connect to?
- What data is exchanged?
- What if those systems are unavailable?
- Who owns those systems?

#### 6. Constraint Space
- What are the performance requirements?
- What are the security requirements?
- What are the compliance requirements?
- What are the budget/timeline constraints?
- What existing systems/tech must we use?

### Discovery Questions Template

See [discovery-questions.md](references/discovery-questions.md) for a comprehensive question bank organized by domain.

---

## Phase 2: Requirement Structure

**Goal:** Organize discovered requirements into a navigable, complete document.

### PRD Structure

```
1. Executive Summary
   - One-paragraph problem statement
   - One-paragraph solution overview
   - Success metrics (3-5 key KPIs)

2. Background & Context
   - Business context
   - User research summary
   - Current state analysis
   - Competitive landscape (if relevant)

3. Goals & Non-Goals
   - What we're trying to achieve
   - What we're explicitly NOT doing
   - Success criteria

4. User Stories & Requirements
   - User personas
   - User stories with acceptance criteria
   - Functional requirements
   - Business rules

5. User Experience
   - User flows
   - Wireframes/mockups
   - Interaction specifications
   - Error states and messaging

6. Data Requirements
   - Data model (conceptual)
   - Data sources
   - Data lifecycle

7. Non-Functional Requirements
   - Performance
   - Security
   - Scalability
   - Accessibility

8. Dependencies & Integrations
   - System dependencies
   - External integrations
   - Team dependencies

9. Timeline & Milestones
   - Phases
   - Key milestones
   - Release criteria

10. Risks & Open Questions
    - Known risks
    - Assumptions
    - Unresolved questions

Appendix
    - Glossary
    - Reference documents
    - Revision history
```

See [prd-template.md](references/prd-template.md) for the complete template with examples.

---

## Phase 3: Requirement Detail

**Goal:** Make every requirement implementable without guesswork.

### The Seven Lenses

Apply these seven lenses to EVERY requirement to ensure completeness:

```
┌──────────────────────────────────────────────────────────────────┐
│                        The Seven Lenses                          │
├──────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. HAPPY PATH: What happens when everything works?              │
│                                                                  │
│  2. SAD PATHS: What can go wrong? How do we handle each?         │
│                                                                  │
│  3. EDGE CASES: What are the boundary conditions?                │
│                                                                  │
│  4. PERMISSIONS: Who can do this? Who can't?                     │
│                                                                  │
│  5. STATE: What states exist? How do they transition?            │
│                                                                  │
│  6. DATA: What data flows in/out? Validation? Persistence?       │
│                                                                  │
│  7. FEEDBACK: What does the user see/hear at each step?          │
│                                                                  │
└──────────────────────────────────────────────────────────────────┘
```

### Lens 1: Happy Path

Document the complete successful flow:
- Entry point: How does the user start?
- Each step: What exactly happens?
- Exit point: How does it end?
- Result: What's the outcome?

### Lens 2: Sad Paths

For every step, ask "what if it fails?":

| Failure Type | Questions to Answer |
|--------------|---------------------|
| **User Error** | Invalid input → What message? Can they retry? |
| **System Error** | Server fails → What message? Data preserved? |
| **External Failure** | Integration down → Fallback? Retry? Queue? |
| **Timeout** | Operation takes too long → Cancel? Retry? |
| **Concurrency** | Two users edit same thing → Who wins? Conflict resolution? |

### Lens 3: Edge Cases

| Category | Examples |
|----------|----------|
| **Empty** | Zero items, blank input, no data yet |
| **One** | Single item (different from multiple) |
| **Many** | Maximum items, pagination needed |
| **Boundary** | Min/max values, exactly at threshold |
| **Invalid** | Wrong type, out of range, special characters |
| **Timing** | Midnight, timezone boundaries, DST transitions |

### Lens 4: Permissions

For every action, define:

| Question | Example Answer |
|----------|----------------|
| Who can perform this? | Admin, Owner, Member |
| Who cannot? | Guest, Suspended users |
| What if unauthorized? | 403 page with "request access" button |
| How are permissions assigned? | Owner grants via settings page |
| Can permissions be revoked? | Yes, immediate effect |

### Lens 5: State

For entities with state, document:

```
State Machine Example:

┌───────┐    submit    ┌─────────┐    approve    ┌──────────┐
│ Draft │─────────────►│ Pending │──────────────►│ Approved │
└───────┘              └─────────┘               └──────────┘
    ▲                       │
    │         reject        │
    └───────────────────────┘

Transitions:
- Draft → Pending: Author submits. Requires: all fields filled.
- Pending → Approved: Admin approves. Side effect: notify author.
- Pending → Draft: Admin rejects. Requires: reason. Notify author.

Who can trigger:
- Submit: Author only
- Approve/Reject: Admin only
```

### Lens 6: Data

For every piece of data:

| Attribute | Specify |
|-----------|---------|
| **Source** | Where does it come from? |
| **Type** | String, number, date, enum, etc. |
| **Format** | Regex pattern, max length, allowed values |
| **Required** | Is it optional? Conditionally required? |
| **Default** | If not provided, what value? |
| **Validation** | What makes it valid/invalid? |
| **Display** | How is it shown to users? |
| **Storage** | How long kept? Where stored? |

### Lens 7: Feedback

At every step, what does the user experience?

| Step | Visual Feedback | Audio/Haptic | Message |
|------|-----------------|--------------|---------|
| Loading | Spinner on button | None | None |
| Success | Green checkmark | Success chime | "Saved successfully" |
| Error | Red highlight | Error vibration | "Email format invalid" |
| Warning | Yellow banner | None | "Unsaved changes will be lost" |

---

## Phase 4: Validation

**Goal:** Verify PRD completeness before handoff.

### Completeness Checklist

Use [completeness-checklist.md](references/completeness-checklist.md) to verify every section.

### Self-Review Questions

Before sharing the PRD, ask yourself:

1. **The Stranger Test**: Could someone who knows nothing about this project implement it?

2. **The Negative Test**: Have I defined what we're NOT doing?

3. **The Edge Case Test**: Have I thought about empty, one, many, and error states?

4. **The Permission Test**: Have I defined who can do what?

5. **The State Test**: Have I mapped all states and transitions?

6. **The Failure Test**: Have I documented what happens when things go wrong?

7. **The Metric Test**: Have I defined how we'll measure success?

8. **The Test Case Test**: Could QA write test cases from this?

---

## Phase 5: Review

**Goal:** Confirm understanding with stakeholders and development team.

### Stakeholder Review

Confirm with product/business stakeholders:
- [ ] Problem statement accurate?
- [ ] Success metrics agreed?
- [ ] Scope and non-scope correct?
- [ ] Priority order correct?
- [ ] Timeline realistic?

### Engineering Review

Walk through with development team:
- [ ] Requirements understood?
- [ ] Questions answered?
- [ ] Technical feasibility confirmed?
- [ ] Effort estimate possible?
- [ ] Dependencies identified?
- [ ] Risks surfaced?

### The Question Log

Track every question asked during reviews:

| Question | Asker | Answer | Added to PRD? |
|----------|-------|--------|---------------|
| "What if user has no email?" | Dev | "Email required for signup" | ✓ Section 4.2 |

**Every question reveals a gap.** Update the PRD with the answer.

---

## Developer Handoff Checklist

Before declaring PRD "ready for development":

### Content Completeness
- [ ] Every user story has acceptance criteria
- [ ] Every acceptance criterion is testable
- [ ] All business rules documented with examples
- [ ] All edge cases documented
- [ ] All error handling specified
- [ ] All states and transitions mapped
- [ ] All permissions defined
- [ ] All data fields specified with validation

### Clarity
- [ ] No ambiguous terms (search for: appropriate, reasonable, etc.)
- [ ] No missing boundaries (search for: large, many, some)
- [ ] No undefined references (every term in glossary or explained)

### Testability
- [ ] QA can write test cases for every requirement
- [ ] Success criteria are measurable
- [ ] Non-functional requirements are quantified

### Alignment
- [ ] Stakeholders have approved
- [ ] Engineering has reviewed
- [ ] Questions have been answered and documented

---

## Common Pitfalls

See [common-pitfalls.md](references/common-pitfalls.md) for detailed guidance on avoiding these mistakes:

### Pitfall 1: Solution Disguised as Problem
❌ "We need a dashboard"
✅ "Users can't see their key metrics at a glance. They currently export to Excel and manually calculate."

### Pitfall 2: Vague Acceptance Criteria
❌ "User can easily create an account"
✅ "User completes signup in < 60 seconds with only email and password"

### Pitfall 3: Missing Negative Cases
❌ "User can upload a file"
✅ "User can upload a file (max 10MB, types: PDF/DOC/DOCX). On invalid type: show error and list allowed types. On size exceeded: show error with current and max size."

### Pitfall 4: Implicit Assumptions
❌ "Display user's orders"
✅ "Display user's orders (sorted by date descending, paginated at 20 per page, show last 90 days by default)"

### Pitfall 5: Missing State Handling
❌ "Order can be cancelled"
✅ "Order can be cancelled by customer if status is Pending or Confirmed. Shipped orders cannot be cancelled (show 'Contact support'). Cancellation triggers: refund, inventory restore, email notification."

---

## AI Feature Requirements

If your product includes AI features, see [ai-features-prd.md](references/ai-features-prd.md) for additional requirements:

- Behavioral specification (what the AI should do)
- Quality metrics (accuracy, relevance, etc.)
- Failure handling (what if AI fails or produces bad output?)
- User expectations (how to set appropriate expectations)
- Feedback mechanisms (how users report issues)
- Cost considerations (if applicable)

---

## Resources

**Scripts:**
- `scripts/generate_prd_skeleton.sh` - Generate PRD document structure

**References:**
- `references/prd-template.md` - Complete PRD template with examples
- `references/discovery-questions.md` - Comprehensive question bank
- `references/completeness-checklist.md` - Validation checklist
- `references/common-pitfalls.md` - Mistakes to avoid
- `references/ai-features-prd.md` - AI feature requirements guide
- `references/writing-style-guide.md` - How to write clear requirements
- `references/prioritization-management.md` - Priority frameworks, change management, compliance
- `references/worked-example.md` - **End-to-end worked example** (HelpBot customer support agent)

---

## Summary: The PRD Writer's Mindset

```
┌─────────────────────────────────────────────────────────────────┐
│  1. ASSUME NOTHING - If not written, it doesn't exist.         │
│  2. BE SPECIFIC - Numbers, not adjectives.                     │
│  3. THINK NEGATIVELY - What can go wrong?                      │
│  4. SEEK CHALLENGES - Questions reveal gaps.                   │
│  5. ITERATE - PRDs are never done on first draft.              │
└─────────────────────────────────────────────────────────────────┘
```

The goal is to **transfer understanding** so completely that anyone can build exactly what you envision.
