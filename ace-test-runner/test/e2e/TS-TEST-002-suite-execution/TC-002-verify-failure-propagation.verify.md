# Goal 2 — Verify Failure Propagation Verification

## Expectations

1. `results/tc/02/` contains failure-injection and run captures.
2. Execution exits non-zero.
3. Output indicates failure was detected/reported.

## Verdict

- **PASS**: Failure is surfaced with non-zero propagation.
- **FAIL**: Failure not reflected in exit code or output.
