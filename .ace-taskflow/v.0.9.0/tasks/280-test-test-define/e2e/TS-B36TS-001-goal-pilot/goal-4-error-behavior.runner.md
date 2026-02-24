# Goal 4 — Error Behavior

## Goal

Feed `ace-b36ts` clearly invalid input — nonsense strings, wrong subcommands, missing required arguments. For each error case, capture the exit code, stdout, and stderr into separate files.

## Workspace

Save all output to `results/4/`. For each error case, create a descriptive subdirectory or file set (e.g., `results/4/nonsense-input.exit`, `results/4/nonsense-input.stdout`, `results/4/nonsense-input.stderr`).

## Constraints

- Using your knowledge of valid subcommands from Goal 1, deliberately misuse them.
- Test at least 2 distinct error cases (e.g., invalid subcommand, invalid argument to a valid subcommand).
- Capture exit code, stdout, and stderr separately for each case. Do not merge streams.
- Do not fabricate output — all captured content must come from actual tool execution.
