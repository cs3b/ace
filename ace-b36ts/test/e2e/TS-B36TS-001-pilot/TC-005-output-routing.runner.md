# Goal 5 — Output Routing

## Goal

Prove stream routing behavior for `ace-b36ts encode` across three modes: default,
quiet (`--quiet`), and verbose (`--verbose`).

## Workspace

Save all output to `results/tc/05/` using this exact naming contract:

- `default.stdout`, `default.stderr`, `default.exit`
- `quiet.stdout`, `quiet.stderr`, `quiet.exit`
- `verbose.stdout`, `verbose.stderr`, `verbose.exit`
- `routing-notes.md`

## Constraints

- Use a fixed input timestamp for all three runs:
  - `2025-01-06T12:30:00Z`
- Use the same command shape each time:
  - `ace-b36ts encode <timestamp> [mode-flag]`
- Capture stdout/stderr/exit separately for each mode.
- Write `routing-notes.md` explicitly before leaving the goal. It must compare at least one observable difference between modes.
- Do not fabricate output — all captures must come from real tool execution.
