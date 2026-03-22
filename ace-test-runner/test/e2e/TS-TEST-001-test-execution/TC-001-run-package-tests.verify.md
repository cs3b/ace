# Goal 1 — Run Package Tests Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Artifacts exist in `results/tc/01/`.
2. Exit code is `0`.
3. Captured output includes executed test summary details.

## Verdict

- **PASS**: Package test run succeeds with real execution evidence.
- **FAIL**: Missing artifacts or non-zero execution result.
