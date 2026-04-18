# Goal 7 — Only-Staged Contract Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox
path.

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Artifacts exist** — `results/tc/07/` contains status snapshots, command
  captures, and commit evidence.
- **Zero exit code** — command exit capture is `0`.
- **Only staged committed** — `git show --stat HEAD` includes the staged file
  and does not include the intentionally unstaged file.
- **Unstaged preserved** — post-command `git status --short` still shows the
  intentionally unstaged modification.

## Verdict

- **PASS**: Commit contains only staged file(s), and unstaged modifications
  remain in working tree after commit.
- **FAIL**: Unstaged file was committed, or unstaged changes were cleared.

Report: `PASS` or `FAIL` with evidence (exit code, status captures, commit
stat).
