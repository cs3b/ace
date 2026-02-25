# Goal 2 — Filter by Status Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Filter command captures exist in `results/tc/02/`.
2. Exit code is `0`.
3. Output includes draft tasks and excludes done tasks created for control.

## Verdict

- **PASS**: Status filter isolates draft tasks correctly.
- **FAIL**: Output includes non-draft tasks or lacks draft evidence.
