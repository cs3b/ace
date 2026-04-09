# Goal 5 — Fork Subtree Scope

## Goal

Test scoped assignment syntax (`<id>@<step>`) to inspect only a subtree without changing any step state. Verify only subtree steps are shown and no state mutations occur during scoped inspection.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/create.stdout`, `.exit` — assignment creation
- `results/tc/05/assignment-id.txt` — captured assignment ID
- `results/tc/05/status-initial.stdout` — initial status (current step outside subtree)
- `results/tc/05/status-initial.json` — initial status as JSON oracle
- `results/tc/05/status-scoped.stdout` — scoped status showing only subtree
- `results/tc/05/status-scoped.json` — scoped subtree status as JSON oracle
- `results/tc/05/status-after-scope.stdout` — status after scoped inspection (unchanged)
- `results/tc/05/status-after-scope.json` — unscoped status as JSON oracle

## Constraints

- Create assignment from `fixtures/subtree/job.yaml`. Capture assignment ID.
- `assignment-id.txt` must always be written; if ID parsing fails, write an explicit resolution failure marker plus the create output context instead of omitting the artifact.
- Verify initial current step is outside the subtree (010-precheck).
- Capture both table and JSON output for each status snapshot.
- Use scoped syntax exactly: `ace-assign status --assignment "<id>@020"` for `status-scoped.stdout` and `status-scoped.json`.
- Use unscoped syntax exactly: `ace-assign status --assignment "<id>"` for `status-after-scope.stdout` and `status-after-scope.json`.
- Do **not** reuse unscoped output for scoped capture.
- Verify scoped status detects fork subtree root (020-subtree-a).
- Verify scoped status shows only subtree steps: 020, 020.01, 020.02, 020.03.
- Verify scoped current step resolves to subtree child (020.01-onboard).
- Verify NO step state changes occurred: all steps remain in their original state.
- Verify unscoped status still shows 010-precheck as current step.
- All artifacts must come from real tool execution.
