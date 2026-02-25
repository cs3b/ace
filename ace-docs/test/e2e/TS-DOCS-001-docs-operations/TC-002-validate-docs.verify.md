# Goal 2 — Validate Docs Verification

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. Validation captures exist in `results/tc/02/`.
2. Exit code and stderr/stdout are captured.
3. Output includes validation result indicators.

## Verdict

- **PASS**: Validation behavior is evidenced clearly.
- **FAIL**: Validation output missing or command failure.
