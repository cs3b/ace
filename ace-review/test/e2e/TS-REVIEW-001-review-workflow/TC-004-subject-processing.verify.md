# Goal 4 — Subject Processing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **All three capture sets exist** — results/tc/04/ contains stdout/exit for diff, files, and mixed subjects.
2. **All exit codes zero** — All three subject types processed successfully.
3. **Each type processed** — Output shows either:
   - the subject type was recognized explicitly in stdout/stderr, or
   - a prepared review session was created successfully for each subject invocation, which is acceptable evidence that the subject was parsed well enough to build the session.

## Verdict

- **PASS**: All subject types (diff, files, mixed) process successfully via dry-run or session preparation.
- **FAIL**: Any subject type fails or is not recognized.

Report: `PASS` or `FAIL` with evidence (exit codes per subject type).
