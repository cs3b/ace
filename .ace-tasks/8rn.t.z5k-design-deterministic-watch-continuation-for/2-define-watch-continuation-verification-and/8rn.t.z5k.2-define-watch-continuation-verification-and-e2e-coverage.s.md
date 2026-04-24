---
id: 8rn.t.z5k.2
status: draft
priority: medium
created_at: "2026-04-24 23:26:18"
estimate: TBD
dependencies: []
tags: [ace-assign, e2e, test]
parent: 8rn.t.z5k
bundle:
  presets: [project]
  files: [.ace-tasks/8rn.t.z5k-design-deterministic-watch-continuation-for/8rn.t.z5k-design-deterministic-watch-continuation-for-forked-ace.s.md, ace-assign/test/fast/commands/fork_run_command_test.rb, ace-assign/test/fast/molecules/fork_session_launcher_test.rb, ace-assign/test/fast/organisms/assign_drive_contract_test.rb, ace-assign/test/e2e/TS-ASSIGN-003-operations/scenario.yml, ace-assign/test/e2e/TS-ASSIGN-003-operations/runner.yml.md, ace-assign/test/e2e/TS-ASSIGN-003-operations/verifier.yml.md, ace-assign/test/e2e/TS-ASSIGN-003-operations/TC-001-multi-assignment.runner.md, ace-assign/test/e2e/TS-ASSIGN-003-operations/TC-002-fork-run-delegation.runner.md, ux/usage.md]
  commands: [ace-task show 8rn.t.z5k.2 --content, ace-task show 8rn.t.z5k --content]
---

# Define watch continuation verification and e2e coverage

## Objective

Define the exact missing verification surface needed to make watcher-based continuation safe to implement and review on top of current `main`.

## Behavioral Specification

### User Experience

- Implementers and reviewers get one decision-complete test map for the new watcher surface instead of inferring coverage ad hoc.
- The retained `TS-ASSIGN-003` suite grows in place so watcher coverage stays next to the existing operator flows that it extends.
- The new artifacts explicitly describe expected evidence files, acceptable outcomes, and failure-path assertions.

### Expected Behavior

1. Fast tests cover the watcher command directly, not only indirect workflow prose.
2. Existing callback and drive-contract tests stay in place and are extended only where watcher behavior changes the public contract.
3. `TS-ASSIGN-003-operations` is extended rather than replaced.
4. New E2E goals validate both:
   - sequential continuation across multiple fork children
   - interruption recovery from assignment state after the original parent/session disappears
5. Verifier and runner inputs expand to include the new test cases and their expected evidence.
6. Coverage must include at least one invalid/failure path in addition to happy-path continuation.

### Interface Contract

- **Fast test additions**
  - `ace-assign/test/fast/commands/watch_command_test.rb`
  - scenarios:
    - sequential fork children continue until inline work remains
    - scoped subtree already complete exits cleanly
    - watcher waits while a tracked child process is still alive
    - watcher recovers when tracked process/session is gone
    - invalid root is rejected
    - failed subtree fails clearly
    - `Errno::EPERM` is treated as live process existence
- **Existing test updates**
  - update drive-workflow contract tests only where watcher behavior becomes part of the public continuation contract
  - preserve current callback-path assertions
- **E2E suite additions under `TS-ASSIGN-003-operations`**
  - `TC-003-watch-sequential-continuation.runner.md`
  - `TC-003-watch-sequential-continuation.verify.md`
  - `TC-004-watch-recovers-after-interruption.runner.md`
  - `TC-004-watch-recovers-after-interruption.verify.md`
  - fixture directories for `watch/` and `watch-recovery/`
- **Expected E2E evidence**
  ```text
  results/tc/03/watch.stdout
  results/tc/03/watch.stderr
  results/tc/03/watch.exit
  results/tc/03/status-before.stdout
  results/tc/03/status-after.stdout
  results/tc/04/watch-recover.stdout
  results/tc/04/watch-recover.stderr
  results/tc/04/watch-recover.exit
  results/tc/04/status-after.stdout
  ```
- **Illustrative verifier expectations**
  - Goal 3 passes when evidence shows multiple fork roots completed in order and watcher stopped at inline/manual tail
  - Goal 4 passes when evidence shows watcher resumed from assignment state without duplicating scope or widening from subtree to parent unexpectedly

### Success Criteria

- [ ] The task names the exact fast-test file to add and the required behavioral cases.
- [ ] The task extends `TS-ASSIGN-003` in place with concrete new TC files and fixture areas.
- [ ] The task defines expected raw evidence artifacts under `results/tc/03/` and `results/tc/04/`.
- [ ] The task includes both happy-path and failure-path coverage requirements.
- [ ] The task leaves no ambiguity about what the verifier must consider PASS for sequential continuation and interruption recovery.

## Vertical Slice Decomposition (Task/Subtask Model)

- **Slice type**: subtask
- **Slice outcome**: implementation-ready verification contract for watcher behavior
- **Advisory size**: medium
- **Context dependencies**: existing callback tests, existing drive contract tests, current `TS-ASSIGN-003`

## Verification Plan

### Unit / Component Validation

- Confirm the subtask covers direct watcher command behavior rather than only indirect workflow expectations.
- Confirm `EPERM`, invalid-root, and failure-path behaviors are explicitly covered.

### Integration / E2E Validation

- Confirm `TC-003` and `TC-004` are specified with enough detail for runner, verifier, and fixture implementation.
- Confirm expected artifact names and evidence sources are concrete and aligned with current E2E conventions.

### Failure / Invalid Path Validation

- Confirm verifier language does not rely on fabricated summaries instead of raw captures.
- Confirm the task does not replace or erase current `TC-001` and `TC-002` flows.
- Confirm recovery coverage includes “resume from state” rather than only “callback arrived.”

### Verification Commands

- `ace-task show 8rn.t.z5k.2 --content`
- `ace-task show 8rn.t.z5k --content`

## Scope of Work

- define direct watcher fast tests
- define exact E2E additions to `TS-ASSIGN-003`
- define expected evidence and PASS conditions
- define regression boundaries around callback compatibility and scoped recovery

## Deliverables

### Behavioral Specifications

- fast-test matrix for watcher behavior
- E2E scenario and evidence contract for watcher continuation

### Validation Artifacts

- explicit `TC-003` and `TC-004` test-artifact plan in the task body and `ux/usage.md`

## Out of Scope

- implementing the tests in this drafting pass
- creating a separate watcher-only E2E suite
- changing unrelated existing assignment E2E flows

## References

- parent task `8rn.t.z5k`
- `ace-assign/test/e2e/TS-ASSIGN-003-operations/scenario.yml`
- `ace-assign/test/e2e/TS-ASSIGN-003-operations/runner.yml.md`
- `ace-assign/test/e2e/TS-ASSIGN-003-operations/verifier.yml.md`
