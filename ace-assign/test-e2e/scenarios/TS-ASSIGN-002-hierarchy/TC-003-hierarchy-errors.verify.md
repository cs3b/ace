# Goal 3 — Hierarchy Errors Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Invalid finish rejected** — `advance-parent.exit` contains non-zero value. Output explains that positional `STEP` cannot be used together with `--assignment`.
2. **Invalid --after rejected** — `invalid-after.exit` contains non-zero value. Output mentions that the requested anchor step was not found or otherwise rejected.
3. **Both return non-zero** — Both error cases produce non-zero exit codes, confirming proper error handling.

## Verdict

- **PASS**: Both error cases return non-zero exit with descriptive error messages matching the current CLI and hierarchy semantics.
- **FAIL**: Either error case exits 0, or the error messages do not explain why the command was rejected.

Report: `PASS` or `FAIL` with evidence (exit codes, error message content).
