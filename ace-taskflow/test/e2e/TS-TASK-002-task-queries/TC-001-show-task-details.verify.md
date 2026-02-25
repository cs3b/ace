# Goal 1 — Show Task Details Verification

## Expectations

1. Detail output artifacts exist in `results/tc/01/`.
2. `ace-task show` exit code is `0`.
3. Output includes metadata fields (id/status/priority) and task content.

## Verdict

- **PASS**: Show command returns complete task details.
- **FAIL**: Missing metadata/content evidence.
