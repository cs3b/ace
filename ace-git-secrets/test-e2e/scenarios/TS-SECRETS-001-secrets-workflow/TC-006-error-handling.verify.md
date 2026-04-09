# Goal 6 — Error Handling Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Both capture sets exist** — results/tc/06/ contains captures for revoke and rewrite-history error tests.
2. **Non-zero exit codes** — Both commands return non-zero exit codes.
3. **Helpful error messages** — At least one output mentions missing raw_value, invalid report, or similar helpful error.
4. **No crash** — No Ruby stack traces in output (graceful failure).

## Verdict

- **PASS**: Both commands fail gracefully with helpful error messages and no stack traces.
- **FAIL**: Either command succeeds unexpectedly, crashes, or provides unhelpful errors.

Report: `PASS` or `FAIL` with evidence (exit codes, error messages).
