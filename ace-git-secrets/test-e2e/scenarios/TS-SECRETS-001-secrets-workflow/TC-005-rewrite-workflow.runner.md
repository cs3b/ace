# Goal 5 — Rewrite Workflow

## Goal

Test the rewrite-history feature in dry-run mode: verify it shows what would be done without modifying git history. Also verify that scan output includes `raw_value` fields needed for the revocation workflow.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/dry-run.stdout`, `.stderr`, `.exit` — rewrite-history --dry-run output
- `results/tc/05/before-head.txt` and `results/tc/05/after-head.txt` — HEAD hash before and after dry-run
- `results/tc/05/raw-values.stdout` — scan output showing raw_value field presence

## Constraints

- Using what you learned from Goal 1, invoke rewrite-history with --dry-run.
- Verify HEAD is unchanged after dry-run.
- For raw values: run a scan with JSON output and check that tokens include raw_value field.
- All artifacts must come from real tool execution, not fabricated.
