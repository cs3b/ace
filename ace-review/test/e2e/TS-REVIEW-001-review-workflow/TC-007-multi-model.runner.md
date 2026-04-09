# Goal 7 — Multi-Model and Reviewers Format

## Goal

Execute reviews using two different preset formats: (1) the `multi` preset which uses a models array with multiple model entries, and (2) the `reviewers-test` preset which uses named reviewer objects with individual models. Verify both produce output files.

## Workspace

Save all output to `results/tc/07/`. Capture:
- `results/tc/07/multi.stdout`, `.stderr`, `.exit` — multi-model execution
- `results/tc/07/reviewers.stdout`, `.stderr`, `.exit` — reviewers format execution
- `results/tc/07/multi-session-listing.txt`
- `results/tc/07/reviewers-session-listing.txt`

Optional capture:
- `results/tc/07/multi-review-output.md`
- `results/tc/07/reviewers-review-output.md`

## Constraints

- Both goals make real API calls. Requires valid API keys.
- Use the `multi` and `reviewers-test` presets from the sandbox fixtures.
- Prefer execution captures plus session listings as the primary evidence. Copied review outputs are support evidence only.
- All artifacts must come from real tool execution, not fabricated.
