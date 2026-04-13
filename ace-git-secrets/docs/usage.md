---
doc-type: user
title: ace-git-secrets Usage Guide
purpose: CLI reference for ace-git-secrets
ace-docs:
  last-updated: 2026-03-22
  last-checked: 2026-03-22
---

# ace-git-secrets Usage Guide

Reference for scanning, revoking, and removing leaked credentials from Git history.

## Quick Start

Run a scan first and keep the saved JSON report path:

```bash
ace-git-secrets scan
```

Then use that saved report for the rest of the remediation flow:

```bash
ace-git-secrets revoke --scan-file .ace-local/git-secrets/sessions/<id>-report.json
ace-git-secrets rewrite-history --dry-run --scan-file .ace-local/git-secrets/sessions/<id>-report.json
ace-git-secrets rewrite-history --scan-file .ace-local/git-secrets/sessions/<id>-report.json
```

## Commands

### scan

Scan Git history for authentication tokens.

```bash
ace-git-secrets scan [OPTIONS]
```

Behavior:

- Summary output goes to stdout by default
- A full report is always saved to `.ace-local/git-secrets/sessions/`
- The saved JSON report includes raw token values needed by `revoke` and `rewrite-history`

Options:

- `--since=VALUE` - Start scanning from a commit or date
- `--format=VALUE, -f` - Stdout format when `--verbose` is enabled: `table`, `json`, `yaml`
- `--report-format=VALUE, -r` - Saved report format: `json`, `markdown`
- `--confidence=VALUE, -c` - Minimum confidence: `high`, `medium`, `low`
- `--[no-]verbose` - Print the full report to stdout in addition to saving it
- `--[no-]quiet, -q` - Suppress non-essential output for CI-style usage
- `--[no-]debug` - Show debug output

Examples:

```bash
# Scan full history
ace-git-secrets scan

# Scan recent history only
ace-git-secrets scan --since "30 days ago"

# Review only high-confidence findings in verbose JSON
ace-git-secrets scan --confidence high --verbose --format json

# Save a human-readable report as Markdown instead of JSON
ace-git-secrets scan --report-format markdown

# Minimal output for automation
ace-git-secrets scan --quiet
```

### revoke

Revoke detected tokens via provider APIs.

```bash
ace-git-secrets revoke [OPTIONS]
```

Options:

- `--service=VALUE, -s` - Revoke for one provider only
- `--token=VALUE, -t` - Revoke one explicit token value
- `--scan-file=VALUE` - Load tokens from a saved scan report
- `--[no-]debug` - Show debug output

Examples:

```bash
# Revoke all high-confidence tokens from a fresh scan
ace-git-secrets revoke

# Revoke only GitHub tokens from a saved scan report
ace-git-secrets revoke --service github --scan-file .ace-local/git-secrets/sessions/<id>-report.json

# Revoke one token directly
ace-git-secrets revoke --token "ghp_example_token"
```

Notes:

- `--scan-file` expects the saved JSON report produced by `scan`
- Redirecting verbose stdout to a file is not a supported substitute, because `revoke` requires `raw_value` fields
- If the scan file is missing `raw_value`, re-run `ace-git-secrets scan` and use the saved report path it prints

### rewrite-history

Remove detected tokens from Git history.

```bash
ace-git-secrets rewrite-history [OPTIONS]
```

`rewrite-history` is destructive. Run it only after revoking the exposed credentials and after previewing the result with
`--dry-run`.

Options:

- `--[no-]dry-run, -n` - Show what would be rewritten without modifying history
- `--[no-]backup` - Create a backup before rewriting (enabled by default)
- `--[no-]force` - Skip the confirmation prompt
- `--scan-file=VALUE` - Load tokens from a saved scan report
- `--[no-]debug` - Show debug output

Examples:

```bash
# Preview cleanup first
ace-git-secrets rewrite-history --dry-run --scan-file .ace-local/git-secrets/sessions/<id>-report.json

# Rewrite history using the same saved report used for revocation
ace-git-secrets rewrite-history --scan-file .ace-local/git-secrets/sessions/<id>-report.json

# Rewrite without a prompt
ace-git-secrets rewrite-history --force --scan-file .ace-local/git-secrets/sessions/<id>-report.json
```

Before running the real rewrite:

- install `git-filter-repo`
- start from a clean working tree
- keep a mirror or clone backup for recovery

### check-release

Run the pre-release security gate.

```bash
ace-git-secrets check-release [OPTIONS]
```

Options:

- `--[no-]strict` - Fail on medium-confidence matches in addition to high-confidence matches
- `--format=VALUE, -f` - Output format: `table`, `json`
- `--[no-]debug` - Show debug output

Examples:

```bash
# Standard release gate
ace-git-secrets check-release

# Stricter release gate for CI
ace-git-secrets check-release --strict

# Structured review output
ace-git-secrets check-release --format json
```

Prefer exit codes for automation. `check-release --format json` currently includes banner text, so it is better suited to
inspection than strict machine parsing.

## Configuration

Configuration follows the ACE cascade. Project overrides live in `.ace/git-secrets/config.yml`.

```yaml
exclusions:
  - "**/node_modules/**"
  - "**/vendor/**"

whitelist:
  - pattern: "ghp_example_for_docs"
    reason: "Documentation example"
  - file: "test/fixtures/*.json"
    reason: "Test fixtures"

output:
  format: table
  mask_tokens: true
  directory: .ace-local/git-secrets

github:
  api_url: https://github.mycompany.com/api/v3
```

Use whitelist rules for known safe examples or fixtures. Keep real credentials out of the whitelist and revoke them
instead.

## Common Workflows

### Full remediation loop

1. Scan and note the saved report path:

   ```bash
   ace-git-secrets scan
   ```

2. Revoke from the saved JSON report:

   ```bash
   ace-git-secrets revoke --scan-file .ace-local/git-secrets/sessions/<id>-report.json
   ```

3. Preview history rewriting:

   ```bash
   ace-git-secrets rewrite-history --dry-run --scan-file .ace-local/git-secrets/sessions/<id>-report.json
   ```

4. Rewrite history for real:

   ```bash
   ace-git-secrets rewrite-history --scan-file .ace-local/git-secrets/sessions/<id>-report.json
   ```

5. Re-scan or run the release gate:

   ```bash
   ace-git-secrets check-release --strict
   ```

### Human-readable reporting

Generate a Markdown report when you need to share findings with reviewers:

```bash
ace-git-secrets scan --report-format markdown
```

### Faster large-repository scans

Limit the scan scope for triage work:

```bash
ace-git-secrets scan --since "6 months ago"
```

## Package Test Commands

Use the package-level test contract when validating this gem:

- `ace-test ace-git-secrets` for deterministic `test/fast` coverage
- `ace-test ace-git-secrets feat` for deterministic `test/feat` coverage when present
- `ace-test ace-git-secrets all` for full package deterministic coverage
- `ace-test-e2e ace-git-secrets` for retained workflow scenarios in `test/e2e`

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success, or no tokens found for scan/check workflows |
| `1` | Tokens found, or partial revocation success/failure |
| `2` | Command error such as missing dependencies, invalid input, or I/O failure |

## Troubleshooting

### "gitleaks is required"

Install the scanner and re-run:

```bash
brew install gitleaks
```

### "git-filter-repo is required"

Install the rewrite tool before using `rewrite-history`:

```bash
brew install git-filter-repo
```

### Scan file missing `raw_value`

Re-run `scan` and use the saved JSON report path that the command prints. Do not build the `--scan-file` input by
redirecting verbose stdout.

### Scan is slow on a large repository

Limit the scan window:

```bash
ace-git-secrets scan --since "30 days ago"
```

### False positives

Add a whitelist entry for known safe examples or fixtures in `.ace/git-secrets/config.yml`.

## Related Docs

- [Getting Started](getting-started.md)
- [Handbook Catalog](handbook.md)
- Runtime help: `ace-git-secrets --help`
