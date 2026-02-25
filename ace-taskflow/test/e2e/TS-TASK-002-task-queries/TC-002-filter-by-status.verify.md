# Goal 2 — Filter by Status Verification

## Expectations

1. Filter command captures exist in `results/tc/02/`.
2. Exit code is `0`.
3. Output includes draft tasks and excludes done tasks created for control.

## Verdict

- **PASS**: Status filter isolates draft tasks correctly.
- **FAIL**: Output includes non-draft tasks or lacks draft evidence.
