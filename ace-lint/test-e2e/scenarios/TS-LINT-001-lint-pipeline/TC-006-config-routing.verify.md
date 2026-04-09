# Goal 6 — Configuration Routing Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

### Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

### Checks
1. **Config routing artifacts exist** — results/tc/06/ contains stdout/exit captures for config-based routing.
2. **Config routing succeeds** — Exit code 0 when linting with config-based group routing.
3. **CLI override artifacts exist** — Separate captures for the `--validators` override test.
4. **CLI override succeeds** — Exit code 0 when overriding with `--validators rubocop`.

## Verdict

- **PASS**: Both config-based routing and CLI override succeed (exit 0), proving config discovery and CLI precedence work.
- **FAIL**: Either test fails, or captures missing.

Report: `PASS` or `FAIL` with evidence (exit codes, output snippets showing routing behavior).
