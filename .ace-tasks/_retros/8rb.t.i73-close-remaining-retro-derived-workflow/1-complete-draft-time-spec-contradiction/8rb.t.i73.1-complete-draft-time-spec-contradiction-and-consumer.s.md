---
id: 8rb.t.i73.1
status: draft
priority: high
created_at: "2026-04-12 12:08:03"
estimate: TBD
dependencies: []
tags: [retros, spec-quality, ace-task, workflow]
parent: 8rb.t.i73
bundle:
  presets: [project]
  files:
    - ace-task/handbook/workflow-instructions/task/draft.wf.md
    - ace-task/handbook/workflow-instructions/task/review.wf.md
    - ace-task/handbook/templates/task/draft.template.md
  commands:
    - ace-task show 8rb.t.i73.1 --content
needs_review: false
---

# Complete draft-time spec contradiction and consumer guardrails

## Objective

Move key spec-quality protections from late review into task drafting itself so contradictions, missing consumer audits, and missing removal/chain contracts are caught before a draft reaches review or planning.

## Behavioral Specification

### User Experience

- A drafter producing a task spec gets early structure that prompts for removals, downstream consumers, and cross-surface contract changes instead of relying on reviewers to catch omissions later.
- Reviewers spend less effort asking for the same structural fixes because the draft artifact already carries those fields.

### Expected Behavior

1. This task starts from current partial coverage already present:
   - task review already checks for contradictory directives
   - task review already asks for consumer packages when interfaces change
2. The remaining gap is draft-time structure and guidance:
   - the draft template does not yet encode explicit “what gets removed” behavior
   - the draft flow does not yet require artifact-chain contracts where pipelines/handoffs are public behavior
   - the draft flow does not yet make consumer audits first-class authoring content
3. The intended outcome is stronger draft-time task specs, not a broader review-system rewrite.
4. Existing review checks remain in place; this task complements them by moving the same quality bar earlier.

### Interface Contract

- **Workflow surfaces affected**
  ```bash
  ace-bundle wfi://task/draft
  ace-bundle wfi://task/review
  ```
- **Artifact surfaces affected**
  - task draft template sections
  - draft usage expectations when CLI/API/workflow/config surfaces change
- **Behavioral contract**
  - no new end-user task command is required
  - the drafting contract becomes more explicit and decision-complete

### Success Criteria

- [ ] The spec distinguishes current review-stage coverage from missing draft-stage coverage.
- [ ] The spec requires explicit handling for removals, consumer audits, and artifact-chain contracts where relevant.
- [ ] The spec preserves existing review-stage contradiction checks rather than replacing them.
- [ ] Draft usage documentation requirements remain aligned with interface-changing tasks.

## Validation Questions

- “What Gets Removed” should be required when replacement/removal intent exists, not forced into every purely additive task.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: standalone task
- **Slice outcome**: stronger draft-time spec guardrails for contradiction, consumer, and contract completeness
- **Advisory size**: medium
- **Context dependencies**: `task/draft`, `task/review`, task draft template, usage-doc expectations

## Verification Plan

### Unit / Component Validation

- Confirm the spec identifies which guardrails already exist at review time and which are missing at draft time.

### Integration / E2E Validation

- Confirm a workflow-changing or interface-changing task can be drafted with explicit consumer and contract details before review.

### Failure / Invalid-Path Validation

- Specify a contradictory “replace vs preserve” example and a pipeline/output-format change example that the improved draft contract must catch before promotion.

### Verification Commands

- `ace-task show 8rb.t.i73.1 --content`

## Current Coverage Already Present

- `task/review` already checks for contradictory directives.
- `task/review` already asks for consumer packages when interfaces change.

## Remaining Gap

- The draft template and `task/draft` workflow still lack first-class sections or requirements for removals, artifact-chain contracts, and consumer-audit content at authoring time.

## Out of Scope / Already Addressed

- Rewriting the full review workflow
- Treating reviewer verification of contradictions as an open gap by itself
- Adding implementation details to draft specs

## Scope of Work

- strengthen task drafting structure
- move critical spec guardrails earlier
- preserve current review-stage protections

## Deliverables

### Behavioral Specifications

- upgraded draft-time task authoring contract for contradiction, consumer, and chain completeness

### Validation Artifacts

- usage scenarios for interface-changing drafts

## References

- `ace-task/handbook/workflow-instructions/task/draft.wf.md`
- `ace-task/handbook/workflow-instructions/task/review.wf.md`
- `ace-task/handbook/templates/task/draft.template.md`
