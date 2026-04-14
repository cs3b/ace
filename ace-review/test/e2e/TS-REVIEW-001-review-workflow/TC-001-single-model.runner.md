# Goal 1 — Single Model Execution

## Goal

Execute a real review using one model with a diff subject and verify session output is produced.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `results/tc/01/execution.stdout`, `.stderr`, `.exit`
- `results/tc/01/session-listing.txt`

## Constraints

- This goal makes a real API call and requires valid provider credentials.
- Use the `single` preset from sandbox fixtures.
- All artifacts must come from real tool execution.
- Do not create synthetic helper copies of review output; rely on the actual execution result and produced session state.
