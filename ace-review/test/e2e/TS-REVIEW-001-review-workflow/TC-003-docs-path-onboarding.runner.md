# Goal 3 — Docs Path Onboarding

## Goal

Prove a user can discover and run a real `ace-review` workflow from public docs/help without hidden recipes.

## Workspace

Save all output to `results/tc/03/`. Capture:
- `results/tc/03/help.stdout`
- `results/tc/03/help.stderr`
- `results/tc/03/help.exit`
- `results/tc/03/docs-path.stdout`
- `results/tc/03/docs-path.stderr`
- `results/tc/03/docs-path.exit`
- `results/tc/03/session-listing.txt`

## Constraints

- This goal starts from public documentation and runtime help:
  - `ace-review/docs/usage.md`
  - `ace-review --help`
- Capture `ace-review --help` first and persist `results/tc/03/help.stdout`, `.stderr`, and `.exit` before running the docs-path command.
- Use a command pattern documented in usage/help.
- This goal makes a real API call and requires valid provider credentials.
- Persist `results/tc/03/docs-path.stdout`, `.stderr`, and `.exit` immediately after the docs-path command, before gathering `session-listing.txt`.
- If the docs-path command produces no terminal output, still write empty `.stdout` / `.stderr` files and the numeric `.exit`.
- All artifacts must come from real tool execution.
- Do not treat provider/model unavailability as success.
