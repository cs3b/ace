# Goal 4 — Switch by Task ID Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **Switch artifacts exist** — results/tc/04/ contains stdout/exit for switch-task.
2. **Switch succeeds** — switch-task.exit is 0 and stdout contains a filesystem path.
3. **Path is valid** — path-check.txt confirms the returned path exists as a directory.
4. **Task files present** — task-check.txt shows `.ace-tasks` directory contents in the worktree.

## Verdict

- **PASS**: Switch by task ID returns a valid path to a worktree containing task files.
- **FAIL**: Switch fails, path invalid, or `.ace-tasks` directory missing from the worktree.

Report: `PASS` or `FAIL` with evidence (path, directory listing).
