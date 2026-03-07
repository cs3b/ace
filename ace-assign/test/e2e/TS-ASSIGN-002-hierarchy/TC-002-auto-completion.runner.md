# Goal 2 — Auto-Completion

## Goal

Test parent auto-completion when all children finish, including multi-level cascade (grandchild -> parent -> grandparent auto-completion).

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/create-single.stdout`, `.exit` — single-level assignment creation
- `results/tc/02/add-children.stdout` — child addition output
- `results/tc/02/complete-child1.stdout`, `.exit` — first child completion
- `results/tc/02/status-after-child1.stdout` — status showing child two is current, parent still pending
- `results/tc/02/complete-child2.stdout`, `.exit` — second child completion
- `results/tc/02/parent-auto-complete.stdout` — evidence parent auto-completed
- `results/tc/02/create-multi.stdout`, `.exit` — multi-level assignment creation
- `results/tc/02/add-hierarchy.stdout` — parent + grandchild addition
- `results/tc/02/complete-grandchild.stdout`, `.exit` — grandchild completion
- `results/tc/02/cascade-auto-complete.stdout` — evidence of multi-level cascade

## Constraints

### Command Discipline (required)
- Use `ace-assign finish --message <report-file> --assignment "<assignment-id>@<phase-number>"` for targeted completions.
- Do **not** pass `<assignment-id>@<phase>` as the positional report file argument.
- When providing a file path to `--message`, ensure the file exists at the path (so it resolves as file content, not inline string).

### Single-Level Auto-Completion
- Create assignment from `fixtures/completion/job-single-level.yaml`.
- Add two children under parent 010.
- Verify parent cannot complete while children are incomplete.
- Set parent to pending, activate first child, complete it with:
  - `ace-assign finish --message fixtures/completion/child1-report.md --assignment "<assignment-id>@010.01"`
- Verify child two becomes current, parent still pending.
- Complete second child with:
  - `ace-assign finish --message fixtures/completion/child2-report.md --assignment "<assignment-id>@010.02"`
- Verify parent auto-completes with "Auto-completed" report at reports/010-parent-job.r.md.
- Verify workflow advances to next top-level phase (020-final-step).

### Multi-Level Auto-Completion
- Clean cache, create assignment from `fixtures/completion/job-multi-level.yaml`.
- Add parent under 010 (`add --after 010 --child`), add grandchild under parent (`add --after 010.01 --child`).
- Set 010 and 010.01 to pending, activate grandchild.
- Complete grandchild with:
  - `ace-assign finish --message fixtures/completion/grandchild-report.md --assignment "<assignment-id>@010.01.01"`
- Verify cascade: grandchild done, parent auto-completes, grandparent auto-completes.
- Next top-level phase (020-next-task) becomes current.
- All artifacts must come from real tool execution.
