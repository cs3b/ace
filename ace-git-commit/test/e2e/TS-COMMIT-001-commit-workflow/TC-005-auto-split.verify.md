# Goal 5 — Auto-Split Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Artifacts exist** — `results/tc/05/` contains setup evidence, command
  captures, and git log/show captures.
- **Zero exit code** — command exit capture is `0`.
- **Split behavior is evidenced** — command output or git history shows at least
  two scoped commits attributable to this goal; do not require an exact log-line
  count because baseline entries may also be present in the capture.
- **Separate scopes** — `git show --stat` for each commit contains files from
  only one package (`pkg-a` or `pkg-b`), not both in the same commit.

## Verdict

- **PASS**: Split commit behavior is visible and each scoped commit contains files
  from only one package scope.
- **FAIL**: Single commit with both packages, or scoped separation is not evidenced.

Report: `PASS` or `FAIL` with evidence (commit log, file lists per commit).
