# Goal 5 — Fork Subtree Scope

## Goal

Test scoped assignment syntax (`<id>@<phase>`) to inspect only a subtree without changing any phase state. Verify only subtree phases are shown and no state mutations occur during scoped inspection.

## Workspace

Save all output to `results/tc/05/`. Capture:
- `results/tc/05/create.stdout`, `.exit` — assignment creation
- `results/tc/05/assignment-id.txt` — captured assignment ID
- `results/tc/05/status-initial.stdout` — initial status (current phase outside subtree)
- `results/tc/05/status-scoped.stdout` — scoped status showing only subtree
- `results/tc/05/status-after-scope.stdout` — status after scoped inspection (unchanged)
- `results/tc/05/phase-states-before.stdout` — phase states before scoped inspection
- `results/tc/05/phase-states-after.stdout` — phase states after scoped inspection

## Setup

Environment provides:
- `CACHE_BASE=.cache/ace-assign` (create it: `mkdir -p .cache/ace-assign`)
- `PROJECT_ROOT_PATH=.`
- Fixture: `fixtures/subtree/job.yaml`

## Constraints

- Create assignment from `fixtures/subtree/job.yaml`. Capture assignment ID.
- Verify initial current phase is outside the subtree (010-precheck).
- Use scoped syntax: `ace-assign status --assignment "<id>@020"`.
- Verify scoped status detects fork subtree root (020-subtree-a).
- Verify scoped status shows only subtree phases: 020, 020.01, 020.02, 020.03.
- Verify scoped current phase resolves to subtree child (020.01-onboard).
- Verify NO phase state changes occurred: all phases remain in their original state.
- Verify unscoped status still shows 010-precheck as current phase.
- All artifacts must come from real tool execution.
