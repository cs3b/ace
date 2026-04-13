# Goal 2 — Multi-Model and Reviewers Format

## Goal

Execute review flows using both multi-model preset format and reviewers-array preset format, then confirm both produce output sessions.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/multi.stdout`, `.stderr`, `.exit`
- `results/tc/02/reviewers.stdout`, `.stderr`, `.exit`
- `results/tc/02/multi-session-listing.txt`
- `results/tc/02/reviewers-session-listing.txt`

## Constraints

- This goal makes real API calls and requires valid provider credentials.
- Use `multi` and `reviewers-test` presets from sandbox fixtures.
- All artifacts must come from real tool execution.
