# Goal 4 - Attach PR Validation Error Verification

## Expectations

Validation order (impact-first):
1. Confirm artifacts under `results/tc/04/`.
2. Use debug captures only as fallback.

1. `attach-missing-pr.exit` is non-zero (`1` expected).
2. `attach-missing-pr.stderr` includes `PR number is required`.

## Verdict

- **PASS**: Command fails with explicit required-argument guidance.
- **FAIL**: Exit semantics or validation message are missing.
