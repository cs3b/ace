# Goal 1 — Help Survey (Task-Aware Flags)

## Goal

Capture the real task-aware help surface from `ace-git-worktree` root help plus relevant subcommand help.

## Capture

- `results/tc/01/help.stdout`
- `results/tc/01/help.stderr`
- `results/tc/01/help.exit`
- `results/tc/01/create-help.stdout`
- `results/tc/01/create-help.stderr`
- `results/tc/01/create-help.exit`
- `results/tc/01/list-help.stdout`
- `results/tc/01/list-help.stderr`
- `results/tc/01/list-help.exit`

## Constraints

- Use only `ace-git-worktree` to gather information.
- Start with `--help` and explore subcommand help (create, list, remove, switch) for task-related options.
- **Foundation for later goals**: Your observations here serve as the reference for all subsequent goals.
