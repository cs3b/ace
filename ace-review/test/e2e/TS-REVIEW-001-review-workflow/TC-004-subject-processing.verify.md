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
3. **Each type processed** — Output shows each subject type was recognized and processed.

## Verdict

- **PASS**: All subject types (diff, files, mixed) process successfully via dry-run.
- **FAIL**: Any subject type fails or is not recognized.

Report: `PASS` or `FAIL` with evidence (exit codes per subject type).
