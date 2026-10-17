# Goal 3 — List and Filter by Task Association Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All capture sets exist** — results/tc/03/ contains stdout/exit for default, task-associated, and no-task-associated.
2. **Default table includes task info** — default.stdout includes the `Task` column and the task-associated worktree's resolved task id (or its row) alongside worktree entries.
3. **Task-associated filter works** — task-associated.stdout shows only the task 8pp.t.q7w worktree (not the main worktree).
4. **No-task-associated filter works** — no-task-associated.stdout shows the main worktree but excludes the task 8pp.t.q7w worktree.

## Verdict

- **PASS**: The default table and both filters produce correct, distinct output separating task and non-task worktrees.
- **FAIL**: Filters not working, outputs identical, or captures missing.

Report: `PASS` or `FAIL` with evidence (output snippets showing filtering).
