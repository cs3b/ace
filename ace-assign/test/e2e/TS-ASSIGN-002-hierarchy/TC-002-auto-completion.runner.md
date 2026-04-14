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
- For `add --yaml`, use only scratch `.yaml` files with a top-level `steps:` array. Never use the markdown report files as add inputs.
- For `finish --message`, use only the existing markdown report files under `completion/`.

### Single-Level Auto-Completion
- Create assignment from `completion/job-single-level.yaml`.
- Write scratch YAML files under `.ace-local/e2e-inputs/tc02/`:
  - `child-one.yaml` -> one `steps:` entry named `child-one`
  - `child-two.yaml` -> one `steps:` entry named `child-two`
- Add the two children under parent 010 using explicit child insertion commands:
  - `ace-assign add --yaml .ace-local/e2e-inputs/tc02/child-one.yaml --after 010 --child`
  - `ace-assign add --yaml .ace-local/e2e-inputs/tc02/child-two.yaml --after 010 --child`
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
- Write scratch YAML files under `.ace-local/e2e-inputs/tc02/`:
  - `nested-parent.yaml` -> one `steps:` entry named `nested-parent`
  - `nested-grandchild.yaml` -> one `steps:` entry named `nested-grandchild`
- Add the parent under 010 with an explicit child insertion command:
  - `ace-assign add --yaml .ace-local/e2e-inputs/tc02/nested-parent.yaml --after 010 --child`
- Then add the grandchild under 010.01 with an explicit child insertion command:
  - `ace-assign add --yaml .ace-local/e2e-inputs/tc02/nested-grandchild.yaml --after 010.01 --child`
- Confirm grandchild `010.01.01` is the active step after the second child injection before attempting completion.
- Complete grandchild with:
  - `ace-assign finish 010.01.01 --message completion/grandchild-report.md`
- Verify cascade: grandchild done, parent auto-completes, grandparent auto-completes.
- If cascade reports exist, copy representative cascade report evidence into `results/tc/02/`.
- Next top-level step (020-next-task) becomes current.
- Capture command outputs using stable names expected by verification:
  - `create_single.*`, `add_child1.*`, `add_child2.*`, `status_single_before.*`, `status_single_mid.*`, `status_single_after.*`
  - `finish_child1.*`, `finish_child2.*`, `list_reports_single.*`
  - `create_multi.*`, `add_parent_multi.*`, `add_grandchild_multi.*`, `status_multi_before.*`, `status_multi_after.*`
  - `finish_grandchild.*`, `list_reports_multi.*`
- Do not stop after an input mistake. If an `add --yaml` attempt fails because the input file is not valid YAML, correct the scratch YAML input and repeat the command using the same stable capture name that the verifier expects.
- All artifacts must come from real tool execution.
