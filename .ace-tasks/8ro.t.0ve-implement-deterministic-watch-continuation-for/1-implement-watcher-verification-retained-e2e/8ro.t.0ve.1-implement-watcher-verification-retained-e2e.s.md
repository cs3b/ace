---
id: 8ro.t.0ve.1
status: draft
priority: medium
created_at: "2026-04-25 00:34:53"
estimate: TBD
dependencies: [8ro.t.0ve.0, 8ro.t.0ve.2]
tags: [ace-assign, watch, e2e, docs]
parent: 8ro.t.0ve
bundle:
  presets: [project]
  files:
    - .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/2-define-watch-continuation-verification-and/8rn.t.z5k.2-define-watch-continuation-verification-and-e2e-coverage.s.md
    - .ace-tasks/_archive/8r/y/8rn.t.z5k-design-deterministic-watch-continuation-for/ux/usage.md
    - ace-assign/docs/usage.md
    - ace-assign/README.md
    - ace-assign/test/fast/commands/fork_run_command_test.rb
    - ace-assign/test/fast/organisms/assign_drive_contract_test.rb
    - ace-assign/test/e2e/TS-ASSIGN-003-operations/scenario.yml
    - ace-assign/test/e2e/TS-ASSIGN-003-operations/runner.yml.md
    - ace-assign/test/e2e/TS-ASSIGN-003-operations/verifier.yml.md
    - ux/usage.md
  commands:
    - ace-task show 8ro.t.0ve.1 --content
    - ace-test ace-assign test/fast/commands/watch_command_test.rb
    - ace-test ace-assign test/e2e/TS-ASSIGN-003-operations
---

# Implement watcher verification retained E2E and package docs

## Objective

Ship the direct watcher verification surface, additive retained E2E coverage, and package docs for the new public CLI command.

## Behavioral Specification

### User Experience

- Reviewers can validate the feature through direct fast tests and the retained `TS-ASSIGN-003` suite instead of relying on archived design prose.
- Users can discover and understand the new command from shipped package docs and README examples.
- The retained E2E suite proves the watcher behavior with raw captures rather than synthetic summaries.

### Expected Behavior

1. `ace-assign/test/fast/commands/watch_command_test.rb` directly covers the watcher public contract.
2. Existing shared contract tests are updated only where the public continuation contract actually changes.
3. `TS-ASSIGN-003-operations` is extended in place with watcher goals `TC-003` and `TC-004`.
4. The E2E verifier uses raw captures under `results/tc/03/` and `results/tc/04/` as primary evidence for the new watcher goals.
5. Package docs describe command syntax, scope rules, stop/failure behavior, and callback compatibility without implying event emission in v1.

### Interface Contract

- Fast-test additions must cover:
  - sequential continuation across multiple fork roots
  - scoped subtree already complete
  - live-child wait
  - lost-session recovery
  - invalid-root rejection
  - failed-subtree non-zero exit
  - `Errno::EPERM` treated as alive
- E2E additions must include:
  - `TC-003-watch-sequential-continuation.runner.md`
  - `TC-003-watch-sequential-continuation.verify.md`
  - `TC-004-watch-recovers-after-interruption.runner.md`
  - `TC-004-watch-recovers-after-interruption.verify.md`
  - fixtures under `ace-assign/test/e2e/TS-ASSIGN-003-operations/fixtures/watch/`
  - fixtures under `ace-assign/test/e2e/TS-ASSIGN-003-operations/fixtures/watch-recovery/`
- Expected raw evidence includes:
  - `results/tc/03/watch.stdout`
  - `results/tc/03/watch.stderr`
  - `results/tc/03/watch.exit`
  - `results/tc/03/status-before.stdout`
  - `results/tc/03/status-after.stdout`
  - `results/tc/04/watch-recover.stdout`
  - `results/tc/04/watch-recover.stderr`
  - `results/tc/04/watch-recover.exit`
  - `results/tc/04/status-after.stdout`

### Success Criteria

- [ ] Direct watcher fast tests exist and cover both happy-path and failure-path behavior.
- [ ] `TS-ASSIGN-003` is extended in place rather than replaced by a watcher-only suite.
- [ ] The retained verifier contract for watcher goals uses raw captures as primary evidence.
- [ ] Package docs describe the shipped command surface and stop/failure behavior.
- [ ] Task-local usage scenarios match the shipped docs and tests.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: shipped verification coverage and package docs for watcher behavior
- **Advisory size**: medium
- **Context dependencies**: watcher runtime subtasks, current retained E2E suite, current package docs

## Verification Plan

### Unit / Component Validation

- Add direct command tests in `watch_command_test.rb`.
- Update shared contract tests only where watcher behavior changes public continuation expectations.

### Integration / E2E Validation

- Extend `TS-ASSIGN-003-operations` with `TC-003` and `TC-004`.
- Confirm raw evidence proves sequential continuation and interruption recovery.

### Failure / Invalid Path Validation

- Confirm at least one direct fast-test invalid/failure path proves invalid-root or failed-subtree behavior.
- Confirm docs do not promise event emission or `watch --callback`.

### Verification Commands

- `ace-test ace-assign test/fast/commands/watch_command_test.rb`
- `ace-test ace-assign test/fast/organisms/assign_drive_contract_test.rb`
- `ace-test ace-assign test/e2e/TS-ASSIGN-003-operations`

## Scope of Work

- implement direct watcher fast tests
- implement retained-suite E2E additions
- update package docs and README examples
- keep task-local usage guidance aligned with shipped behavior

## Deliverables

### Behavioral Specifications

- direct watcher verification matrix
- additive retained E2E watcher goals
- package docs for the new CLI surface

### Validation Artifacts

- raw watcher E2E evidence files
- updated docs and `ux/usage.md`

## Out of Scope

- watcher runtime command semantics not needed to support verification/docs
- unrelated assignment E2E rewrites
- separate watcher-only documentation surface outside package docs

## References

- archived task `8rn.t.z5k.2`
- `ace-assign/test/e2e/TS-ASSIGN-003-operations/scenario.yml`
- `ace-assign/docs/usage.md`
