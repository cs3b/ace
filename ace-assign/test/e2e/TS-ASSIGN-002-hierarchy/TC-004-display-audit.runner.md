# Goal 4 — Display and Audit Trail

## Goal

Verify status displays tree structure with hierarchy indicators, and audit trail metadata is correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/create-tree.stdout`, `.exit` — tree display assignment creation
- `results/tc/04/add-tree-children.stdout` — children added under two parents
- `results/tc/04/status-tree.stdout` — hierarchical status display
- `results/tc/04/create-audit.stdout`, `.exit` — audit trail assignment creation
- `results/tc/04/child-of-metadata.stdout` — child_of audit trail evidence
- `results/tc/04/inject-sibling.stdout` — sibling injection output
- `results/tc/04/injected-after-metadata.stdout` — injected_after audit trail
- `results/tc/04/renumbered-metadata.stdout` — renumbered_from/renumbered_at audit trail
- `results/tc/04/dynamic-metadata.stdout` — dynamic add audit trail

## Setup

Environment provides:
- `CACHE_BASE=.cache/ace-assign` (create it: `mkdir -p .cache/ace-assign`)
- `PROJECT_ROOT_PATH=.`
- Fixtures: `fixtures/display/job-tree.yaml`, `fixtures/display/job-audit.yaml`

## Constraints

### Tree Display
- Create assignment from `fixtures/display/job-tree.yaml`.
- Add children: a-subtask-1 and a-subtask-2 under 010, b-subtask-1 under 020.
- Capture status output. Verify all 5 phases displayed.
- Verify hierarchical display indicators (tree characters: pipe, tee, elbow) and nested phase numbers (010.01, 010.02, 020.01).

### Audit Trail
- Clean cache, create assignment from `fixtures/display/job-audit.yaml`.
- Add child under 010 (`add --after 010 --child`). Verify `added_by: child_of:010` and `parent: "010"`.
- Add another child, then inject sibling after first child. Verify `added_by: injected_after:010.01`.
- Verify renumbered phase has `renumbered_from` and `renumbered_at` (ISO8601 format).
- Mark parent done, add dynamic phase. Verify `added_by: dynamic`.
- All artifacts must come from real tool execution.
