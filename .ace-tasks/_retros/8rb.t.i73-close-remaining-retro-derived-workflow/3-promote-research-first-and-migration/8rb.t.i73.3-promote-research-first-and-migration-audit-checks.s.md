---
id: 8rb.t.i73.3
status: draft
priority: medium
created_at: "2026-04-12 12:08:03"
estimate: TBD
dependencies: []
tags: [retros, process, migration, workflow]
parent: 8rb.t.i73
bundle:
  presets: [project]
  files:
    - ace-task/handbook/workflow-instructions/task/plan.wf.md
    - ace-task/handbook/workflow-instructions/task/work.wf.md
    - ace-task/handbook/workflow-instructions/task/review-work.wf.md
    - ace-handbook/handbook/guides/ai-agent-integration.g.md
  commands:
    - ace-task show 8rb.t.i73.3 --content
needs_review: false
---

# Promote research-first and migration-audit checks into execution

## Objective

Promote research-first and migration-audit expectations from planning guidance into execution-facing workflows so implementation work is less likely to skip pattern research, flag verification, or stale-reference audits.

## Behavioral Specification

### User Experience

- A maintainer executing a task gets a clearer expectation that research and migration audits are not optional planning niceties; they are part of correct execution behavior for cross-cutting changes.
- Reviewers evaluating implementation quality can expect explicit evidence that existing patterns were checked and old references were audited.

### Expected Behavior

1. This task starts from current partial coverage already present:
   - planning guidance already calls for cross-package reference audits and consumer tracing
   - handbook guidance already says to research existing patterns
   - review-work already flags unjustified new patterns
2. The remaining gap is execution-stage enforcement:
   - `task/work` still largely says “follow established project patterns” without an explicit preflight/research contract
   - migration-audit behavior is more explicit during planning than during execution
3. The intended result is stronger work-time and review-time expectations, not a new planning system.
4. The task should preserve the current fast path for trivial work while making cross-cutting changes carry clearer preflight and audit responsibilities.

### Interface Contract

- **Workflow surfaces**
  ```bash
  ace-bundle wfi://task/plan
  ace-bundle wfi://task/work
  ace-bundle wfi://task/review-work
  ```
- **Behavioral contract**
  - No new user-facing CLI command is required.
  - Execution-facing workflows become more explicit about required research and migration-audit evidence.

### Success Criteria

- [ ] The spec distinguishes current planning-stage coverage from missing execution-stage coverage.
- [ ] The spec names research-first checks and migration-audit checks that must move into execution behavior.
- [ ] The spec preserves the ability to keep trivial work lightweight.
- [ ] The verification plan includes one stale-reference or skipped-preflight failure scenario.

## Validation Questions

- The task should not force heavyweight discovery for obviously mechanical one-file edits; it should target shared, interface-changing, or migration-style work.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: standalone task
- **Slice outcome**: stronger execution-time workflow contract for research-first and migration-audit behavior
- **Advisory size**: medium
- **Context dependencies**: task planning, task execution, execution review, handbook guidance

## Verification Plan

### Unit / Component Validation

- Confirm the spec clearly separates planning guidance already present from missing execution-stage requirements.

### Integration / E2E Validation

- Confirm a migration or interface-change task would have explicit execution-time expectations to check patterns, verify flags/APIs, and audit stale references.

### Failure / Invalid-Path Validation

- Include a migration scenario where an old pattern or path survives because the implementer skipped the audit, and define the expected review/workflow response.

### Verification Commands

- `ace-task show 8rb.t.i73.3 --content`

## Current Coverage Already Present

- `task/plan` already includes cross-package reference audits and consumer tracing.
- handbook guidance already tells agents to research existing patterns.
- `review-work` already flags unjustified new patterns.

## Remaining Gap

- Execution-facing workflows do not yet make those checks explicit enough during actual work.

## Out of Scope / Already Addressed

- Rebuilding the planning workflow from scratch
- Treating pattern research as absent from the repo entirely
- Forcing heavyweight preflight for every trivial change

## Scope of Work

- bring research/audit expectations into execution behavior
- preserve lightweight flow for trivial work
- clarify review evidence for skipped or completed audits

## Deliverables

### Behavioral Specifications

- execution-stage preflight and migration-audit contract

### Validation Artifacts

- usage scenarios for migration-style execution and review

## References

- `ace-task/handbook/workflow-instructions/task/plan.wf.md`
- `ace-task/handbook/workflow-instructions/task/work.wf.md`
- `ace-task/handbook/workflow-instructions/task/review-work.wf.md`
- `ace-handbook/handbook/guides/ai-agent-integration.g.md`
