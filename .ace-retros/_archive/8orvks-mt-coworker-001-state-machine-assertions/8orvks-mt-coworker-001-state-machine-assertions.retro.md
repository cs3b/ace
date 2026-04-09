---
id: 8orvks
title: MT-COWORKER-001 State Machine Assertion Gaps
type: conversation-analysis
tags: []
created_at: '2026-01-28 21:03:05'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8orvks-mt-coworker-001-state-machine-assertions.md"
---

# Reflection: MT-COWORKER-001 State Machine Assertion Gaps

**Date**: 2026-01-28
**Context**: Fixing E2E test MT-COWORKER-001 which tested CLI commands but never verified state machine transitions
**Author**: Development Agent
**Type**: Conversation Analysis

## What Went Well

- The plan accurately traced the full execution path through `WorkflowExecutor` before writing any assertions, catching a subtle ordering bug in TC-010/TC-011
- Exploring the actual source code (status formatter, report handler, add/retry executor methods) before writing grep patterns meant every assertion matched real output strings on the first pass
- The approach of weaving state assertions into existing test cases (rather than creating new TCs) preserved the test's narrative flow while adding the missing verification layer

## What Could Be Improved

- The original test was written and reviewed without anyone questioning whether `report` actually completes the step the test claims it completes. TC-011's descriptions were backwards, and this was only caught by manual execution tracing during plan mode
- The original TC-010/TC-011 split made the test harder to reason about because the queue state carried across the boundary without documentation. Adding the queue state diagram to TC-011's header mitigated this, but the split itself creates coupling

## Key Learnings

- **Exit-code-only testing creates false confidence**: The original test passed for every command, but the state machine could have been completely broken (e.g., `report` completing the wrong step, `add` not auto-activating, `retry` stealing the current step) and no test would have caught it
- **`report` is step-blind**: It always completes `state.current` regardless of what the report file is named. This is by design but means test authors must track which step is current at each point — report filenames provide zero safety
- **`add` vs `retry` have opposite activation semantics**: `add` auto-activates when the queue is stalled (`initial_status = state.current ? :pending : :in_progress`), while `retry` always creates with `status: :pending`. This asymmetry is intentional but non-obvious and was never asserted
- **Queue state diagrams in test documentation**: Adding the explicit queue state entering TC-011 makes the test self-documenting. Without it, the reader has to mentally replay TC-005 through TC-010 to know what's current

## Action Items

### Stop Doing

- Writing E2E tests that only check exit codes and output text without verifying the system's internal state transitions
- Describing test steps by the report filename rather than by the step being completed (e.g., "complete verify step" not "submit verify-report.md")

### Continue Doing

- Tracing execution through the actual source code before writing test assertions
- Using `status` command output as the primary state verification mechanism (it's the user-facing truth)
- Using plan mode to analyze complex state machine behavior before making changes

### Start Doing

- Adding queue state diagrams at test case boundaries where state carries over from a previous test case
- Asserting both the positive case (correct step is current) and negative case (other steps are NOT current) after state-changing operations
- For future E2E tests involving sequential state transitions, consider a `verify_current_step()` helper pattern that checks status output after every command

## Technical Details

### The TC-010/TC-011 Ordering Bug

The original test described TC-011 step 1 as "Complete the retry step (now in_progress after retry)" and step 2 as "Complete the verify step (030)". The actual execution order was reversed:

1. Entering TC-011, `030-verify` is `in_progress` (auto-advanced after completing fix-issue in TC-010)
2. `031-implement` (retry) is `pending` (retry never auto-activates)
3. First `report` completes 030-verify, then 031-implement auto-advances
4. Second `report` completes 031-implement

The test passed because `report` doesn't care about filenames — it just completes whatever `state.current` is. The descriptions were cosmetically wrong but functionally irrelevant to the exit codes being checked.

### Key Status Output Patterns for Assertions

| Scenario | Grep pattern | Present? |
|----------|-------------|----------|
| Step is current | `Current Step:.*<name>` | Yes |
| Queue stalled | `Current Step:` | No (absence) |
| Session complete | `Session completed!` | Yes |
| Report rejected (stalled) | `No step currently in progress` | Yes (exit 1) |

## Additional Context

- File modified: `ace-coworker/test-e2e/scenarios/MT-COWORKER-001-workflow-lifecycle.mt.md`
- Related earlier retro: `8ortz8-ace-coworker-e2e-test-fixes.md` (same day, earlier session focused on error paths)
- The E2E markdown tests are manual execution scripts, not automated — assertions use PASS/FAIL echo patterns