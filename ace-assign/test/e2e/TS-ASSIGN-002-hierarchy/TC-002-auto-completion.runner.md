# Goal 2 — Auto-Completion

## Goal

Test parent auto-completion when all children finish, including multi-level cascade (grandchild -> parent -> grandparent auto-completion).

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/create-single.stdout`, `.exit` — single-level assignment creation
- `results/tc/02/single-assignment-id.txt` — resolved assignment ID for the single-level flow
- `results/tc/02/add-children.stdout` — child addition output
- `results/tc/02/complete-child1.stdout`, `.exit` — first child completion
- `results/tc/02/status-after-child1.stdout` — status showing child two is current, parent still pending
- `results/tc/02/complete-child2.stdout`, `.exit` — second child completion
- `results/tc/02/parent-auto-complete.stdout` — evidence parent auto-completed
- `results/tc/02/010-parent-job.r.md` — copied parent auto-completion report when present
- `results/tc/02/create-multi.stdout`, `.exit` — multi-level assignment creation
- `results/tc/02/multi-assignment-id.txt` — resolved assignment ID for the multi-level flow
- `results/tc/02/add-hierarchy.stdout` — parent + grandchild addition
- `results/tc/02/complete-grandchild.stdout`, `.exit` — grandchild completion
- `results/tc/02/cascade-auto-complete.stdout` — evidence of multi-level cascade
- `results/tc/02/010.01-parent-job.r.md` — copied parent cascade report when present
- `results/tc/02/010-grandparent-job.r.md` — copied grandparent cascade report when present

## Constraints

### Command Discipline (required)
- For these flows, complete steps through the targeted assignment's current step:
  - `ace-assign finish --assignment "<assignment-id>" --message <report-file>`
- Do not use positional step targeting in this TC; the assignments under test are not selected as the active assignment.
- Use scoped `--assignment "<assignment-id>@<step-number>"` only to constrain subtree operations, not as a substitute for assignment-targeted finish.
- When providing a file path to `--message`, ensure the file exists at the path (so it resolves as file content, not inline string).

### Single-Level Auto-Completion
- Create assignment from `fixtures/completion/job-single-level.yaml`.
- Capture the created assignment ID into `results/tc/02/single-assignment-id.txt`.
- Add two children under parent 010.
- Verify parent cannot complete while children are incomplete.
- Confirm child `010.01` is the active step after child injection, then complete it with:
  - `ace-assign finish --assignment "<single-assignment-id>" --message fixtures/completion/child1-report.md`
- Verify child two becomes current, parent still pending.
- Complete second child with:
  - `ace-assign finish --assignment "<single-assignment-id>" --message fixtures/completion/child2-report.md`
- Verify parent auto-completes with "Auto-completed" report at reports/010-parent-job.r.md.
- If the report exists, copy it into `results/tc/02/010-parent-job.r.md`.
- `parent-auto-complete.stdout` must always be written; if no dedicated report file is present, capture the direct status/output evidence that shows the parent auto-completed.
- Verify workflow advances to next top-level step (020-final-step).

### Multi-Level Auto-Completion
- Clean cache, create assignment from `fixtures/completion/job-multi-level.yaml`.
- Capture the created assignment ID into `results/tc/02/multi-assignment-id.txt`.
- Add parent under 010 (`add --after 010 --child`), add grandchild under parent (`add --after 010.01 --child`).
- Confirm grandchild `010.01.01` is the active step after the second child injection before attempting completion.
- Complete grandchild with:
  - `ace-assign finish --assignment "<multi-assignment-id>" --message fixtures/completion/grandchild-report.md`
- Verify cascade: grandchild done, parent auto-completes, grandparent auto-completes.
- `cascade-auto-complete.stdout` must always be written; if dedicated cascade report files are absent, capture the status/output evidence that proves the cascade outcome.
- If cascade reports exist, copy them into `results/tc/02/` using the filenames above.
- Next top-level step (020-next-task) becomes current.
- All artifacts must come from real tool execution.
