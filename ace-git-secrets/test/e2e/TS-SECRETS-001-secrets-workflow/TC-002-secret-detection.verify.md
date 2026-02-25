# Goal 2 — Secret Detection Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Capture set exists** — results/tc/02/ contains stdout/stderr/exit for the scan.
2. **Non-zero exit code** — Exit code is 1 (secrets found).
3. **Detection reported** — Output mentions tokens or secrets being found.

## Verdict

- **PASS**: Scan detects secrets, non-zero exit code, detection reported in output.
- **FAIL**: Zero exit code, or no detection reported.

Report: `PASS` or `FAIL` with evidence (exit code, output snippet).
