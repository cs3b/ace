# Goal 1 — Single Model Execution Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Artifacts exist** — `results/tc/01/` contains execution captures and a session listing.
2. **Execution succeeded** — `execution.exit` is `0`.
3. **Meaningful review output exists** — `execution.stdout` or generated session files show substantive review output (not only startup/error text).
4. **Session directory created** — Session listing shows session files created.
5. **Failure evidence is actionable when not successful** — if execution fails, stderr clearly identifies a prerequisite/provider issue.

## Verdict

- **PASS**: Execution succeeds with meaningful review output and session artifacts.
- **FAIL**: Execution is non-zero (including provider/model unavailability), output is ambiguous/non-meaningful, session artifacts are missing, or failure details are not actionable.

Report: `PASS` or `FAIL` with evidence.
