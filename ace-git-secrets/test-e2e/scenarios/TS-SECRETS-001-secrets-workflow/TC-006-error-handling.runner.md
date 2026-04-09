# Goal 6 — Error Handling

## Goal

Test graceful failure when the scan file lacks `raw_value` fields. Feed a broken report (with tokens that have no raw_value) to the revoke and rewrite-history commands, and verify they fail with helpful error messages.

## Workspace

Save all output to `results/tc/06/`. Capture:
- `results/tc/06/revoke-error.stdout`, `.stderr`, `.exit` — revoke with broken report
- `results/tc/06/rewrite-error.stdout`, `.stderr`, `.exit` — rewrite-history with broken report

## Constraints

- Place the `broken-report.json` fixture (which has tokens without raw_value) into the expected cache location.
- The broken report fixture is at `fixtures/broken-report.json`.
- All artifacts must come from real tool execution, not fabricated.
