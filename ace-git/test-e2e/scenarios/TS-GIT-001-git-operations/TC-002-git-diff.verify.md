# Goal 2 — Git Diff Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Diff artifacts exist in `results/tc/02/`.
2. Exit code is successful.
3. Output includes expected changed file/line evidence.

## Verdict

- **PASS**: Diff command surfaces expected repository change.
- **FAIL**: Change evidence absent or command failed.
