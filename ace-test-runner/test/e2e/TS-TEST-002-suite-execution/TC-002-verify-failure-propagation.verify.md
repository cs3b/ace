# Goal 2 — Verify Failure Propagation Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. `results/tc/02/` contains failure-injection and run captures.
2. Prefer `results/tc/02/.exit` and verify non-zero exit when present.
3. If `.exit` is missing, captured stdout/stderr must clearly show failure was detected/reported.
4. Failure evidence in output and available exit-status artifacts must be internally consistent.

## Verdict

- **PASS**: Failure is surfaced with non-zero propagation, or with explicit failure evidence in captured output when `.exit` is absent.
- **FAIL**: Failure is not reflected in available exit/output evidence.
