# Goal 5 — Auto-Split Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Artifacts exist** — results/tc/05/ contains git log and git show captures.
2. **Two commits created** — Git log shows two new commits (not just one).
3. **Separate scopes** — Each commit contains files from only one package (pkg-a or pkg-b, not both).

## Verdict

- **PASS**: Two separate commits created, each containing files from a single package scope.
- **FAIL**: Single commit with both packages, or wrong number of commits.

Report: `PASS` or `FAIL` with evidence (commit log, file lists per commit).
