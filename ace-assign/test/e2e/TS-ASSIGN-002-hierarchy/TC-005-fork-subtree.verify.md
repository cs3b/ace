# Goal 5 — Fork Subtree Scope Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — `create.exit` contains `0`. Assignment ID captured.
2. **Initial state** — `status-initial.json` reports `current_phase.number == "010"` and `current_phase.name == "precheck"`.
3. **Scoped subtree detected** — `status-scoped.json` contains only phases 020, 020.01, 020.02, and 020.03.
4. **Scoped view** — `status-scoped.json` reports `current_phase.number == "020.01"` and excludes out-of-scope phases 010/030.
5. **No state mutations** — `phase-states-before.stdout` and `phase-states-after.stdout` match. No phases changed state from scoped inspection.
6. **Unscoped unchanged** — `status-after-scope.json` reports `current_phase.number == "010"` and `current_phase.name == "precheck"`.

## Verdict

- **PASS**: Scoped status shows only subtree phases, resolves subtree current phase, and causes no state mutations.
- **FAIL**: Scoped view shows wrong phases, state mutations occurred, or current phase changed.

Report: `PASS` or `FAIL` with evidence from the JSON oracle files first, then stdout excerpts if needed.
