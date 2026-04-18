# Goal 4 - Compact refusal contract for rule-heavy input

## Goal

Verify compact mode refusal semantics for a rule-heavy source created from behavior-driven constraints (no
verbatim fixture dependency), with explicit guidance to retry exact mode.

## Workspace

Save artifacts to `results/tc/04/`.

Actions:
1. Create `results/tc/04/rules.md` with this rule-heavy policy content:

```markdown
# Architecture Decisions

## Workflow Self Containment

All AI workflows must be completely self-contained with embedded templates and context.
Workflows cannot depend on other workflows or external files except standard context documents.
When executing workflows, never load external guides or templates.

## XML Template Embedding

Use XML format `<documents>` and `<template>` tags for embedded templates.
Preserve XML template blocks exactly.
Never use four-tick markdown blocks for templates.

## Consistent Path Standards

All document paths must be relative to project root, never absolute.
Never use paths starting with `./` or `../`.
Always validate path references before command execution.

## Operational Constraints

Commands that fail must include exact command, stderr evidence, and next action.
Agents must not bypass required verification steps.
Agents must stop on ambiguous product decisions and create HITL requests.

- Only approved paths may be modified.
- Every failure requires explicit evidence.
- Verification commands are mandatory before completion.
```

2. Run `ace-compressor results/tc/04/rules.md --mode compact --format stdio`.
3. Capture stdout/stderr/exit to:
   - `results/tc/04/compact.stdout`
   - `results/tc/04/compact.stderr`
   - `results/tc/04/compact.exit`

## Constraints

- Do not treat non-zero exit as runner failure; capture evidence and continue.
- Keep all writes under `results/tc/04/`.
