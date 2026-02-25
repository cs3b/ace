# Goal 1 — Create Task Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains command captures (`.stdout`, `.stderr`, `.exit`).
2. Exit code is `0`.
3. Artifacts include the created task reference.
4. Evidence shows created task metadata includes draft status.

## Verdict

- **PASS**: Task creation succeeded with reusable task reference evidence.
- **FAIL**: Missing captures, non-zero exit, or missing task creation proof.
