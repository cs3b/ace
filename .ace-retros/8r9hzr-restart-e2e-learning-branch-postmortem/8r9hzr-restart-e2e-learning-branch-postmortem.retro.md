---
id: 8r9hzr
title: restart-e2e-learning-branch-postmortem
type: standard
tags: [e2e, testing, migration, restart, branch]
created_at: "2026-04-10 11:59:44"
status: active
---

# restart-e2e-learning-branch-postmortem

Date: 2026-04-10
Context: Learning-branch postmortem for fix/e2e, focused on why the attempted deterministic and agent split lost coverage, over-specialized the runner stack, and still failed to produce a clean long-term architecture.
Author: Codex
Type: Standard

## What Went Well

- The branch surfaced the real architectural boundary: deterministic sandboxed CLI coverage belongs in ordinary Minitest, not in a custom ace-test-e2e phase.
- We recovered hard evidence about the current failure modes instead of arguing from preference. The branch history now proves the deterministic migration removed 133 TC runner cases across 25 packages.
- The branch also validated two durable ideas worth keeping in the restart:
  - shared sandbox preparation for both deterministic and scenario work
  - behavior-first agent scenarios anchored in real output and real state rather than synthetic support artifacts
- We found and documented harness-level defects that would have stayed hidden without pushing the branch far enough:
  - ace-test-e2e integration reporting could show 0/0 case(s) after real execution
  - suite visibility could make the branch look healthy while most deterministic coverage had been physically deleted
  - back-to-back ace-retro create and ace-task create calls can collide on the same generated ID within one second

## What Could Be Improved

- We deleted deterministic scenario suites before parity was actually restored in Minitest. That inverted the safe order of operations.
- We overfit the design around ace-test-e2e as a two-phase engine instead of first asking whether ace-test and ace-test-suite already had the right target and group model.
- We treated one thin smoke file per package as sufficient replacement for TC-level coverage. It was not.
- We released package changes while migration parity was still incomplete and branch truth was still moving.
- We let reporting correctness lag behind execution changes, which made it too easy to misread the branch state.

## Key Learnings

- Deterministic CLI and package-copy tests should live in test/e2e and run through ace-test like any other Minitest target.
- ace-test-e2e should remain scenario-only. Its value is agent execution, context injection, and state-based verification, not owning a second deterministic test runner.
- Shared sandbox setup is still the right isolation model, but it should be factored into a helper used by both ace-test-driven deterministic tests and ace-test-e2e scenarios.
- Agent scenarios should be fewer and more realistic:
  - provide docs and --help
  - state the job to accomplish
  - save only the final response as scenario-owned text output
  - verify from final response plus filesystem and git state
- Coverage migration must be fail-closed: do not delete deterministic scenario TCs until matching test/e2e methods exist and pass.
- Tooling that generates IDs from second-level timestamps is unsafe for batched or automated drafting work.

## Action Items

### Stop Doing

- Deleting deterministic scenario suites before parity exists in Minitest.
- Treating ace-test-e2e as the owner of deterministic test execution.
- Accepting package-level smoke replacements for TC-level deterministic coverage.
- Cutting releases while migration parity and reporting correctness are still unstable.

### Continue Doing

- Reusing one sandbox preparation model across deterministic and agent-driven testing.
- Preferring behavior-first verification over artifact choreography.
- Using targeted package-level migration matrices instead of generic restore-coverage plans.

### Start Doing

- Pilot the restart on ace-b36ts end to end before migrating the rest of the packages.
- Put deterministic sandboxed tests under test/e2e and expose them through ace-test <pkg> e2e and ace-test-suite --target e2e.
- Use one package task per package with an explicit source-TC to destination-test mapping.
- Patch or redesign ace-task create and ace-retro create ID generation so sequential automation cannot collide inside one second.

## Additional Context

- New pilot task: 8r9.t.hzr
- New migration orchestrator: 8r9.t.i05
- New synthesis retro: 8r9i04
