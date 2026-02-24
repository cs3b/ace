# Goal 4 — Delete and Rename Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations

1. **Both commit sets exist** — results/tc/04/ contains captures for delete and rename commits.
2. **Delete commit succeeds** — Exit code 0, git show shows deletion of the file.
3. **Rename commit succeeds** — Exit code 0, git show shows rename and modification.
4. **Final state correct** — Deleted file is absent, renamed file exists, keeper file contains new content.

## Verdict

- **PASS**: Both delete and rename commits succeed with correct file state.
- **FAIL**: Either commit fails, or file state is wrong.

Report: `PASS` or `FAIL` with evidence.
