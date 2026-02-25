# Goal 3 — Status Check Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/03/` contains status command captures.
2. Exit code is `0`.
3. Output includes summary/coverage indicators.

## Verdict

- **PASS**: Status command reports documentation state.
- **FAIL**: Missing summary evidence or command failure.
