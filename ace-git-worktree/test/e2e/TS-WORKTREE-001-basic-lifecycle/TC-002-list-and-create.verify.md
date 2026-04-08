# Goal 2 — List and Create Worktrees Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
1. **All capture sets exist** — results/tc/02/ contains stdout/exit for list-before, create-existing, create-new, and list-after.
2. **List before shows main only** — list-before.stdout shows the main worktree and no others.
3. **Both creations succeed** — create-existing.exit and create-new.exit are both `0`, and neither stdout capture is just the create-command usage/help text.
4. **List after shows all worktrees** — list-after.stdout shows main plus the two newly created worktrees.
5. **Directories exist** — dir-listing.txt confirms the created worktree directories are present on the filesystem.

## Verdict

- **PASS**: List starts with main only, both creations succeed, list after shows all three worktrees, directories exist.
- **FAIL**: Creation fails, list doesn't reflect new worktrees, or directories missing.

Report: `PASS` or `FAIL` with evidence (exit codes, list output before/after, directory listing).
