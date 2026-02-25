# Goal 2 — Filter by Status

## Goal

Create at least one draft and one done task, then run
`ace-task list --status draft --include-drafts` and capture output showing only
matching draft tasks.

## Workspace

Save artifacts to `results/tc/02/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/02/`.
- Do not write outside the sandbox.
- Create control tasks with explicit statuses: at least one using `ace-task create --status draft` and one using `ace-task create --status done`.
- Capture task creation output as `results/tc/02/create_draft.*` and `results/tc/02/create_done.*`.
- Run `ace-task list --status draft --include-drafts` and capture its output as the primary verification evidence.
