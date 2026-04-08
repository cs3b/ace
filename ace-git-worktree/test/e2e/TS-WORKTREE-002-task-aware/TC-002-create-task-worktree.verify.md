# Goal 2 — Create Task Worktree Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Creation artifacts exist** — results/tc/02/ contains stdout/exit for create-task.
2. **Creation succeeds** — create-task.exit is 0.
3. **Branch is task-derived** — branch-check.stdout shows a branch name derived from the task (for example containing `q7w` or the task slug), not an unrelated branch.
4. **Task worktree listed** — `list-task.stdout` shows the newly created task-associated worktree, and `list-show-tasks.stdout` includes task metadata for `q7w`.

## Verdict

- **PASS**: Task worktree created with a task-derived branch and appears in the explicit task-aware listings.
- **FAIL**: Creation fails, branch naming is unrelated to the task, or the worktree is not in the task-associated list.

Report: `PASS` or `FAIL` with evidence (exit code, branch name, list output).
