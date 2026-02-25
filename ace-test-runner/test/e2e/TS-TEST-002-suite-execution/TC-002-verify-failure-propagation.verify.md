# Goal 2 — Verify Failure Propagation Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains failure-injection and run captures.
2. Execution exits non-zero.
3. Output indicates failure was detected/reported.

## Verdict

- **PASS**: Failure is surfaced with non-zero propagation.
- **FAIL**: Failure not reflected in exit code or output.
