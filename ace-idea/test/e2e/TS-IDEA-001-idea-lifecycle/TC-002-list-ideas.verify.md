# Goal 2 — List Ideas Verification

## Expectations

Validation order (impact-first):
1. Confirm sandbox/project state impact first.
2. Confirm explicit artifacts under `results/tc/{NN}/`.
3. Use debug evidence (`stdout`, `stderr`, `.exit`) only as fallback.

1. `ace-idea list` exit code is `0` and output includes the idea created in Goal 1 (by ID or title).
2. `ace-idea list --status pending` exit code is `0` and output includes the same idea (default status is `pending`).
3. `ace-idea list --in next` exit code is `0` and output includes the idea (default `next` scope is root).

## Verdict

- **PASS**: All three list invocations confirm correct filtering behavior.
- **FAIL**: Idea absent from unfiltered listing, wrong result from status filter, or folder filter does not exclude root ideas.
