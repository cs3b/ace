# Goal 3 — List and Filter by Task Association Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **All capture sets exist** — results/tc/03/ contains stdout/exit for show-tasks, task-associated, and no-task-associated.
2. **Show-tasks includes task info** — show-tasks.stdout includes task-related metadata or identifiers alongside worktree entries.
3. **Task-associated filter works** — task-associated.stdout shows only the task 999 worktree (not the main worktree).
4. **No-task-associated filter works** — no-task-associated.stdout shows the main worktree but excludes the task 999 worktree.

## Verdict

- **PASS**: All three filters produce correct, distinct output separating task and non-task worktrees.
- **FAIL**: Filters not working, outputs identical, or captures missing.

Report: `PASS` or `FAIL` with evidence (output snippets showing filtering).
