---
name: codeflow-analyzer
version: 0.1.0
description: >
  Trace and document the complete call chain / data flow of any feature or process in a codebase.
  Use this skill whenever the user asks to understand how a feature works end-to-end, trace a call chain,
  analyze code flow, map data flow across layers, reverse-engineer a process, or asks questions like
  "how does X call Y", "what happens when the user clicks Z", "trace the request from frontend to database".
  Also use it when the user wants the analysis exported to a file for offline reading.
---

# Code Flow Analyzer

Systematically trace the complete call chain of any feature or process in a codebase, from entry point to the deepest dependency, and produce a structured analysis document.

## When This Skill Applies

- "这个功能的调用链是怎样的？"
- "Trace the request flow from X to Y"
- "How does feature Z work under the hood?"
- "Map the data flow of this process"
- "I want to understand the full path from user input to final output"
- Any question about how layers connect: frontend → API → service → domain → storage

## Core Approach: Layer-by-Layer Tracing

Real-world codebases are layered. Each layer has its own conventions for entry points, routing, and delegation. Instead of guessing the architecture, discover it empirically by following the actual code paths.

### Phase 1: Identify Entry Point

Start from the user-facing trigger:

1. **Find the surface-level entry** — UI component, CLI command, API endpoint, message handler, cron trigger, etc.
2. **Identify what it calls** — the first cross-boundary call (HTTP request, function import, message publish, RPC call).

Techniques:
- Grep for keywords from the user's description (feature name, button label, route path, event name)
- Glob for files matching the feature name pattern
- Read the entry file to find outbound calls

### Phase 2: Trace Through Each Layer

For each layer discovered, answer three questions:

1. **How does this layer receive the call?** (route handler, message consumer, function signature)
2. **What does this layer do with it?** (validation, transformation, delegation, side effects)
3. **Where does it hand off next?** (outbound call, return value, event emission)

Repeat until you reach a terminal point (database write, external API call, file output, response return).

**Parallel exploration strategy**: When entering a new layer, launch multiple searches in parallel:
- Grep for the function/class/route name being called
- Glob for files matching the module/package name
- Read configuration files that might define routing or wiring

### Phase 3: Map Supporting Systems

After the main call chain is clear, identify supporting concerns:
- **Configuration**: Where are settings, feature flags, environment variables loaded?
- **Dependency injection / wiring**: How are components connected?
- **External resources**: What templates, prompt files, schema definitions, or config files are loaded at runtime?

Only trace these if they are relevant to understanding the flow.

### Phase 4: Synthesize

Assemble findings into a coherent narrative. The output structure should follow the natural flow of the code, not the order you discovered it.

## Output Document Structure

Adapt this template to the actual codebase — don't force layers that don't exist, add layers the template doesn't anticipate.

    # [Feature/Process Name]: Complete Call Chain Analysis

    ## Overview
    - Brief summary of what the feature does
    - List of main paths (if there are multiple)
    - Key technologies/frameworks involved

    ## Path N: [Path Name]

    ### Layer 1: [Layer Name]
    - Entry point: file:line
    - Key logic: what happens here
    - Handoff: what it calls next and how

    ### Layer 2: [Layer Name]
    ...repeat...

    ### Layer N: [Terminal Layer]
    - Final action: what happens at the end

    ## Supporting Systems
    - Configuration loading
    - Dependency wiring
    - External resources

    ## Data Flow Summary
    Input -> Layer1 -> Layer2 -> ... -> Output

    ## Key Findings
    - Important architectural decisions observed
    - Non-obvious connections or indirections
    - Potential gotchas or complexity hotspots

## Exploration Budget

- Target: 5-12 tool calls for a typical 3-4 layer trace
- Parallel-first: Always batch independent searches in a single turn
- Early stop: If 3+ searches converge on the same area, read the files instead of searching more
- Depth control: For well-known frameworks, summarize the framework role briefly rather than tracing into internals

## Export

When the user requests export:

1. Write the analysis to the user-specified path (default: ./codeflow-analysis.md)
2. Use the Output Document Structure above
3. Include actual file paths with line numbers
4. Keep code snippets short (key signatures and calls only)

## Anti-Patterns to Avoid

- Do not guess architecture — trace actual code
- Do not trace framework internals — stop at the boundary of third-party code
- Do not dump entire files — extract only the relevant lines
- Do not over-search — if you have identified the file, read it directly
- Do not mix discovery order with presentation order — follow the call flow
