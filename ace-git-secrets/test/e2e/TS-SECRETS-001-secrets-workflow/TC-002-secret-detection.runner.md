# Goal 2 — Secret Detection

## Goal

Scan the repository for secrets using ace-git-secrets. The sandbox has a committed `config.env` file containing a GitHub personal access token. Verify the scanner detects it and returns a non-zero exit code.

## Workspace

Save all output to `results/tc/02/`. Capture:
- `results/tc/02/scan.stdout`, `.stderr`, `.exit` — scan command output

## Constraints

- Using what you learned from Goal 1, invoke the scan subcommand.
- The config.env fixture contains `GITHUB_TOKEN=ghp_ABCDEFghijklmnop1234567890abcdefABCD`.
- All artifacts must come from real tool execution, not fabricated.
