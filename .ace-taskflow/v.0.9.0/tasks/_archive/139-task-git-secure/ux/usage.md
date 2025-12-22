# ace-security Usage Documentation

## Overview

`ace-security` is a CLI tool for detecting, removing, and revoking authentication tokens from Git repository history. It provides a comprehensive security workflow for ensuring credentials are not exposed when publishing gems or pushing to public repositories.

## Available Commands

| Command | Purpose |
|---------|---------|
| `ace-security scan` | Scan Git history for authentication tokens |
| `ace-security rewrite-history` | Remove detected tokens from Git history |
| `ace-security revoke` | Revoke detected tokens via provider APIs |
| `ace-security check-release` | Pre-release security validation check |

## Command Structure

### Basic Invocation

```bash
# Scan current repository
ace-security scan

# Scan with custom patterns
ace-security scan --patterns ~/.ace/security/custom-patterns.yml

# Dry-run history rewrite
ace-security rewrite-history --dry-run

# Execute history rewrite with confirmation
ace-security rewrite-history

# Revoke tokens for specific service
ace-security revoke --service github

# Pre-release check (blocks on findings)
ace-security check-release
```

## Usage Scenarios

### Scenario 1: Pre-Release Security Audit

**Goal**: Ensure no tokens exist in Git history before publishing a gem.

```bash
# Step 1: Run comprehensive scan
$ ace-security scan

Scanning Git history for authentication tokens...
Repository: /Users/mc/Ps/ace-meta
Commits analyzed: 1,247

FINDINGS:
- 2 GitHub PAT tokens detected
- 1 Anthropic API key detected

Token Summary:
+--------+-------------------+-----------+---------------+-------------+
| Type   | Pattern           | Commit    | File          | Confidence  |
+--------+-------------------+-----------+---------------+-------------+
| GitHub | ghp_************* | a1b2c3d   | .env.example  | HIGH        |
| GitHub | gho_************* | d4e5f6g   | config/test   | HIGH        |
| LLM    | sk-ant-**********| h7i8j9k   | scripts/test  | HIGH        |
+--------+-------------------+-----------+---------------+-------------+

Run 'ace-security rewrite-history' to remove these tokens.
Run 'ace-security revoke' to invalidate the tokens.

# Step 2: Review and revoke tokens first
$ ace-security revoke --service github

Revoking GitHub tokens...
Token ghp_***: REVOKED (logged to audit)
Token gho_***: REVOKED (logged to audit)

# Step 3: Rewrite history to remove tokens
$ ace-security rewrite-history

WARNING: This operation will rewrite Git history.
- This is IRREVERSIBLE
- All collaborators must re-clone after this
- Backup recommended: git clone --mirror repo.git backup.git

Type 'REWRITE HISTORY' to confirm: REWRITE HISTORY

Rewriting history...
Using git-filter-repo to remove 3 tokens from history...
Progress: 1247/1247 commits processed
History rewritten successfully.

IMPORTANT: Force push required:
  git push --force-with-lease origin main
```

### Scenario 2: CI/CD Pre-Release Gate

**Goal**: Block releases if tokens are detected in history.

```bash
# In CI pipeline (GitHub Actions, etc.)
$ ace-security check-release

Performing pre-release security check...
Repository: /Users/mc/Ps/ace-meta
Branch: main

Scanning for authentication tokens...
No tokens detected in Git history.

Pre-release check: PASSED
```

If tokens are found:
```bash
$ ace-security check-release

SECURITY CHECK FAILED

3 authentication tokens detected in Git history.
Release blocked until tokens are removed.

Run 'ace-security scan' for details.
Exit code: 1
```

### Scenario 3: Custom Pattern Configuration

**Goal**: Add organization-specific token patterns.

```yaml
# .ace/security/patterns.yml
patterns:
  - name: internal_api_key
    regex: 'INTERNAL_[A-Z0-9]{32}'
    description: Internal API keys
    confidence: high

  - name: aws_session
    regex: 'ASIA[A-Z0-9]{16}'
    description: AWS session tokens
    confidence: medium
```

```bash
$ ace-security scan --patterns .ace/security/patterns.yml

Using custom patterns from .ace/security/patterns.yml
Added 2 custom patterns

Scanning...
1 internal_api_key detected (high confidence)
```

### Scenario 4: Integration with ace-taskflow Release

**Goal**: Automatic security check during release workflow.

The `ace-security check-release` command integrates with `publish-release.wf.md`:

```markdown
### 1. Pre-Publish Validation

4. **Run Security Checks:**
   - Execute: `ace-security check-release`
   - Verify no tokens in Git history
   - Address any findings before proceeding
```

## Command Reference

### ace-security scan

Scan Git history for authentication tokens.

**Syntax:**
```bash
ace-security scan [OPTIONS]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--patterns FILE` | Custom patterns YAML file | Built-in patterns |
| `--since COMMIT` | Start scanning from commit | Repository start |
| `--branch BRANCH` | Scan specific branch | All branches |
| `--format FORMAT` | Output format (table, json, yaml) | table |
| `--confidence LEVEL` | Minimum confidence (high, medium, low) | low |

**Exit Codes:**
- 0: No tokens found
- 1: Tokens found
- 2: Error during scan

### ace-security rewrite-history

Remove detected tokens from Git history using git-filter-repo.

**Syntax:**
```bash
ace-security rewrite-history [OPTIONS]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--dry-run` | Show what would be rewritten | false |
| `--backup` | Create backup before rewrite | true |
| `--force` | Skip confirmation prompt | false |
| `--scan-file FILE` | Use previous scan results | Re-scan |

**Requirements:**
- git-filter-repo must be installed (`brew install git-filter-repo`)
- Clean working directory (no uncommitted changes)

### ace-security revoke

Revoke detected tokens via provider APIs.

**Syntax:**
```bash
ace-security revoke [OPTIONS]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--service SERVICE` | Revoke for specific service | All supported |
| `--token TOKEN` | Revoke specific token | All detected |
| `--scan-file FILE` | Use previous scan results | Re-scan |

**Supported Services:**
- `github`: GitHub PATs (ghp_, gho_, ghs_, ghr_)
- `anthropic`: Anthropic API keys (via ace-llm integration)
- `openai`: OpenAI API keys (via ace-llm integration)

**Environment Variables:**
Token revocation uses environment variables for authentication:
- `GITHUB_TOKEN`: For GitHub API access (required for some revocation types)

### ace-security check-release

Pre-release security validation for CI/CD integration.

**Syntax:**
```bash
ace-security check-release [OPTIONS]
```

**Options:**
| Option | Description | Default |
|--------|-------------|---------|
| `--strict` | Fail on medium confidence matches | false |
| `--format FORMAT` | Output format (table, json) | table |

**Exit Codes:**
- 0: Security check passed
- 1: Tokens detected (release should be blocked)
- 2: Error during check

## Built-in Token Patterns

| Token Type | Pattern Prefix | Confidence |
|------------|----------------|------------|
| GitHub PAT (classic) | `ghp_` | HIGH |
| GitHub OAuth | `gho_` | HIGH |
| GitHub App Token | `ghs_` | HIGH |
| GitHub Refresh | `ghr_` | HIGH |
| Anthropic API Key | `sk-ant-` | HIGH |
| OpenAI API Key | `sk-` (40+ chars) | HIGH |
| AWS Access Key | `AKIA` | HIGH |
| AWS Session | `ASIA` | MEDIUM |
| Generic Secret | Base64 encoded patterns | LOW |

## Tips and Best Practices

1. **Always scan before publishing**: Run `ace-security check-release` as part of your release workflow.

2. **Revoke before rewriting**: Always revoke tokens before rewriting history. Even if removed from history, leaked tokens remain valid until revoked.

3. **Backup before rewrite**: The `--backup` flag (default on) creates a backup clone. Keep this until you verify the rewrite succeeded.

4. **Coordinate with team**: History rewrites affect all collaborators. Notify your team and have them re-clone after a rewrite.

5. **Use custom patterns**: Add organization-specific patterns for internal API keys and secrets.

6. **CI integration**: Add `ace-security check-release` to your CI pipeline to prevent accidental token commits from being published.

## Integration with ACE Tools

### ace-git-commit Pre-commit Hook

ace-security can integrate with ace-git-commit to detect tokens before they're committed:

```yaml
# .ace/git-commit/config.yml
pre_commit_hooks:
  - ace-security scan --staged
```

### ace-taskflow Release Workflow

The publish-release workflow can require security checks:

```yaml
# .ace/taskflow/release/config.yml
pre_publish_checks:
  - ace-security check-release
```

## Troubleshooting

### git-filter-repo Not Found

```
Error: git-filter-repo not found in PATH

Install with: brew install git-filter-repo
```

### API Rate Limiting

```
Warning: GitHub API rate limit reached (60/hour for unauthenticated)
Set GITHUB_TOKEN environment variable for higher limits.
```

### False Positives

If you encounter false positives, add them to the whitelist:

```yaml
# .ace/security/whitelist.yml
whitelist:
  - pattern: 'ghp_example_token_for_docs'
    reason: Documentation example
  - file: 'test/fixtures/mock_tokens.json'
    reason: Test fixtures with mock data
```
