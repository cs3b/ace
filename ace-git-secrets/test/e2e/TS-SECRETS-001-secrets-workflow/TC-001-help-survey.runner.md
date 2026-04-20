# Goal 1 — Help + Docs Parity Survey

## Goal

Discover the public CLI surface from `ace-git-secrets --help` and subcommand help. Record parity with `ace-git-secrets/docs/usage.md`, including whether `check-release` is discoverable and whether whitelist behavior is configuration-based rather than a dedicated CLI flag.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `results/tc/01/help.stdout`, `.stderr`, `.exit` — top-level `ace-git-secrets --help`
- `results/tc/01/scan-help.stdout`, `.stderr`, `.exit` — `ace-git-secrets scan --help`
- `results/tc/01/check-release-help.stdout`, `.stderr`, `.exit` — `ace-git-secrets check-release --help`
- `results/tc/01/observations.md` — bullet-list parity summary grounded in the captured help output

## Constraints

- Use only `ace-git-secrets` commands for interface discovery.
- Do not assume flags from prior suites; rely on observed help output.
- `observations.md` must explicitly mention these facts, preferably as separate bullets:
  - available subcommands including `check-release`
  - scan option behavior relevant to later goals (`--format`, `--report-format`, `--verbose`, `--quiet`)
  - whitelist being configured through `.ace/git-secrets/config.yml` (not a dedicated CLI flag)
