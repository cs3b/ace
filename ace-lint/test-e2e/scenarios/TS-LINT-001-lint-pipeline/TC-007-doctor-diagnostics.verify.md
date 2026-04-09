# Goal 7 — Doctor Diagnostics Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Both capture sets exist** — results/tc/07/ contains stdout/exit for both healthy and syntax-error environments.
2. **Healthy environment** — Exit code is not 2 (no error state). Output mentions validators or configuration.
3. **Syntax error detection** — Command completes without crashing (exit code ≤ 2). Output indicates an error, syntax issue, or invalid configuration.

## Verdict

- **PASS**: Healthy env shows validators/config info without error. Syntax error env is detected or reported gracefully.
- **FAIL**: Healthy env shows errors, or syntax error crashes the tool.

Report: `PASS` or `FAIL` with evidence (exit codes, output snippets from both environments).
