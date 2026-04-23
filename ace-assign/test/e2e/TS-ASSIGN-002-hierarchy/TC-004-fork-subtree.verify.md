# Goal 4 — Fork Subtree Scope Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Assignment created** — `create.exit` contains `0` and `assignment-id.txt` contains a non-empty assignment ID derived from `create.stdout`.
2. **Initial state** — `status-initial.json` reports `active_steps == []`, `next_step.number == "010"`, and `next_step.name == "precheck"`. If JSON is unavailable, accept `status-initial.stdout` with equivalent table evidence only when the JSON command exit/stderr explains the absence.
3. **Scoped subtree detected** — `status-scoped.json` contains only steps 020, 020.01, 020.02, and 020.03.
4. **Scoped view** — scoped status evidence reports `active_steps == []`, `next_step.number == "020.01"`, and excludes out-of-scope steps 010/030.
5. **No step-state mutations** — `step-states-before.stdout` and `step-states-after.stdout` match. If these files are absent, accept equivalent before/after status output proving step statuses did not change; assignment lifecycle state labels (for example `running` vs `paused`) alone are not sufficient failure evidence.
6. **Unscoped unchanged** — `status-after-scope.json` keeps the same unscoped next-step identity (`010`, `precheck`) even if assignment lifecycle state text differs.

## Verdict

- **PASS**: Scoped status shows only subtree steps, resolves subtree next-step state, and causes no state mutations.
- **FAIL**: Scoped view shows wrong steps, state mutations occurred, or next-step identity changed.

Report: `PASS` or `FAIL` with evidence from the JSON oracle files first, then stdout excerpts if needed.
