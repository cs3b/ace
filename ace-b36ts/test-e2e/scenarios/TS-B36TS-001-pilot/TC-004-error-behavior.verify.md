# Goal 4 — Error Behavior Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Files exist** — At least 2 distinct error-case file sets exist in `results/tc/04/` (each with exit code, stdout, and stderr captured).
2. **Non-zero exit codes** — Every captured exit code is non-zero.
3. **Error on stderr** — Every stderr capture contains a non-empty error message.
4. **Clean stdout** — Every stdout capture is either empty or contains no error message content (errors must not leak to stdout).

## Verdict

- **PASS**: At least 2 error cases present, all showing non-zero exit codes, error messages on stderr, and clean stdout.
- **FAIL**: Fewer than 2 cases, any zero exit code, error messages on stdout, or missing captures.

Report: `PASS` or `FAIL` with evidence (exit codes found, stderr snippets, stdout content or absence).
