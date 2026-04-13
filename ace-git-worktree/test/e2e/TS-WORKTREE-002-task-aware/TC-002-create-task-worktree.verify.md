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
3. **Branch includes task identifier token** — branch-check.stdout shows a branch name containing `q7w` (for example `q7w-test-feature-implementation`).
4. **Task worktree listed** — list-task.stdout shows the newly created task-associated worktree.

## Verdict

- **PASS**: Task worktree created with `q7w` identifier in branch name, appears in task-associated listing.
- **FAIL**: Creation fails, branch name missing `q7w`, or worktree not in task-associated list.

Report: `PASS` or `FAIL` with evidence (exit code, branch name, list output).
