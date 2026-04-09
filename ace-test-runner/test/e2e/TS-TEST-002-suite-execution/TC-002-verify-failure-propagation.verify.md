# Goal 2 — Verify Failure Propagation Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains failure-injection and run captures.
2. `results/tc/02/run2.exit` exists and records a non-zero exit code.
3. `results/tc/02/run2.stdout` or `results/tc/02/run2.stderr` indicates failure was detected/reported.
4. Failure evidence and exit status in `run2.*` are internally consistent.

## Verdict

- **PASS**: Failure is surfaced with non-zero propagation.
- **FAIL**: Failure not reflected in exit code or output.
