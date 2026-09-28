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
