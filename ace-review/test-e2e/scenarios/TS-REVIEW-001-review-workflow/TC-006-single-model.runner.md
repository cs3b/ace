# Goal 6 — Single Model Execution

## Goal

Execute a real review using a single model (google:gemini-2.5-flash) with a diff subject. Use the `single` preset. Verify a session directory is created with review output containing meaningful content.

## Workspace

Save all output to `results/tc/06/`. Capture:
- `results/tc/06/execution.stdout`, `.stderr`, `.exit` — review execution output
- `results/tc/06/session-listing.txt` — listing of the session directory

Optional capture:
- `results/tc/06/review-output.md` — copied review output content, if a concrete output file is easy to resolve

## Constraints

- This goal makes a real API call. Requires a valid API key.
- Use the `single` preset from the sandbox fixtures.
- Using what you learned from Goal 1, invoke ace-review with the preset and a diff subject.
- Prefer `execution.*` plus `session-listing.txt` as the primary evidence. `review-output.md` is support evidence only.
- All artifacts must come from real tool execution, not fabricated.
