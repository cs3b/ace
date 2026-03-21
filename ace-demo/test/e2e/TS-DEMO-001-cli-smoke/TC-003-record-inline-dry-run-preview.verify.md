# Goal 3 - Record Inline Dry-Run Preview Verification

## Expectations

Validation order (impact-first):
1. Confirm artifacts under `results/tc/03/`.
2. Use debug captures only as fallback.

1. `record-dry-run.exit` is `0`.
2. `record-dry-run.stdout` includes generated tape-preview content (`Type "echo hello"`).
3. `record-dry-run.stdout` includes attach preview text (`[dry-run] Would attach`).

## Verdict

- **PASS**: Dry-run preview shows both inline tape content and attach-preview intent.
- **FAIL**: Dry-run output is missing expected preview behaviors.
