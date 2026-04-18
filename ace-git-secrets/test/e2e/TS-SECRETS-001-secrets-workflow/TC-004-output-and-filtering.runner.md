# Goal 4 — Output Report + Whitelist Impact

## Goal

Validate two public outcomes:
1. The scan workflow produces a saved JSON report with expected structure.
2. Whitelist configuration filters fixture paths while non-whitelisted secrets still trigger findings.

## Workspace

Save all output to `results/tc/04/`. Capture:
- `results/tc/04/json-scan.stdout`, `.stderr`, `.exit` — scan run used to produce report artifacts
- `results/tc/04/saved-report.path` — absolute/relative path to the saved report used for verification
- `results/tc/04/saved-report.json` — copy of the saved report JSON
- `results/tc/04/whitelist-scan.stdout`, `.stderr`, `.exit` — scan run after whitelist config is applied
- `results/tc/04/whitelist-config.yml` — exact config file content used for whitelist test

## Constraints

- Use real `ace-git-secrets scan` execution; do not fabricate report artifacts.
- For JSON/report validation, use options discovered in Goal 1 (`--report-format json` and optional `--verbose --format json`).
- Resolve the report path from scan output or `.ace-local/git-secrets/sessions/`, then copy that file into `results/tc/04/saved-report.json`.
- For whitelist behavior, create `.ace/git-secrets/config.yml` with a file whitelist rule for `test/**` and preserve that exact YAML in `results/tc/04/whitelist-config.yml`.
- Whitelist outcome should still detect the non-whitelisted secret in `config.env`.
