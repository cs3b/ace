# Goal 1 — Show Task Details Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Detail output artifacts exist in `results/tc/01/`.
2. `ace-task show` exit code is `0`.
3. Output includes metadata fields (id/status/priority) and task content.

## Verdict

- **PASS**: Show command returns complete task details.
- **FAIL**: Missing metadata/content evidence.
