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
3. **Path is valid** — `path-check.txt` confirms the returned path exists as a directory.
4. **Path is publicly discoverable** — `path-check.txt` or `switch-list.stdout` confirms the same path appears in `ace-git-worktree switch --list`.
5. **Task files check is optional diagnostic** — absence of deeper layout evidence must not fail the goal if the path exists and is listed publicly.

## Verdict

- **PASS**: Switch by task ID returns a valid directory path and the same path is confirmed by `switch --list`.
- **FAIL**: Switch fails, returns a non-directory path, or the returned path is not confirmed by the public list output.

Report: `PASS` or `FAIL` with evidence (returned path, directory check, and list output).
