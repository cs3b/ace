# Goal 4 — Switch by Task ID Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Switch artifacts exist** — results/tc/04/ contains stdout/exit for switch-task.
2. **Switch succeeds** — switch-task.exit is 0 and stdout contains a filesystem path.
3. **Path is valid** — path-check.txt confirms the returned path exists as a directory.
4. **Taskflow present** — taskflow-check.txt shows .ace-taskflow directory contents in the worktree.

## Verdict

- **PASS**: Switch by task ID returns a valid path to a worktree containing taskflow files.
- **FAIL**: Switch fails, path invalid, or taskflow directory missing from the worktree.

Report: `PASS` or `FAIL` with evidence (path, directory listing).
