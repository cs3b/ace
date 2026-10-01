# Compare three pipelines with complete cost evidence -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: Nine-cell preflight

**Action:** Prepare three new task contracts and three frozen arms; run benchmark preflight.

**Expected:** Nine planned cells, actual bindings/resources and any blocked prerequisites; no paid execution during preflight.

## Scenario 2: Incomplete cost data

**Action:** One provider omits usage and one arm escalates to Astra.

**Expected:** Unknown usage stays unknown; all known escalation work is included; no allowance-to-money conversion.

## Scenario 3: Negative experimental result

**Action:** Swarm costs more or misses acceptance on a task.

**Expected:** Report no advantage or insufficient evidence; retain failed cells and do not change default routing.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.
