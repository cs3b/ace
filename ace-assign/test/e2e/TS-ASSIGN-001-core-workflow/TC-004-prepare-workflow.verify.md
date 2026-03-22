# Goal 4 — Prepare Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Fixture copy exists** — `work-on-task.yml` exists under `results/tc/04/`.
2. **Single-task compatibility** — `work-on-task.yml` contains `name: work-on-task`, `steps:`, and shorthand single-task usage markers (`--taskref` or equivalent).
3. **Multi-task capability** — `work-on-task.yml` contains `taskrefs` parameter + `expansion:` with expected batch/child template markers.
4. **No internal API dependency** — Evidence shows CLI/tool-based validation only (no Ruby internal API output expected).
5. **CLI-only evidence** — `fixture-checks.stdout` and `analysis.md` exist and show command-based checks.

## Verdict

- **PASS**: Unified fixture is present and validated with command-based evidence for both single-task and multi-task behavior.
- **FAIL**: Fixture missing, required markers absent, or validation evidence missing.

Report: `PASS` or `FAIL` with evidence (file content citations).
