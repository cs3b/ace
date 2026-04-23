# Goal 1 — Public Surface Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Help capture exists** — `results/tc/01/help.stdout`, `results/tc/01/help.stderr`, and `results/tc/01/help.exit` exist.
2. **Help command succeeded** — `results/tc/01/help.exit` is `0`.
3. **Mentions key flags** — `results/tc/01/help.stdout` references at least three of: `--fix`, `--no-report`, `--validators`, `--doctor`.
4. **Public surface is substantive** — `results/tc/01/help.stdout` contains more than 5 non-empty lines.

## Verdict

- **PASS**: The retained help capture exists, succeeded, and exposes the key public flags used later in the scenario.
- **FAIL**: The help capture is missing, failed, or does not expose the expected public surface.

Report: `PASS` or `FAIL` with evidence from the help capture.
