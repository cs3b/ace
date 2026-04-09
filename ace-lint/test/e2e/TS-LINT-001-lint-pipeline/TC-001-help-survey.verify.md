# Goal 1 — Help Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Help captures exist** — `help.stdout`, `help.stderr`, and `help.exit` are present.
2. **Help succeeded** — `help.exit` reports success.
3. **Mentions key flags** — `help.stdout` references at least two of: --fix, --no-report, --validators, --doctor.

## Verdict

- **PASS**: The help command succeeds and exposes the expected lint command surface.
- **FAIL**: Captures are missing, help fails, or key flags are not evidenced.

Report: `PASS` or `FAIL` with evidence from `help.*`.
