# Goal 4 — Delete and Rename Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Both commit sets exist** — results/tc/04/ contains captures for delete and rename commits.
- **Delete commit succeeds** — Exit code 0, git show shows deletion of the file.
- **Rename commit succeeds** — Exit code 0, and commit/stat output shows the intended rename-or-add path plus the keeper modification.
- **Final state correct** — explicit final-state artifacts are the primary oracle: they show the deleted file is absent, the renamed file exists, and `keeper.rb` contains the new content.

## Verdict

- **PASS**: Both delete and rename commits succeed with correct file state.
- **FAIL**: Either commit fails, or file state is wrong.

Report: `PASS` or `FAIL` with evidence.
