# Goal 1 — Help + Docs Parity Survey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Help captures exist** — Top-level, scan, and check-release help captures exist with exit code artifacts.
2. **Public subcommands are discoverable** — Captured help includes `scan`, `rewrite-history`, `revoke`, and `check-release`.
3. **Observations are substantive** — `observations.md` has at least 5 non-empty lines and is clearly grounded in the captured help output.
4. **Whitelist contract is accurate** — Observations do not claim a `--whitelist` CLI flag and explicitly frame whitelist as config-driven behavior.

## Verdict

- **PASS**: Help captures and observations accurately describe the public CLI surface and parity assumptions for later goals.
- **FAIL**: Missing captures, missing `check-release`, or inaccurate whitelist/flag claims.

Report: `PASS` or `FAIL` with evidence.
