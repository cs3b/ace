# Goal 3 — Hierarchy Errors Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Parent advance blocked** — `advance-parent.exit` contains non-zero value. Output mentions "incomplete children" and lists 010.01 and 010.02.
2. **Invalid --after rejected** — `invalid-after.exit` contains non-zero value. Output mentions "not found" and shows available phase numbers (010, 020).
3. **Both return non-zero** — Both error cases produce non-zero exit codes, confirming proper error handling.

## Verdict

- **PASS**: Both error cases return non-zero exit with descriptive error messages listing affected phases.
- **FAIL**: Either error case exits 0, or error messages lack specific phase information.

Report: `PASS` or `FAIL` with evidence (exit codes, error message content).
