# Goal 3 - Record Inline Dry-Run Preview Verification

## Expectations

Validation order (impact-first):
1. Confirm artifacts under `results/tc/03/`.
2. Use debug captures only as fallback.

Contract anchors:
- `ace-demo/docs/usage.md` dry-run behavior for `record` (planned recording + attach actions, no side effects)

1. `record-dry-run.exit` is `0`.
2. `record-dry-run.stdout` shows dry-run preview semantics for inline recording and includes
   the inline command intent (`echo hello`) without requiring exact implementation-only phrasing.
3. `record-dry-run.stdout` includes attach preview intent (`[dry-run]` + `Would attach`).

## Verdict

- **PASS**: Dry-run preview shows inline command intent and attach-preview intent.
- **FAIL**: Dry-run output is missing expected preview behaviors.
