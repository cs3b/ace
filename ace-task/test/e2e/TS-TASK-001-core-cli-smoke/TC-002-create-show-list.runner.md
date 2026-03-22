# Goal 2 - Create, Show, and List Lifecycle

## Goal

Create a real task via CLI, then verify it is discoverable through `list` and `show` with stable IDs.

## Workspace

Save all artifacts to `results/tc/02/`.

## Constraints

- Use only `ace-task ...` commands.
- Persist the created ref for downstream checks.
- Capture stdout/stderr/exit for each command.

## Steps

1. Run `ace-task create "E2E smoke task"` and save `create.*`.
2. Extract short ref from `create.stdout` into `results/tc/02/task-ref.txt`.
3. Run `ace-task list --status pending` and save `list.*`.
4. Run `ace-task show <ref>` using `task-ref.txt` and save `show.*`.
5. Capture filesystem evidence with `find .ace-tasks -maxdepth 3 -type f -name '*.s.md' | sort > results/tc/02/task-files.txt`.
