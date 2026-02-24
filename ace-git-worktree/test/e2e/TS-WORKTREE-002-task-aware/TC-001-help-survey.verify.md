# Goal 1 — Help Survey (Task-Aware Flags) Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **File exists** — At least one file exists in `results/tc/01/`.
2. **Substantive content** — The file contains more than 5 lines of non-empty text.
3. **Mentions task-aware concepts** — The content references task-related flags or options (--task, --show-tasks, --task-associated, --no-task-associated, or --delete-branch).
4. **Observations present** — The content includes at least one observation about how task flags integrate with worktree operations.

## Verdict

- **PASS**: All expectations met. File exists with substantive observations about task-aware worktree flags.
- **FAIL**: File missing, empty, boilerplate-only, or lacks mention of task-aware concepts.

Report: `PASS` or `FAIL` with evidence.
