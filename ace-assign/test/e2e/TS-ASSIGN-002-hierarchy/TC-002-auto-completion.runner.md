# Goal 2 — Auto-Completion

## Goal

Test parent auto-completion when all children finish, including multi-level cascade (grandchild -> parent -> grandparent auto-completion).

## Workspace

Save all output to `results/tc/02/`. Required artifact:
- `results/tc/02/` — auto-completion execution evidence

## Constraints

### Command Discipline (required)
- Use positional step targeting for explicit step completions in the active assignment:
  - `ace-assign finish <step-number> --message <report-file>`
- After each `create`, run `ace-assign select <id>` so positional `finish` targets the intended active assignment.
- For `add` commands in this goal, do NOT pass `--assignment`; mutate the selected active assignment directly.
- Use scoped `--assignment "<assignment-id>@<step-number>"` only to constrain subtree operations, not as a substitute for explicit step targeting.
- When providing a file path to `--message`, ensure the file exists at the path (so it resolves as file content, not inline string).

### Single-Level Auto-Completion
- Create assignment from `completion/job-single-level.yaml`.
- Add two children under parent 010.
- Verify parent cannot complete while children are incomplete.
- Confirm child `010.01` is the active step after child injection, then complete it with:
  - `ace-assign finish 010.01 --message completion/child1-report.md`
- Verify child two becomes current, parent still pending.
- Complete second child with:
  - `ace-assign finish 010.02 --message completion/child2-report.md`
- Verify parent auto-completes with an "Auto-completed" report in `reports/`.
- If report files exist, copy representative report evidence into `results/tc/02/`.
- Verify workflow advances to next top-level step (020-final-step).

### Multi-Level Auto-Completion
- Clean cache, create assignment from `completion/job-multi-level.yaml`.
- Add parent under 010 (`add --after 010 --child`), add grandchild under parent (`add --after 010.01 --child`).
- Confirm grandchild `010.01.01` is the active step after the second child injection before attempting completion.
- Complete grandchild with:
  - `ace-assign finish 010.01.01 --message completion/grandchild-report.md`
- Verify cascade: grandchild done, parent auto-completes, grandparent auto-completes.
- If cascade reports exist, copy representative cascade report evidence into `results/tc/02/`.
- Next top-level step (020-next-task) becomes current.
- Capture command outputs using stable names expected by verification:
  - `create_single.*`, `add_children_single.*`, `status_single_before.*`, `status_single_mid.*`, `status_single_after.*`
  - `finish_child1.*`, `finish_child2.*`, `list_reports_single.*`
  - `create_multi.*`, `add_parent_multi.*`, `add_grandchild_multi.*`, `status_multi_before.*`, `status_multi_after.*`
  - `finish_grandchild.*`, `list_reports_multi.*`
- All artifacts must come from real tool execution.
