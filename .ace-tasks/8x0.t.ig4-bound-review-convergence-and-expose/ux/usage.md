# Bound review convergence and expose escalation -- Draft Usage

## API Surface

Agent workflow/artifact contracts and configuration; R1 additionally introduces the campaign CLI. These scenarios specify proposed behavior, not available commands.

## Scenario 1: Medium is still required

**Action:** Run three no-High rounds but leave one required Medium unresolved.

**Expected:** search_converged is true; accepted is false and the Medium remains visible.

## Scenario 2: Budget exhausted

**Action:** Complete five delivery rounds without all acceptance conditions.

**Expected:** needs_escalation with evidence and reason; no sixth review or automatic model upgrade.

## Scenario 3: Infrastructure failure

**Action:** A provider times out, then fails authentication on retry.

**Expected:** Attempts are recorded; authentication stops immediately; completed-round and clean counters do not increase.

## Delivery

Complete public usage documentation during implementation; preserve these positive and negative acceptance scenarios.

## Scenario 4: Required repair in the last round

**Action:** Round five finds a required Medium; the worker repairs it and changes HEAD.

**Expected:** The old verdict cannot certify the repair. Status is needs_escalation; a sixth review is not launched or counted outside the cap. An explicitly authorized finite follow-up phase retains lifetime counters and the failed phase.

## Scenario 5: Historical High and later clean rounds

**Action:** Record High -> clean -> clean, keeping the original High unresolved.

**Expected:** The numeric search threshold is met but accepted remains false. Fixing the High requires verification/current evidence; absence from later reports does not close it.
