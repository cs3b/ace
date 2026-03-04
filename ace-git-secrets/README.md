# ace-git-secrets

Detect, remove, and revoke authentication tokens from Git history.

## Overview

`ace-git-secrets` provides CLI tools for:

1. **Scanning** Git history for leaked authentication tokens (GitHub PATs, API keys, AWS credentials)
2. **Removing** detected tokens from Git history using git-filter-repo
3. **Revoking** compromised tokens via provider APIs
4. **Blocking** releases if tokens are detected (CI/CD integration)

## Installation

Add to your Gemfile:

```ruby
gem 'ace-git-secrets'
```

Or install directly:

```bash
gem install ace-git-secrets
```

### Required Dependencies

**gitleaks** is required for token detection:

```bash
brew install gitleaks
```

For history rewriting, install **git-filter-repo**:

```bash
brew install git-filter-repo
```

## Usage

### Scan for Tokens

```bash
# Scan entire Git history
ace-git-secrets scan

# Scan with specific confidence level
ace-git-secrets scan --confidence high

# Verbose output as JSON to stdout (report also saved to file)
ace-git-secrets scan --verbose --format json

# Save report in markdown format (default is json)
ace-git-secrets scan --report-format markdown

# Scan commits since a specific point
ace-git-secrets scan --since "2024-01-01"

# Enable verbose output for debugging
ace-git-secrets scan --verbose

# Quiet mode for CI pipelines (only errors and exit code)
ace-git-secrets scan --quiet
```

### Remove Tokens from History

```bash
# Preview what would be removed (dry run)
ace-git-secrets rewrite-history --dry-run

# Remove tokens (requires confirmation)
ace-git-secrets rewrite-history

# Skip backup (not recommended)
ace-git-secrets rewrite-history --no-backup
```

### Revoke Tokens

```bash
# Revoke all detected tokens
ace-git-secrets revoke

# Revoke specific service only
ace-git-secrets revoke --service github

# Revoke a specific token
ace-git-secrets revoke --token "ghp_..."
```

### Pre-Release Check

```bash
# CI/CD gate - exits 1 if tokens found
ace-git-secrets check-release

# Strict mode (fail on medium confidence too)
ace-git-secrets check-release --strict
```

## Supported Token Types

gitleaks includes 100+ actively maintained patterns. Common types include:

| Token Type | Pattern | Confidence |
|------------|---------|------------|
| GitHub PAT (classic) | `ghp_*` | High |
| GitHub OAuth | `gho_*` | High |
| GitHub App | `ghs_*` | High |
| GitHub Refresh | `ghr_*` | High |
| GitHub Fine-grained | `github_pat_*` | High |
| Anthropic API Key | `sk-ant-*` | High |
| OpenAI API Key | `sk-*` | High |
| AWS Access Key | `AKIA*` | High |
| AWS Session | `ASIA*` | Medium |
| Google API Key | `AIza*` | High |
| Slack Token | `xox*` | High |
| NPM Token | `npm_*` | High |

See [gitleaks rules](https://github.com/gitleaks/gitleaks/tree/master/config) for the complete pattern list.

## Configuration

Create `.ace/git-secrets/config.yml`:

```yaml
# File exclusions (files that never contain secrets)
exclusions:
  - "**/package-lock.json"
  - "**/node_modules/**"
  - "**/vendor/**"

# Whitelist false positives
whitelist:
  - pattern: 'ghp_example_for_docs'
    reason: Documentation example
  - file: 'test/fixtures/mock_tokens.json'
    reason: Test fixtures

# Output settings
output:
  format: table
  mask_tokens: true
  directory: .ace-local/git-secrets
```

### Custom Gitleaks Rules

To customize detection patterns, create `.ace/git-secrets/gitleaks.toml`:

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
```

## Security Workflow

For a complete guided workflow, see `wfi://git/token-remediation` (use `ace-nav wfi://git/token-remediation`).

### Recommended Steps

1. **Scan** - Detect tokens in history
   ```bash
   ace-git-secrets scan
   # Report saved to .ace-local/git-secrets/
   ```

2. **Revoke** - Invalidate compromised tokens immediately
   ```bash
   ace-git-secrets revoke
   ```

3. **Rewrite** - Remove tokens from history
   ```bash
   ace-git-secrets rewrite-history
   ```

4. **Push** - Force push cleaned history
   ```bash
   git push --force-with-lease origin main
   ```

5. **Notify** - Tell collaborators to re-clone

### CI/CD Integration

Add to your release workflow:

```yaml
- name: Security Check
  run: ace-git-secrets check-release --strict
```

Use `--quiet` flag for cleaner CI logs:

```yaml
- name: Security Scan
  run: ace-git-secrets scan --quiet
  # Exit code 1 if tokens found, 0 if clean
```

## Development

```bash
# Run tests
ace-test

# Run specific test file
ace-test test/atoms/gitleaks_runner_test.rb
```

## Architecture

Follows ATOM pattern:

- **Atoms**: Pure functions (GitleaksRunner, ServiceApiClient)
- **Molecules**: Composed operations (HistoryScanner, GitRewriter, TokenRevoker)
- **Organisms**: Business logic (SecurityAuditor, HistoryCleaner, ReleaseGate)
- **Models**: Data structures (DetectedToken, ScanReport, RevocationResult)

## License

MIT
