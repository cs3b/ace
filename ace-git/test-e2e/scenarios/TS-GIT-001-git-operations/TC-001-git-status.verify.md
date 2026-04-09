# Goal 1 — Git Status Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains status command captures.
2. Exit code is successful.
3. Output includes repository/branch and working tree status details.

## Verdict

- **PASS**: Status output reflects real repository state.
- **FAIL**: Missing status evidence or failed command.
