# Goal 6 — No-Split Override Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Artifacts exist** — results/tc/06/ contains git log and git show captures.
- **Single commit** — Git log shows exactly one new commit.
- **Both packages** — Git show --stat shows files from both pkg-a and pkg-b in the same commit.

## Verdict

- **PASS**: Single commit contains files from both package scopes.
- **FAIL**: Multiple commits, or only one package's files in the commit.

Report: `PASS` or `FAIL` with evidence (commit log, file list).
