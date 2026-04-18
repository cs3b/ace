# Goal 1 - Status Dashboard Real State

## Goal

Create and update real tasks, then confirm `ace-task status` reflects the resulting
state using command output and on-disk task artifacts.

## Workspace

Save all artifacts to `results/tc/01/`.

## Constraints

- Use only `ace-task ...` commands.
- Capture stdout/stderr/exit for each command.
- Keep all task writes in sandbox paths.
- Extract refs only from `create-*.stdout` lines matching `Created task <ref>` and preserve full IDs.
- Mention the created refs in final runner observations.

## Steps

1. Run `ace-task status` and save `status-before.*`.
2. Run `ace-task create "E2E status pending task" --status pending` and save `create-pending.*`.
3. Run `ace-task create "E2E status done task" --status pending` and save `create-done-candidate.*`.
4. Resolve the second task ref from `create-done-candidate.stdout` (`Created task <ref>`) and run `ace-task update <ref> --set status=done`; save `mark-done.*`.
5. Run `ace-task status` again and save `status-after.*`.
6. Run `ace-task list --status pending` and save `list-pending.*`.
7. Run `ace-task list --status done --in all` and save `list-done.*`.
