# Goal 4 — Prepare Workflow Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Fixture copy exists** — `work-on-task.yml` exists under `results/tc/04/`.
2. **Bundle output is valid** — The copied artifact is either the plain preset body or an `ace-bundle` wrapper that clearly identifies `prepare/work-on-task.yml` as the source.
3. **CLI-only evidence** — `fixture-checks.stdout` exists and shows command-based validation with no internal Ruby API use.
4. **Capability conclusion recorded** — `fixture-checks.stdout` or optional `analysis.md` makes it clear whether the copied output is a wrapper or expanded body and ties that conclusion back to the command evidence.

## Verdict

- **PASS**: The workflow fixture is present and validated through CLI evidence, even if `ace-bundle` emits wrapper metadata instead of raw YAML body content.
- **FAIL**: Fixture missing, command-based evidence missing, or the copied artifact cannot be tied back to the expected source.

Report: `PASS` or `FAIL` with evidence (file content citations).
