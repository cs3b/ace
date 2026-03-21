# Goal 1 — Run Full Suite Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains suite command captures.
2. `results/tc/01/command.txt` confirms an `ace-test-suite` invocation was executed.
3. Output captures show grouped or multi-package execution evidence.
4. `results/tc/01/.exit` exists and is interpreted consistently with captured output.

## Verdict

- **PASS**: Suite execution shows aggregated runner behavior.
- **FAIL**: Missing aggregate evidence or invalid captures.
