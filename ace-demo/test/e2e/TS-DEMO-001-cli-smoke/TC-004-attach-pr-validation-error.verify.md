# Goal 4 - Attach PR Validation Error Verification

## Expectations

Validation order (impact-first):
1. Confirm artifacts under `results/tc/04/`.
2. Use debug captures only as fallback.

Contract anchors:
- `ace-demo/docs/usage.md` attach command requires `--pr`

1. `attach-missing-pr.exit` is non-zero (`1` expected).
2. `attach-missing-pr.stderr` includes required-argument guidance mentioning both `PR`
   and `--pr` (exact full sentence is not required).

## Verdict

- **PASS**: Command fails with explicit required-argument guidance.
- **FAIL**: Exit semantics or validation message are missing.
