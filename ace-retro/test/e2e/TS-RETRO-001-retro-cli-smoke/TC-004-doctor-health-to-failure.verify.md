# Goal 4 - Doctor Health to Failure Transition Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit corrupted file evidence exists.
2. Confirm command artifacts under `results/tc/04/`.
3. Use debug captures as fallback.

1. `doctor-healthy.exit` is `0`.
2. `doctor-broken.exit` is non-zero (`1` expected).
3. `doctor-broken.stdout` or `.stderr` shows issue detection/failure messaging.
4. `corrupted-file.path` and `corrupted-file.md` show a real in-sandbox corruption step occurred.

## Verdict

- **PASS**: Doctor reports healthy before corruption and failure after corruption with clear evidence.
- **FAIL**: Missing transition evidence, unchanged exit status, or missing corruption artifact.
