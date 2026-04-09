# Goal 2 — List and Create Worktrees Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All capture sets exist** — results/tc/02/ contains stdout/exit for list-before, create-existing, create-new, and list-after.
2. **Target names recorded** — `target-existing.txt` and `target-new.txt` exist and identify the unique worktrees created for this run.
3. **Targets absent before creation** — `list-before.stdout` does not already include the recorded target labels.
4. **Both creations succeed** — create-existing.exit and create-new.exit are both `0`, and neither stdout capture is just the create-command usage/help text.
5. **List after shows the two recorded targets** — list-after.stdout includes the labels recorded in `target-existing.txt` and `target-new.txt`.
6. **Directories exist** — dir-listing.txt confirms the created worktree directories are present on the filesystem.

## Verdict

- **PASS**: Target worktrees were absent before creation, both creations succeed, list after shows the recorded targets, and directories exist.
- **FAIL**: Creation fails, the recorded targets are already present before creation, list doesn't reflect the new worktrees, or directories are missing.

Report: `PASS` or `FAIL` with evidence (exit codes, list output before/after, directory listing).
