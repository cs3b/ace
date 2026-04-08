# Goal 4 — Delete and Rename Verification

## Injected Context

The verifier receives the `results/` directory tree and access to the sandbox path.

## Expectations


Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.
- **Both commit sets exist** — results/tc/04/ contains captures for delete and rename commits, including SHA captures.
- **Delete commit succeeds** — Exit code 0, captured delete SHA is non-empty, and git show for that SHA shows deletion of the file.
- **Rename commit succeeds** — Exit code 0, captured rename SHA is non-empty, and git show for that SHA shows rename and modification.
- **Final state correct** — Deleted file is absent, renamed file exists, keeper file contains new content.

## Verdict

- **PASS**: Both delete and rename commits succeed with correct file state.
- **FAIL**: Either commit fails, or file state is wrong.

Report: `PASS` or `FAIL` with evidence.
