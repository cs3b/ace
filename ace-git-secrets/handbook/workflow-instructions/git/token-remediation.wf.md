---
name: git/token-remediation
allowed-tools: Bash, Read, Write
description: Complete workflow to detect, revoke, and remove authentication tokens from Git history
argument-hint: "[scan-only|full]"
doc-type: workflow
purpose: security remediation workflow instruction
update:
  frequency: on-change
  last-updated: '2025-12-21'
---

# Token Remediation Workflow

## Purpose

Execute a complete security remediation workflow to detect, revoke, and remove leaked authentication tokens from Git history using ace-git-secrets.

## Context

ace-git-secrets provides:
- Token detection via gitleaks (required)
- Token revocation via GitHub Credential Revocation API
- History rewriting via git-filter-repo
- Pre-release security gates for CI/CD

## Prerequisites

- Git repository with push access
- `gitleaks` installed (`brew install gitleaks`) - required for token detection
- For history rewriting: `git-filter-repo` installed (`brew install git-filter-repo`)
- Clean working directory (no uncommitted changes)

## Variables

- `$mode`: Workflow mode - `scan-only` (detection only) or `full` (complete remediation)

## Instructions

### Phase 1: Detection

1. **Scan Git history for tokens:**
   ```bash
   # Full history scan (saves report to .ace-local/git-secrets/)
   ace-git-secrets scan

   # Scan with verbose table output
   ace-git-secrets scan --verbose

   # Scan since specific date (faster for large repos)
   ace-git-secrets scan --since "2024-01-01"

   # Scan high confidence tokens only
   ace-git-secrets scan --confidence high
   ```

   The scan automatically saves a JSON report with raw token values to
   `.ace-local/git-secrets/<timestamp>-report.json`. This report can be
   reused for revocation and history rewriting without rescanning.

2. **Review scan results:**
   - Check token types detected (github_pat, anthropic_api_key, aws_access_key, etc.)
   - Verify confidence levels (high, medium, low)
   - Note commit hashes and file paths for context
   - Identify false positives

### Phase 1.5: Token Analysis & Categorization

3. **Read the providers report for unique token summary:**

   The scan generates two report files:
   - `<timestamp>-report.json` - Full details of all occurrences
   - `<timestamp>-providers.md` - Unique tokens grouped by provider

   Read the providers report to understand unique tokens and their locations.

4. **Categorize each token by file path pattern:**

   | Category | Path Patterns | Recommendation |
   |----------|---------------|----------------|
   | **A: Test Fixtures** | `**/test/**`, `**/spec/**`, `**/__tests__/**`, `**/fixtures/**` | Whitelist (fake tokens) |
   | **B: Recorded Keys** | `**/cassettes/**`, `**/vcr/**`, `**/recordings/**` | Verify revoked, then whitelist |
   | **C: Real Credentials** | `.env`, `config/**`, `secrets/**`, `src/**`, `lib/**` | IMMEDIATE REVOCATION |
   | **D: Legacy/Backup** | `*.backup*/**`, `*.bak`, `_legacy/**`, `archive/**` | Review, cleanup, whitelist |
   | **E: Documentation** | `**/docs/**`, `**/*.md` | Whitelist (examples) |

5. **For Category A (Test Fixtures):**
   - These are fake tokens used in tests
   - Add to whitelist, no revocation needed:
   ```yaml
   # .ace/git-secrets/config.yml
   whitelist:
     - file: "**/test/**"
       reason: "Unit test fixtures"
     - file: "**/spec/**"
       reason: "RSpec test files"
   ```

6. **For Category B (Recorded API Keys in VCR cassettes):**
   - These may contain real API keys recorded during tests
   - List unique keys and verify each is revoked at provider:
     - GCP: https://console.cloud.google.com/apis/credentials
     - Anthropic: https://console.anthropic.com/account/keys
     - OpenAI: https://platform.openai.com/api-keys
     - GitHub: https://github.com/settings/tokens
   - Only add to whitelist AFTER confirming revocation

7. **For Category C (Real Credentials):**
   - These require IMMEDIATE action
   - Proceed to Phase 2 Revocation without delay
   - Do NOT whitelist these

8. **For Category D (Legacy/Backup):**
   - Consider removing legacy directories from git entirely
   - If keeping, verify any real keys are revoked first
   - Add to whitelist after cleanup

9. **Generate recommendations summary:**

   ```
   ## Token Analysis Summary

   Category A (Test Fixtures): [N] tokens → whitelist
   Category B (Recorded Keys): [N] tokens → verify revoked, whitelist
   Category C (Real Creds):    [N] tokens → REVOKE IMMEDIATELY
   Category D (Legacy):        [N] tokens → review + cleanup
   Category E (Docs):          [N] tokens → whitelist

   Recommended whitelist patterns:
   - [pattern]: [reason]
   ```

10. **If `$mode` is `scan-only`, stop here and report analysis with recommendations.**

### Phase 2: Revocation (CRITICAL - Do First)

11. **Revoke tokens immediately** (before they can be exploited):
   ```bash
   # Revoke all detected tokens (runs fresh scan)
   ace-git-secrets revoke

   # Revoke from saved scan file (faster, no rescan needed)
   ace-git-secrets revoke --scan-file .ace-local/git-secrets/<timestamp>-report.json

   # Revoke specific service only
   ace-git-secrets revoke --service github

   # Revoke specific token directly
   ace-git-secrets revoke --token "ghp_..."
   ```

   **Tip:** Using `--scan-file` from a previous scan is faster and ensures
   you're revoking the exact tokens that were detected.

12. **Verify revocation:**
   - Check revocation results for each token
   - Note any tokens that couldn't be revoked (unsupported services)
   - For unsupported services, manually revoke via provider dashboards:
     - GitHub: https://github.com/settings/tokens
     - Anthropic: https://console.anthropic.com/account/keys
     - OpenAI: https://platform.openai.com/api-keys
     - AWS: https://console.aws.amazon.com/iam

### Phase 3: History Rewriting

13. **Create backup before rewriting:**
   ```bash
   # Create backup clone (CRITICAL)
   git clone --mirror . ../repo-backup-$(date +%Y%m%d)
   ```

14. **Preview history rewrite (dry run):**
   ```bash
   ace-git-secrets rewrite-history --dry-run
   ```

15. **Execute history rewrite:**
   ```bash
   # Interactive mode (requires confirmation, runs fresh scan)
   ace-git-secrets rewrite-history

   # From saved scan file (faster, consistent with revocation)
   ace-git-secrets rewrite-history --scan-file .ace-local/git-secrets/<timestamp>-report.json

   # Force mode (skip confirmation - use with caution)
   ace-git-secrets rewrite-history --force
   ```

   **Tip:** Use the same `--scan-file` used for revocation to ensure
   the exact same tokens are removed from history.

16. **Verify history is clean:**
   ```bash
   # Rescan to confirm tokens removed
   ace-git-secrets scan
   ```

### Phase 4: Push and Notify

17. **Force push cleaned history:**
    ```bash
    # Force push with lease (safer)
    git push --force-with-lease origin main

    # Push all branches if needed
    git push --force-with-lease --all origin
    ```

18. **Notify collaborators:**
    - All collaborators must re-clone or reset their local copies
    - Anyone who fetched the compromised history should check for token exposure
    - Consider rotating any tokens that may have been cached locally

19. **Update documentation:**
    - Document incident and remediation in security log
    - Update .gitignore to prevent future leaks
    - Consider adding pre-commit hooks

## Post-Remediation Actions

### Prevent Future Leaks

1. **Add pre-commit integration:**
   ```bash
   # Add to .pre-commit-config.yaml
   ace-git-secrets check-release --strict
   ```

2. **Configure CI/CD gate:**
   ```yaml
   # In CI workflow
   - name: Security Check
     run: ace-git-secrets check-release --strict
   ```

3. **Add patterns to .gitignore:**
   ```
   .env
   .env.local
   *.pem
   *_rsa
   credentials.json
   ```

### Whitelist False Positives

If the scan detected false positives, add them to configuration:

```yaml
# .ace/git-secrets/config.yml
whitelist:
  - pattern: 'ghp_example_for_docs'
    reason: Documentation example
  - file: 'test/fixtures/mock_tokens.json'
    reason: Test fixtures
```

## Options Reference

### Scan Command
- `--since DATE`: Scan commits after date
- `--confidence LEVEL`: Minimum confidence (low, medium, high)
- `--format FORMAT`: Stdout format when --verbose is used (table, json, yaml)
- `--report-format FORMAT`: Format for saved report file (json, markdown)
- `--verbose`: Enable verbose output with full report to stdout
- `--quiet`: Suppress non-essential output (for CI)

### Revoke Command
- `--scan-file FILE`: Revoke tokens from scan results file
- `--service SERVICE`: Revoke only specific service (github, anthropic, openai)
- `--token TOKEN`: Revoke specific token

### Rewrite Command
- `--dry-run`: Preview changes without modifying history
- `--force`: Skip confirmation prompt
- `--no-backup`: Skip backup (not recommended)
- `--scan-file FILE`: Use tokens from scan results file

### Check-Release Command
- `--strict`: Fail on medium confidence tokens too
- `--format FORMAT`: Output format (table, json)

## Success Criteria

- All detected tokens are revoked
- Git history no longer contains any tokens
- Force push completed successfully
- Collaborators notified and re-cloned
- Pre-commit/CI integration added to prevent future leaks

## Response Template

**Scan Results:** [Number of tokens found, by type and confidence]
**Revocation Status:** [Tokens revoked / total, any failures]
**History Rewrite:** [Commits modified, files cleaned]
**Push Status:** [Branch(es) pushed, any conflicts]
**Status:** Complete | Partial (manual action needed for [reason])
