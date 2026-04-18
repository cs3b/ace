# Goal 1 — Single Model Execution

## Goal

Execute a real review using one model with a documented CLI path and verify meaningful review output is
produced.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `results/tc/01/execution.stdout`, `.stderr`, `.exit`
- `results/tc/01/session-listing.txt`

## Constraints

- This goal makes a real API call and requires valid provider credentials.
- Use a command path discoverable from `ace-review/docs/usage.md` and `ace-review --help`.
- Use the `single` preset from sandbox fixtures only as backing config, not as a hidden recipe.
- Review the sandbox's actual user-visible change by providing an explicit subject such as
  `--subject diff:HEAD~1..HEAD`; do not rely on any implicit/default review target.
- All artifacts must come from real tool execution.
- Do not create synthetic helper copies of review output; rely on the actual execution result and produced session state.
