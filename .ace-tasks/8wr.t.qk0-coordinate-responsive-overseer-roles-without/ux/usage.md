# Coordinate responsive overseer roles without the legacy Lab engine: draft usage

Target interfaces, not claims of implementation.

## Restart discovery and concurrent progress

Run `ace-overseer status --project ace --format json` after restarting the overseer without its local assignment cache. Expected: registered assignments and original attempt references are discovered through the authorized Assign inventory. Accepted task IDs and scope references are shown; unavailable detailed status remains unknown. Empty inventory is reported only after a successful complete owner response.

If the journal advances between inventory pages, continue at the selected revision. Each later attempt-status observation carries its own revision; the output does not claim all observations are an atomic snapshot. An unavailable retained revision discards the incomplete enumeration and requires a fresh read. Revoked access, an oversized record or an unreachable authority is an explicit error, never an empty queue or a labd/private-directory fallback. The precise proposed API and failure scenarios are in `../protected-inventory-contract.md`; they require independent readiness review.

## Scenario 1: Start scoped work

```text
ace-overseer work-on --task TASK --project ace --agent builder --runtime herdr
```

Expected: One task-backed assignment starts at the registered scope; conversation remains available.

## Scenario 2: See why progress stopped

```text
ace-overseer status --project ace --format json
```

Expected: Shows exact step/attempt and HITL deadline or evidence blocker; no status inferred from pane prose.

## Scenario 3: Redirect the original attempt

```text
ace-overseer prompt --assignment ASSIGNMENT --file instruction.txt
```

Expected: Resolve the active protected attempt through Assign, then use xz9.2's canonical prompt API. Acknowledgment reports `submitted`, never consumed/read. A replaced terminal/runtime refuses before writing. An uncertain or lost acknowledgment is visible in status and is not automatically retried. No pane-name lookup or raw runtime.send fallback.

## Scenario 4: Stop without losing unresolved work

```text
ace-overseer stop --assignment ASSIGNMENT
ace-overseer status --project ace --format json
ace-overseer prune --assignment ASSIGNMENT --dry-run
```

Expected: Stop delegates to the canonical protected owner. `stopped` requires its whole-scope and settlement proof. Surviving writers, unsettled effects or unavailable evidence report uncertain and preserve the worktree. Prune does not treat a stop request or empty pane as accepted completion; dry-run explains the unmet gate without deleting work.

## Verification ownership

These are source acceptance scenarios with controlled external boundaries. The actual installed runtime, OS-user separation, Captain conversation and complete delivery run are tracked once in lab-config:gad.2 `qkb-delivery / WORKFLOW`; source fixtures do not check that installed row.

## Scenario 5: Retain the original protected launcher

Starting scoped work runs through the configured launcher-role overseer account. The overseer reads one bounded `launch_ready` line, validates the mapping/assignment/attempt against the original accepted Assign binding, and retains ownership of that foreground child. The Captain can continue the conversation while work runs.

Missing or invalid readiness remains a visible launch/recovery problem, never a successful start. A control reconnect uses the same original child and does not resend prior prompts. A replacement process cannot attach as that launcher. Child exit or cancellation preserves uncertain work until the canonical owner confirms the relevant input and execution scopes are settled; neither EOF nor worker-unit termination permits pruning. Controlled source tests exercise these cases; actual service accounts/startup remain in gad.2.
