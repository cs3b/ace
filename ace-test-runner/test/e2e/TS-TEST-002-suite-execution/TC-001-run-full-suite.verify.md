# Goal 1 — Run Full Suite Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/01/` contains suite command captures.
2. `results/tc/01/command.txt` confirms an `ace-test-suite` invocation was executed.
3. Output captures show suite-level package execution evidence (for example package counts, package rows, or suite summary output).
4. Prefer `results/tc/01/.exit` for exit status. If `.exit` is missing, accept captured stdout/stderr evidence showing the suite command completed and produced aggregate output.

## Verdict

- **PASS**: Suite execution shows aggregated runner behavior.
- **FAIL**: Missing aggregate evidence, or captures that cannot establish command execution outcome.
