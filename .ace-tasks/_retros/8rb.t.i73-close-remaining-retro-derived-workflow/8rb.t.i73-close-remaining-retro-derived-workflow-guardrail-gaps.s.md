---
id: 8rb.t.i73
status: draft
priority: medium
created_at: "2026-04-12 12:07:54"
estimate: TBD
dependencies: []
tags: [retros, workflow, quality]
bundle:
  presets: [project]
  files:
    - ace-task/handbook/workflow-instructions/task/draft.wf.md
    - ace-task/handbook/workflow-instructions/task/review.wf.md
    - ace-task/handbook/templates/task/draft.template.md
    - ace-review/handbook/workflow-instructions/review/verify-feedback.wf.md
  commands:
    - ace-task show 8rb.t.i73 --content
    - ace-task show 8rb.t.i73.0 --content
    - ace-task show 8rb.t.i73.1 --content
    - ace-task show 8rb.t.i73.2 --content
    - ace-task show 8rb.t.i73.3 --content
    - ace-task show 8rb.t.i73.4 --content
needs_review: false
---

# Close remaining retro-derived workflow guardrail gaps

## Objective

Turn the remaining value in older retro syntheses into one coordinated draft scope that targets only the gaps still visible in the current codebase and workflows, instead of reopening areas that are already sufficiently addressed.

## Behavioral Specification

### User Experience

- Maintainers reviewing retro follow-up work see a single orchestrator task that clearly separates five remaining gaps by concern.
- Each child task states what is already covered in the repo today, what remains missing, and what is intentionally out of scope because the earlier retro concern has already been handled.
- This parent acts as the coordination contract for retro-derived follow-up work and does not introduce independent runtime behavior.

### Expected Behavior

1. The work is represented as one orchestrator task with five child tasks covering:
   - safe write primitives in domain-managed flows
   - draft-time spec contradiction and consumer guardrails
   - no-real-I/O test discipline and profiling enforcement
   - research-first and migration-audit checks during execution
   - PR base-branch safety across git workflows
2. The parent remains behavior-only and does not own implementation details beyond defining the decomposition, acceptance boundaries, and verification expectations for the children.
3. Each child task must explicitly distinguish:
   - current partial coverage already present in code or workflows
   - remaining gap to close
   - already-addressed portions that should not be reworked
4. The parent is complete only when all five children are implemented, verified, and shown to preserve behavior already working today.
5. Review-finding verification is treated as largely addressed already and is therefore excluded from new child scope except where it interacts with unresolved git workflow safety.

### Interface Contract

- **Task decomposition contract**
  - Orchestrator: `8rb.t.i73`
  - Child tasks:
    - `8rb.t.i73.0` -> safe write primitives in task, idea, and retro flows
    - `8rb.t.i73.1` -> draft-time contradiction and consumer guardrails
    - `8rb.t.i73.2` -> no-real-I/O and profiling enforcement
    - `8rb.t.i73.3` -> research-first and migration-audit checks in execution
    - `8rb.t.i73.4` -> PR base-branch safety across git workflows
- **Parent boundary**
  - No new CLI command, workflow name, or config surface is introduced by the parent alone.
  - Public surfaces, if any, are owned by specific child tasks.

### Success Criteria

- [ ] Five child tasks are drafted and linked under `8rb.t.i73`.
- [ ] Each child includes explicit “already present”, “remaining gap”, and “out of scope/already addressed” sections.
- [ ] Each child includes bundle context and a verification plan with at least one failure-path scenario.
- [ ] The parent makes it clear that review-finding verification is not being reopened as a standalone workstream.
- [ ] The parent provides a stable retro-followup program without duplicating already-solved concerns.

## Validation Questions

- If implementation discovers one child is already fully addressed in code, the expected outcome is to archive or narrow that child rather than broaden the parent scope.
- Cross-child overlap should be minimized; where overlap exists, the child owning the public surface remains authoritative.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: orchestrator with five independent follow-up subtasks
- **Slice outcome**: one coherent retro-derived quality follow-up program focused only on remaining repo gaps
- **Advisory size**: medium
- **Context dependencies**: `ace-task`, `ace-review`, `ace-test`, `ace-git`, `ace-support-markdown`, repository command-integrity rules
- **End-state coherence**
  - `8rb.t.i73.0` addresses production write-safety gaps in domain-managed flows
  - `8rb.t.i73.1` moves key spec guardrails earlier into drafting
  - `8rb.t.i73.2` turns testing guidance into stronger enforcement
  - `8rb.t.i73.3` promotes research/audit checks from planning guidance into execution behavior
  - `8rb.t.i73.4` finishes unresolved base-branch safety in git workflows

## Verification Plan

### Unit / Component Validation

- Confirm each child task clearly describes one remaining gap and does not restate already solved work as open scope.

### Integration / E2E Validation

- Confirm the five-child tree covers the remaining retro-derived gaps found in the repo review without leaving a major uncovered category.

### Failure / Invalid-Path Validation

- If a child task lacks explicit “current coverage vs remaining gap” framing, the orchestrator remains in draft and is not ready for review/promotion.

### Verification Commands

- `ace-task show 8rb.t.i73 --content`
- `ace-task show 8rb.t.i73.0 --content`
- `ace-task show 8rb.t.i73.1 --content`
- `ace-task show 8rb.t.i73.2 --content`
- `ace-task show 8rb.t.i73.3 --content`
- `ace-task show 8rb.t.i73.4 --content`

## Scope of Work

- Define the remaining retro-derived gaps still visible in the repo
- Split them into independently implementable child specs
- Preserve already-addressed improvements by marking them out of scope where appropriate

## Deliverables

### Behavioral Specifications

- One orchestrator spec
- Five child draft specs with clear ownership boundaries

### Validation Artifacts

- Child-level verification plans
- Explicit repo-evidence framing for partial coverage

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Retro follow-up orchestrator | `8rb.t.i73` | -- | KEPT |
| Safe write primitive adoption gap | `8rb.t.i73.0` | -- | KEPT |
| Draft-time spec guardrail gap | `8rb.t.i73.1` | -- | KEPT |
| Test-discipline enforcement gap | `8rb.t.i73.2` | -- | KEPT |
| Execution-stage research/audit gap | `8rb.t.i73.3` | -- | KEPT |
| Git base-branch safety gap | `8rb.t.i73.4` | -- | KEPT |
| Review-finding verification as standalone work | -- | `8rb.t.i73` | REJECTED |

## Out of Scope

- Implementing runtime code, tests, or workflow changes in this drafting phase
- Reopening review-finding verification as a general problem area
- Creating additional retro-derived tasks outside these five gaps unless new evidence appears

## References

- retros: `8q0z2p`, `8q0z3f`, `8q0z3i`, `8q0z3l`, `8q0zc6`, `8q0zf0`, `8q0zhl`
- repo review evidence captured during this session
