# Goal 4 — Error Behavior

## Goal

Feed `ace-b36ts` clearly invalid input — unsupported subcommands or invalid arguments to valid subcommands. For each error case, capture the exit code, stdout, and stderr into separate files.

## Workspace

Save all output to `results/tc/04/`. For each error case, create a descriptive file set (for example `invalid-subcommand.exit`, `bad-count.stdout`, `bad-count.stderr`).

## Constraints

- Use only cases that the current implementation definitely rejects according to command tests and current CLI behavior.
- Include at least 2 distinct invalid cases.
- Recommended valid invalid cases:
  - invalid subcommand
  - invalid numeric argument such as `--count nope`
  - malformed token with invalid characters or invalid length for decode
- Do **not** use merely surprising-but-parseable decode inputs as an error oracle.
- Capture exit code, stdout, and stderr separately for each case. Do not merge streams.
- Do not fabricate output — all captured content must come from actual tool execution.
