# Goal 5 — CLI-API Parity Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **All capture sets exist** — `results/tc/05/` contains stdout/exit for both success-mode CLI runs and the error-path run.
- **Success path exits are zero** — `cli-valid.exit` and `cli-valid-cache.exit` are `0`.
- **Success behavior comparison exists** — `comparison.md` classifies behavior as `consistent` or `divergent` with evidence.
- **Error handling is non-zero** — `cli-error.exit` is non-zero for nonexistent file input and has informative stderr/stdout evidence.

## Verdict

- **PASS**: Success-mode CLI runs pass, comparison evidence is present, and error-path handling is non-zero with useful diagnostics.
- **FAIL**: Missing artifacts, wrong exit behavior, or missing comparison/error evidence.

Report: `PASS` or `FAIL` with evidence (exit codes, output match status, error behavior).
