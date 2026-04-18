# Goal 7 — Configuration Cascade (Focused)

## Goal

Verify high-value config precedence behavior with a focused matrix:
1. Default behavior without user config
2. User config affects scan behavior
3. CLI flag override supersedes user config

## Workspace

Save all output to `results/tc/07/`. Capture:
- `results/tc/07/defaults.stdout`, `.stderr`, `.exit` — scan with no `.ace/git-secrets/config.yml`
- `results/tc/07/user-config.yml` — user config written for this goal
- `results/tc/07/user-config.stdout`, `.stderr`, `.exit` — scan with user config present
- `results/tc/07/cli-override.stdout`, `.stderr`, `.exit` — scan with CLI option overriding user config

## Constraints

- Start with no user config and run baseline scan.
- Use `--verbose` on all three scans so `output.format` changes are visible in stdout.
- Create `.ace/git-secrets/config.yml` with at least one observable output-affecting setting (for example output format), then run scan.
- Run a third scan where CLI flags override the config setting. Prefer an explicit `--format table` override against a config value of `json`.
- Keep this goal focused; do not expand into unrelated config edge matrices.
- All artifacts must come from real tool execution, not fabricated.
