# Goal 2 — Verify Failure Propagation Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains failure-injection and run captures, including `injected-test.path`.
2. `results/tc/02/precheck.exit` exists and is non-zero.
3. `results/tc/02/precheck.stdout` or `results/tc/02/precheck.stderr` explicitly references the injected file, its test class, or its sentinel failure message.
4. `results/tc/02/.exit` exists and is non-zero.
5. Captured suite stdout or stderr clearly shows the failing package, and that aggregate failure is consistent with the direct precheck failure.

## Verdict

- **PASS**: Failure is surfaced with non-zero propagation, the direct `ace-test` precheck proves the injected failure path ran, and the suite aggregates that failure coherently.
- **FAIL**: Failure is not reflected in exit/output evidence, or the capture set does not prove the injected failure path actually ran.
