# Goal 2 — Basic Commit Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Artifacts exist** — results/tc/02/ contains stdout/exit captures plus SHA/log/show output.
- **Zero exit code** — The commit command exited successfully.
- **Commit created** — The captured SHA is non-empty and git log shows a new commit with the specified message.
- **Files included** — Git show for the captured SHA shows the modified file(s) in the commit.

## Verdict

- **PASS**: Commit created successfully with correct message and files.
- **FAIL**: Non-zero exit, no commit, or wrong files.

Report: `PASS` or `FAIL` with evidence (exit code, commit message, file list).
