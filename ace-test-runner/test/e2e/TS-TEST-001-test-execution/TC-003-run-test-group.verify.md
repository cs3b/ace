# Goal 3 — Run Test Group Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Artifacts exist in `results/tc/03/`.
2. Exit code is `0`.
3. Output reflects atom-layer/group-focused execution.

## Verdict

- **PASS**: Group filtering executes expected test layer.
- **FAIL**: Group evidence missing or execution failed.
