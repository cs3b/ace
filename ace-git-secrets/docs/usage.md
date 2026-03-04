# ace-git-secrets Usage Guide

Comprehensive guide for scanning, revoking, and removing authentication tokens from Git history.

## Quick Start

```bash
# Scan repository for tokens
ace-git-secrets scan

# Revoke detected tokens
ace-git-secrets revoke

# Remove tokens from history (destructive)
ace-git-secrets rewrite-history --dry-run
```

## Commands

### scan

Scan Git history for authentication tokens.

```bash
ace-git-secrets scan [options]
```

Options:
- `--since DATE` - Start scanning from commit/date (e.g., "30 days ago", commit SHA)
- `--format, -f FORMAT` - Stdout format when --verbose is used: table, json, yaml (default: table)
- `--report-format, -r FORMAT` - Format for saved report file: json, markdown (default: json)
- `--confidence, -c LEVEL` - Minimum confidence: high, medium, low (default: low)
- `--verbose, -v` - Enable verbose output with full report to stdout
- `--quiet, -q` - Suppress non-essential output (for CI)

Examples:
```bash
# Full history scan
ace-git-secrets scan

# Scan last 30 days only
ace-git-secrets scan --since "30 days ago"

# High confidence only, verbose JSON output
ace-git-secrets scan --confidence high --format json --verbose

# Scan from merge base (for PR reviews)
ace-git-secrets scan --since "$(git merge-base main HEAD)"

# Save report in markdown format
ace-git-secrets scan --report-format markdown
```

### revoke

Revoke detected tokens via provider APIs.

```bash
ace-git-secrets revoke [options]
```

Options:
- `--service, -s NAME` - Revoke for specific service only
- `--token, -t TOKEN` - Revoke a specific token value
- `--scan-file FILE` - Use previous scan results file

Examples:
```bash
# Revoke all detected tokens
ace-git-secrets revoke

# Revoke GitHub tokens only
ace-git-secrets revoke --service github

# Revoke a specific token
ace-git-secrets revoke --token "ghp_your_token_here"

# Use previous scan results
ace-git-secrets revoke --scan-file scan-results.json
```

### rewrite-history

Remove detected tokens from Git history using git-filter-repo.

**WARNING**: This is a destructive operation that rewrites Git history.

```bash
ace-git-secrets rewrite-history [options]
```

Options:
- `--dry-run, -n` - Preview what would be rewritten
- `--backup` - Create backup before rewrite (default: true)
- `--force` - Skip confirmation prompt
- `--scan-file FILE` - Use previous scan results file

Examples:
```bash
# Preview changes (recommended first step)
ace-git-secrets rewrite-history --dry-run

# Rewrite with confirmation
ace-git-secrets rewrite-history

# Rewrite without backup (not recommended)
ace-git-secrets rewrite-history --no-backup --force
```

### check-release

Pre-release security validation check.

```bash
ace-git-secrets check-release [options]
```

Options:
- `--strict` - Fail on medium confidence matches
- `--format, -f FORMAT` - Output format: table, json

Examples:
```bash
# Standard check (fails on high confidence only)
ace-git-secrets check-release

# Strict mode (fails on medium+ confidence)
ace-git-secrets check-release --strict
```

## Configuration

Configuration uses the ACE config cascade. Create `.ace/git-secrets/config.yml`:

```yaml
# File exclusions (files that never contain secrets)
exclusions:
  - "**/package-lock.json"
  - "**/node_modules/**"

# Whitelist (will not be flagged)
whitelist:
  - pattern: 'ghp_example_for_docs'
    reason: Documentation example
  - file: 'test/fixtures/*.json'
    reason: Test fixtures

# Output settings
output:
  format: table
  mask_tokens: true
  directory: .ace-local/git-secrets

# GitHub Enterprise support
github:
  api_url: https://github.mycompany.com/api/v3
```

### Custom Gitleaks Rules

To add custom detection patterns, create `.ace/git-secrets/gitleaks.toml`:

```toml
# Extend default gitleaks rules
[extend]
useDefault = true

# Add custom rules
[[rules]]
id = "internal-api-key"
description = "Internal API Key"
regex = '''INTERNAL_[A-Za-z0-9]{32,}'''
entropy = 3.5

[[rules]]
id = "company-live-key"
description = "Company Production Key"
regex = '''mycompany_live_[A-Za-z0-9]{32,}'''
```

See [gitleaks documentation](https://github.com/gitleaks/gitleaks#configuration) for the complete rule syntax.

### Whitelist Configuration

Whitelist entries can match by pattern (exact token value) or file path:

```yaml
whitelist:
  # Match by exact token value
  - pattern: 'ghp_example123456789012345678901234567890'
    reason: Documentation example

  # Match by file path (glob patterns supported)
  - file: 'test/fixtures/*.json'
    reason: Test fixtures
  - file: 'docs/examples/*'
    reason: Example code
```

## Default Token Patterns

The following patterns are detected by default:

| Pattern | Prefix | Confidence | Service |
|---------|--------|------------|---------|
| GitHub PAT (classic) | `ghp_` | high | github |
| GitHub OAuth | `gho_` | high | github |
| GitHub App | `ghs_` | high | github |
| GitHub Refresh | `ghr_` | high | github |
| GitHub PAT (fine-grained) | `github_pat_` | high | github |
| Anthropic API Key | `sk-ant-` | high | anthropic |
| OpenAI API Key | `sk-` | high | openai |
| AWS Access Key | `AKIA` | high | aws |
| AWS Session | `ASIA` | medium | aws |

## Token Revocation

### Automatic Revocation

GitHub tokens can be revoked automatically via API (no authentication required):

```bash
# Revokes all detected GitHub tokens
ace-git-secrets revoke --service github
```

### Manual Revocation

Other providers require manual revocation:

| Service | Action |
|---------|--------|
| Anthropic | Visit https://console.anthropic.com/settings/keys |
| OpenAI | Visit https://platform.openai.com/api-keys |
| AWS | Visit https://console.aws.amazon.com/iam/home#/security_credentials |

## History Rewriting

### Prerequisites

1. Install git-filter-repo:
   ```bash
   brew install git-filter-repo
   ```

2. Commit or stash all changes (working directory must be clean)

3. **Revoke tokens first** before rewriting history

### Workflow

1. **Scan and save results**:
   ```bash
   ace-git-secrets scan --format json > tokens.json
   ```

2. **Revoke tokens**:
   ```bash
   ace-git-secrets revoke --scan-file tokens.json
   ```

3. **Preview rewrite**:
   ```bash
   ace-git-secrets rewrite-history --dry-run --scan-file tokens.json
   ```

4. **Execute rewrite**:
   ```bash
   ace-git-secrets rewrite-history --scan-file tokens.json
   ```

5. **Force push**:
   ```bash
   git push --force-with-lease origin <branch>
   ```

6. **Notify collaborators** to re-clone the repository

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success (or no tokens found) |
| 1 | Tokens found or partial failure |
| 2 | Error (configuration, I/O, etc.) |

## Integration with CI/CD

### Pre-release Check

```yaml
# .github/workflows/security.yml
jobs:
  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for scanning

      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true

      - name: Check for secrets
        run: ace-git-secrets check-release --strict
```

### PR Review Check

```yaml
- name: Scan PR changes only
  run: |
    ace-git-secrets scan --since "${{ github.event.pull_request.base.sha }}"
```

## Performance Tips

- Use `--since` to limit history scanning for large repositories
- gitleaks is highly optimized for scanning large repositories
- For very large repos, consider scanning only recent history: `--since "6 months ago"`

## Troubleshooting

### "git-filter-repo is required"

Install with: `brew install git-filter-repo`

### "Working directory has uncommitted changes"

Commit or stash changes before running `rewrite-history`.

### Scan is slow on large repositories

Use `--since` to limit the scan scope:
```bash
ace-git-secrets scan --since "6 months ago"
```

### False positives

Add patterns or files to the whitelist in configuration.
