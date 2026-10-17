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

## Integrated R3 entrypoints (2026-10-08 source checkpoint)

`campaign start --profile delivery` freezes minimum three rounds, two clean rounds,
and maximum five. `--profile discovery` freezes at most two and cannot return an
accepted result. Explicit policy snapshots may strengthen acceptance requirements;
conflicts with the finite initial budget fail before execution.

`campaign status ID --format json` reports profile, current phase, retained phases,
lifetime completed rounds, phase rounds, remaining rounds, clean streak, findings,
execution attempts, evidence validity, outcome and next action. `--profile` on status
or finish verifies the expected frozen profile. Status does not mutate state.

`campaign resume ID --phase additional --reason 'Verified repair needs fresh evidence'
--route review --additional-rounds 2` authorizes a finite additional phase after
escalation or a terminal execution failure. Recurrence requires the explicit
`diagnosis` route before equivalent review. Replaying a phase with conflicting
reason, route or budget fails. An unresolved running/uncertain original execution
cannot be abandoned by authorizing a fresh phase.

`campaign assess ID --input assessment.json` appends a verified finding audit event.
The JSON contains a unique `id`, `kind`, existing `source_id` and nonempty `reason`.
A `repair_attempt` supplies a nonempty content-addressed `artifact` reference.
A `severity_correction` supplies `priority` and `disposition` matching the current
verified feedback source. Corrections retain original observation bytes and
recompute the sequence; repair attempts do not turn a High round into a clean one.

Start, record-round, assess, resume and finish support `--dry-run`. No dry-run
creates a directory, writes a counter or calls a provider. Finish exits successfully
for `accepted` delivery and `discovery_complete` export, and fails for blocked
or escalation outcomes. Restarting start with the same contract/policy/profile
returns the original campaign and budget.
