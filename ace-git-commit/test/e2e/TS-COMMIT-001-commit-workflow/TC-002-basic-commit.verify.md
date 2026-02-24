# Goal 2 — Basic Commit Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Artifacts exist** — results/tc/02/ contains stdout/exit captures and git log/show output.
2. **Zero exit code** — The commit command exited successfully.
3. **Commit created** — Git log shows a new commit with the specified message.
4. **Files included** — Git show --stat shows the modified file(s) in the commit.

## Verdict

- **PASS**: Commit created successfully with correct message and files.
- **FAIL**: Non-zero exit, no commit, or wrong files.

Report: `PASS` or `FAIL` with evidence (exit code, commit message, file list).
