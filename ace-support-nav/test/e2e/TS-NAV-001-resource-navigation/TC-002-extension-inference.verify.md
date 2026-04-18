# Goal 2 — Public Resolve Journey Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. **Both capture sets exist** — `results/tc/02/` contains stdout/stderr/exit captures for guide and workflow resolve commands.
2. **Both exit codes zero** — `guide-resolve.exit` and `workflow-resolve.exit` are `0`.
3. **Guide resolution is usable** — `guide-resolve.stdout` contains a concrete resolved path to a guide resource.
4. **Workflow resolution is usable** — `workflow-resolve.stdout` contains a concrete resolved path to a workflow resource.
5. **No fallback-chain micromanagement required** — Verdict does not depend on a specific extension-priority internals sequence; only user-visible successful resolution.

## Verdict

- **PASS**: Both resolve operations succeed and produce usable user-facing paths.
- **FAIL**: Missing captures, non-zero exits, or unresolved/non-usable outputs.

Report: `PASS` or `FAIL` with evidence (resolved paths and exit codes).
