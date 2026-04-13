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
2. **Execution result is explicit** — either:
   - `execution.exit` is `0` and produced a normal review output, or
   - `execution.exit` is non-zero with a clear model-availability error message (for example: missing `review-default` role model).
3. **Session directory created** — Session listing shows session files created.
4. **Outcome evidence captured** — `review-output.md` or stderr includes enough detail to classify the run as successful execution or explicit environment blocker.

## Verdict

- **PASS**: Execution succeeds with meaningful output, or fails explicitly due to missing model configuration with clear evidence.
- **FAIL**: Execution outcome is ambiguous, session artifacts are missing, or failure lacks actionable error details.

Report: `PASS` or `FAIL` with evidence.
