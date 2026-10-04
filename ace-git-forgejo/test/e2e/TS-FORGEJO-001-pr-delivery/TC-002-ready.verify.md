# TC-002 Verify — Ready goals

### Goal 1 - Ready marks the exact draft ready

- **Verdict**: PASS only if `ready.exit` is 0 and `ready.json` shows
  `operation: "ready"`, `draft: false`, a title without the `WIP:`
  prefix, and the unchanged head SHA.

### Goal 2 - Ready replay is idempotent

- **Verdict**: PASS only if `ready-replay.exit` is 0 with
  `operation: "ready"` and `draft: false` (no error, no mutation).

### Goal 3 - A stale head cannot yield a receipt

- **Verdict**: PASS only if `ready-stale.exit` is nonzero with category
  `expected_head_conflict`, and `show-after-stale.json` still reports
  `draft: false` at the original head (no forged receipt, no state
  damage).
