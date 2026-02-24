# Goal 5 — Fork Subtree Scope Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Assignment created** — `create.exit` contains `0`. Assignment ID captured.
2. **Initial state** — `status-initial.stdout` shows current phase as 010-precheck (outside subtree).
3. **Scoped subtree detected** — `status-scoped.stdout` includes phase 020 subtree entries.
4. **Scoped view** — `status-scoped.stdout` shows subtree phases: 020, 020.01 (onboard), 020.02 (plan-task), 020.03 (work-on-task), and excludes out-of-scope phases 010/030.
5. **No state mutations** — `phase-states-before.stdout` and `phase-states-after.stdout` match. No phases changed state from scoped inspection.
6. **Unscoped unchanged** — `status-after-scope.stdout` still shows 010-precheck as current phase.

## Verdict

- **PASS**: Scoped status shows only subtree phases, resolves subtree current phase, and causes no state mutations.
- **FAIL**: Scoped view shows wrong phases, state mutations occurred, or current phase changed.

Report: `PASS` or `FAIL` with evidence (scoped output excerpts, state comparison).
