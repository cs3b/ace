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
4. **Task files check is optional diagnostic** — when present, task-check.txt should show `.ace-tasks` directory contents; absence of this optional artifact should not fail the goal if path-check passes.

## Verdict

- **PASS**: Switch by task ID returns a valid path to a task worktree, with optional diagnostic task-file listing when available.
- **FAIL**: Switch fails or path-check does not confirm a valid worktree path.

Report: `PASS` or `FAIL` with evidence (path, directory listing).
