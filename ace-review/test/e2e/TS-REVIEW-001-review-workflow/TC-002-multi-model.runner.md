# Goal 2 — Multi-Model and Reviewers Format

## Goal

Execute review flows using both multi-model preset format and reviewers-array preset format through documented
CLI paths, then confirm both produce meaningful output sessions.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/multi.stdout`, `.stderr`, `.exit`
- `results/tc/02/reviewers.stdout`, `.stderr`, `.exit`
- `results/tc/02/multi-session-listing.txt`
- `results/tc/02/reviewers-session-listing.txt`

## Constraints

- This goal makes real API calls and requires valid provider credentials.
- Use command patterns discoverable from `ace-review/docs/usage.md` and `ace-review --help`.
- Use `multi` and `reviewers-test` presets from sandbox fixtures.
- Review the sandbox's actual user-visible change by providing an explicit subject such as
  `--subject diff:HEAD~1..HEAD` for both commands; do not rely on any implicit/default review target.
- Persist the full capture set for each command before moving to the next one. In particular, both
  `results/tc/02/multi.exit` and `results/tc/02/reviewers.exit` must be written even when a command fails.
- After each review command completes, write its `.stdout`, `.stderr`, and `.exit` files immediately before
  collecting session listings or starting the next command.
- If a command prints no terminal output, still persist an empty `.stdout` or `.stderr` file alongside the `.exit`.
- All artifacts must come from real tool execution.
