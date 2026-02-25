# Goal 1 — Run Full Suite Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains suite command captures.
2. Output references multiple package runs or grouped execution.
3. Exit code is captured and interpreted correctly.

## Verdict

- **PASS**: Suite execution shows aggregated runner behavior.
- **FAIL**: Missing aggregate evidence or invalid captures.
