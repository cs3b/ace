# Goal 7 — Configuration Cascade

## Goal

Test the configuration cascade: (1) tool works with defaults when no user config exists, (2) user config in `.ace/` overrides defaults, (3) CLI flags take highest priority, (4) missing or empty configs are handled gracefully.

## Workspace

Save all output to `results/tc/07/`. Capture:
- `results/tc/07/defaults.stdout`, `.stderr`, `.exit` — scan with no user config
- `results/tc/07/user-config.stdout`, `.stderr`, `.exit` — scan with user config
- `results/tc/07/cli-override.stdout`, `.stderr`, `.exit` — scan with CLI flag override
- `results/tc/07/empty-config.stdout`, `.stderr`, `.exit` — scan with empty config file

## Constraints

- For defaults: ensure no `.ace/` config exists, run scan.
- For user config: create `.ace/git-secrets/config.yml` with custom settings, run scan.
- For CLI override: use a CLI flag (e.g., --format) that overrides the user config setting.
- For empty config: create an empty `.ace/git-secrets/config.yml`, run scan.
- All artifacts must come from real tool execution, not fabricated.
