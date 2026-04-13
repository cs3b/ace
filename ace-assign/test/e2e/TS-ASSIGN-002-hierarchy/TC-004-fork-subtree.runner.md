# Goal 4 — Fork Subtree Scope

## Goal

Test scoped assignment syntax (`<id>@<step>`) to inspect only a subtree without changing any step state. Verify only subtree steps are shown and no state mutations occur during scoped inspection.

## Workspace

Save all output to `results/tc/04/`. Required artifact:
- `results/tc/04/` — fork subtree scope evidence

## Constraints

- Create assignment from `subtree/job.yaml`. Capture assignment ID.
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
