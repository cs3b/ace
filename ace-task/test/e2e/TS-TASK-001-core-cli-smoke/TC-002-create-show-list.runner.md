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
2. Extract the exact created ref from the `Created task <ref>` line in `create.stdout` into `results/tc/02/task-ref.txt`. The saved ref must match the CLI output exactly, for example `8r7.t.trm`.
3. Run `ace-task list --status pending` and save `list.*`.
4. Run `ace-task show <ref>` using the exact contents of `task-ref.txt` with no truncation or normalization, and save `show.*`.
5. Capture filesystem evidence with `find .ace-tasks -maxdepth 3 -type f -name '*.s.md' | sort > results/tc/02/task-files.txt`.
