# Goal 5 — Output Routing

## Goal

Run the same encode operation in different verbosity modes. Discover available modes via `--help`. For each mode, capture stdout and stderr into separate files to prove that output streams are routed correctly.

## Workspace

Save all output to `goal/5/`. Use descriptive filenames that identify the mode and stream (e.g., `goal/5/quiet.stdout`, `goal/5/quiet.stderr`, `goal/5/verbose.stdout`, `goal/5/verbose.stderr`).

## Constraints

- Use `--help` to discover what verbosity or output modes the tool supports. Do not assume flag names.
- Test at least 2 distinct modes (e.g., quiet/default, or quiet/verbose).
- Capture stdout and stderr separately for each mode — do not merge streams.
- Do not fabricate output — all captured content must come from actual tool execution.
