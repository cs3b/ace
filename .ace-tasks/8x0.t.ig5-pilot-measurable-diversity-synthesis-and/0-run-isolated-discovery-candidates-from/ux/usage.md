# Run isolated discovery candidates from one baseline -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: Three isolated candidates

**Action:** Start discover-only with one contract/base and three pre-resolved roles.

**Expected:** Three worktrees/attempts produce separate manifests; no delivery side effects.

## Scenario 2: One worker fails

**Action:** Terminate candidate B and resume the assignment.

**Expected:** B remains failed/stopped with evidence; A/C are not reset; no duplicate B writer.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.
