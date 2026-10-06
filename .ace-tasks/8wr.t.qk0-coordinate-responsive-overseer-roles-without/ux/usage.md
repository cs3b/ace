# Coordinate responsive overseer roles without the legacy Lab engine: draft usage

Target interfaces, not claims of implementation.

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
