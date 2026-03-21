# Goal 1 - Help Survey

## Goal

Inspect `ace-task --help` and collect command-level help evidence for `create`, `update`, and `doctor`.

## Workspace

Save all artifacts to `results/tc/01/`.

## Constraints

- Use only `ace-task` commands.
- Capture raw outputs and exit codes.
- Do not infer missing behavior.

## Steps

1. Run `mise exec -- ace-task --help` and save stdout/stderr/exit as:
   - `results/tc/01/help.stdout`
   - `results/tc/01/help.stderr`
   - `results/tc/01/help.exit`
2. Run `mise exec -- ace-task create --help` and save as `create-help.*`.
3. Run `mise exec -- ace-task update --help` and save as `update-help.*`.
4. Run `mise exec -- ace-task doctor --help` and save as `doctor-help.*`.
