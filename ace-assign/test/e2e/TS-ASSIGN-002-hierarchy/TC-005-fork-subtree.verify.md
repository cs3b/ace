# Goal 5 — Fork Subtree Scope Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — `create.exit` contains `0`. Assignment ID captured.
2. **Initial state** — `status-initial.json` reports `current_step.number == "010"` and `current_step.name == "precheck"`.
3. **Scoped subtree detected** — `status-scoped.json` contains only steps 020, 020.01, 020.02, and 020.03.
4. **Scoped view** — `status-scoped.json` reports `current_step.number == "020.01"` and excludes out-of-scope steps 010/030.
5. **No state mutations** — `step-states-before.stdout` and `step-states-after.stdout` match. No steps changed state from scoped inspection.
6. **Unscoped unchanged** — `status-after-scope.json` reports `current_step.number == "010"` and `current_step.name == "precheck"`.

## Verdict

- **PASS**: Scoped status shows only subtree steps, resolves subtree current step, and causes no state mutations.
- **FAIL**: Scoped view shows wrong steps, state mutations occurred, or current step changed.

Report: `PASS` or `FAIL` with evidence from the JSON oracle files first, then stdout excerpts if needed.
