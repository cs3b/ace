---
id: 8rb.t.i73.2
status: draft
priority: high
created_at: "2026-04-12 12:08:03"
estimate: TBD
dependencies: []
tags: [retros, testing, performance, workflow, ci]
parent: 8rb.t.i73
bundle:
  presets: [project]
  files:
    - ace-test/handbook/templates/test-review-checklist.template.md
    - ace-test/handbook/workflow-instructions/test/verify-suite.wf.md
    - .github/workflows/test.yml
    - docs/tools.md
    - CLAUDE.md
  commands:
    - ace-task show 8rb.t.i73.2 --content
    - ace-test --profile 10
needs_review: false
---

# Enforce no-real-I-O test discipline and compliant profiling

## Objective

Turn the repo’s existing test-performance and no-real-I/O guidance into stronger enforcement, while bringing test workflows back into compliance with the repository’s direct `ace-*` command-integrity contract.

## Behavioral Specification

### User Experience

- A maintainer writing or reviewing tests gets stronger signals when unit tests perform real I/O or drift beyond intended profiling budgets.
- Workflow examples and verification guidance no longer tell operators to pipe or redirect `ace-test` in ways that contradict the current repo rules.
- CI behavior reflects at least part of the performance and no-real-I/O policy rather than leaving it purely advisory.

### Expected Behavior

1. This task starts from current partial coverage already present:
   - test review guidance already says unit tests should have no real I/O
   - test checklists already expect profiling and budget awareness
2. The remaining gap is enforcement and consistency:
   - CI does not currently enforce profiling or performance-budget behavior
   - some workflow examples still show `ace-test` piping/redirection that conflicts with current command-integrity policy
3. The task should not redefine the underlying testing philosophy; it should make current policy harder to bypass and easier to follow consistently.
4. The resulting contract must clearly distinguish documentation-only guidance from enforceable behavior.

### Interface Contract

- **Existing surfaces**
  ```bash
  ace-test --profile 10
  ace-bundle wfi://test/verify-suite
  ```
- **Behavioral contract**
  - No new public test command is required.
  - Workflow examples for `ace-test` must remain compatible with the repo-wide direct-command rule.
  - CI and/or verification flows should expose clearer enforcement behavior for unit-test performance and no-real-I/O discipline.

### Success Criteria

- [ ] The spec names the current guidance already in place for no-real-I/O and profiling.
- [ ] The spec names the remaining CI/enforcement gap.
- [ ] The spec names the current command-integrity mismatch in test workflow examples.
- [ ] The verification plan includes one invalid-path or policy-violation scenario.

## Validation Questions

- Enforcement can be staged, but the spec must define a concrete first enforcement step instead of only restating guidance.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: standalone task
- **Slice outcome**: test-discipline rules become more enforceable and workflow examples become repo-compliant
- **Advisory size**: medium
- **Context dependencies**: `ace-test` handbook, CI workflow, repo command-integrity rules

## Verification Plan

### Unit / Component Validation

- Confirm the spec captures both the no-real-I/O rule and the direct-command-integrity rule for `ace-test`.

### Integration / E2E Validation

- Confirm the spec describes how CI or verification workflows expose profiling/performance policy more concretely than today.

### Failure / Invalid-Path Validation

- Include a case where a unit test performs subprocess/filesystem/network/sleep behavior or a workflow example pipes `ace-test`, and define the expected policy response.

### Verification Commands

- `ace-task show 8rb.t.i73.2 --content`
- `ace-test --profile 10`

## Current Coverage Already Present

- The test review checklist already says unit tests should have no real I/O.
- Test docs already encourage profiling and budget awareness.

## Remaining Gap

- CI lacks clear enforcement of these expectations.
- `test/verify-suite` examples still show `ace-test` shell post-processing that conflicts with the current command-integrity rule.

## Out of Scope / Already Addressed

- Re-arguing the testing philosophy itself
- Treating “profile your tests” as a brand-new idea
- Large E2E redesign unrelated to unit-test discipline

## Scope of Work

- define enforceable first-step policy for no-real-I/O and profiling
- align test workflows with repo command-integrity rules
- connect guidance to CI or verification behavior

## Deliverables

### Behavioral Specifications

- stronger test-discipline enforcement contract

### Validation Artifacts

- workflow/CI usage scenarios showing compliant profiling behavior

## References

- `ace-test/handbook/templates/test-review-checklist.template.md`
- `ace-test/handbook/workflow-instructions/test/verify-suite.wf.md`
- `.github/workflows/test.yml`
- `docs/tools.md`
- `CLAUDE.md`
