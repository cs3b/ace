# Goal 2 - Create, Show, and List Lifecycle

## Goal

Create a real task via CLI, then verify it is discoverable through `list` and `show` with stable IDs.

## Workspace

Save only real command captures to `results/tc/02/`.

## Constraints

- Use only `ace-task ...` commands.
- Capture stdout/stderr/exit for each command.
- Do not create helper ref-tracking or filesystem-inventory files under `results/`.
- Resolve the created task ref from real command output at execution time and use it immediately for `show`.
- Mention the resolved task ref in final runner observations.

## Steps

1. Run `ace-task create "E2E smoke task" --status pending` and save `create.*`.
2. Run `ace-task list --status pending` and save `list.*`.
3. Resolve the full short ref for `E2E smoke task` from the real `create`/`list` output.
4. Run `ace-task show <resolved-ref>` immediately in this goal and save `show.stdout`, `show.stderr`, and `show.exit` under `results/tc/02/`.
5. Do not defer the `show` capture to a later TC.
