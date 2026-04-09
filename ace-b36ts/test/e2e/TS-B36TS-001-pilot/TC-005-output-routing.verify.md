# Goal 5 — Output Routing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Required captures exist** — All nine required files exist:
   - `default.stdout`, `default.stderr`, `default.exit`
   - `quiet.stdout`, `quiet.stderr`, `quiet.exit`
   - `verbose.stdout`, `verbose.stderr`, `verbose.exit`
2. **Successful execution** — All three `.exit` files contain `0`.
3. **Token appears on stdout** — Each `*.stdout` file contains a token-like value (`[0-9a-z]{2,8}`).
4. **Quiet mode is least noisy** — `quiet.stderr` is empty or shorter than `verbose.stderr`.

## Verdict

- **PASS**: All required captures exist, runs succeed, stdout contains tokens, and the stderr evidence shows the expected quiet/verbose noise difference.
- **FAIL**: Missing captures, failed execution, absent token outputs, or no evidence of stream-noise comparison.

Report: `PASS` or `FAIL` with evidence (file content snippets and exit-code values).
