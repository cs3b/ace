---
doc-type: workflow
title: Security Audit Workflow
purpose: security-audit workflow instruction
ace-docs:
  last-updated: 2026-02-23
  last-checked: 2026-03-21
---

# Security Audit Workflow

## Purpose

Detect and report leaked authentication tokens in Git repositories using ace-git-secrets - scan history, identify risks, and provide remediation guidance.

## Core Responsibilities

**DETECT** and **REPORT** security issues, not automatically remediate:
- Scan Git history for leaked authentication tokens
- Identify token types and assess risk levels
- Provide actionable remediation guidance
- Report findings in a clear, prioritized format

## Primary Tool: ace-git-secrets

Use **ace-git-secrets** for all security scanning operations. This tool detects:
- GitHub PATs (ghp_, gho_, ghs_, ghr_, github_pat_)
- LLM API keys (Anthropic sk-ant-, OpenAI sk-)
- Cloud credentials (AWS AKIA/ASIA, Google AIza)
- Other common tokens (Slack xox*, NPM npm_)

## Audit Modes

### Full Audit (Default)
Scan entire Git history:
```bash
ace-git-secrets scan --format table
```

### Recent Changes
Scan commits from the last 30 days:
```bash
ace-git-secrets scan --since "30 days ago" --format table
```

### Staged Changes Only
Check uncommitted changes before commit:
```bash
ace-git-secrets scan --branch HEAD --format table
```

### High Confidence Only
Filter for high-confidence detections:
```bash
ace-git-secrets scan --confidence high --format table
```

## Output Formats

### Summary (Default)
Quick overview of findings:
```bash
ace-git-secrets scan --format table
```

### JSON (Automation)
Machine-readable output:
```bash
ace-git-secrets scan --format json --output audit-results.json
```

### Pre-Release Check
CI/CD friendly exit codes:
```bash
ace-git-secrets check-release --strict
# Exit 0: Clean
# Exit 1: Tokens found
```

## Audit Workflow

### Step 1: Initial Scan
```bash
# Run comprehensive scan
ace-git-secrets scan --format table
```

### Step 2: Analyze Results
For each detected token, assess:
1. **Token Type**: What service does it authenticate to?
2. **Confidence**: How certain is the detection?
3. **Location**: Which commit and file?
4. **Exposure Risk**: Is this in a public/shared branch?

### Step 3: Prioritize Findings
Order by risk:
1. **Critical**: High-confidence tokens in public branches
2. **High**: High-confidence tokens in any branch
3. **Medium**: Medium-confidence detections
4. **Low**: Low-confidence detections (review for false positives)

### Step 4: Generate Report
Provide actionable findings with:
- Token count by type and confidence
- Affected commits and files
- Remediation priority
- Next steps

## Gitleaks Integration

ace-git-secrets uses gitleaks when available for enhanced detection:
```bash
# Check if gitleaks is available
which gitleaks

# If not installed (recommended for comprehensive scanning)
brew install gitleaks
```

When gitleaks is not available, ace-git-secrets falls back to built-in Ruby pattern matching.

## Response Format

### Audit Summary
```markdown
## Security Audit Results

**Repository:** [repo path]
**Scan Scope:** [full history / since date / staged only]
**Detection Method:** [gitleaks / ruby patterns]

### Findings Summary

| Confidence | Count | Risk Level |
|------------|-------|------------|
| High       | N     | Critical   |
| Medium     | N     | Review     |
| Low        | N     | Verify     |

### Critical Findings (Immediate Action Required)

1. **[token_type]** in `path/to/file`
   - Commit: `abc123`
   - Line: 42
   - Action: Revoke immediately via [provider dashboard URL]

### Recommendations

1. **Immediate**: Revoke all high-confidence tokens
2. **Short-term**: Rewrite Git history to remove tokens
3. **Long-term**: Add pre-commit hooks to prevent future leaks
```

### Clean Repository
```markdown
## Security Audit Results

**Repository:** [repo path]
**Scan Scope:** [scope]
**Status:** CLEAN

No authentication tokens detected in the scanned scope.

### Recommendations
- Continue using pre-commit hooks
- Schedule periodic audits
- Review any new credentials before committing
```

## False Positive Handling

If detections appear to be false positives:
1. Verify the matched content is not an actual token
2. Check if it's a placeholder/example in documentation
3. Recommend adding to whitelist:
   ```yaml
   # .ace/git-secrets/config.yml
   whitelist:
     - pattern: 'ghp_example_pattern'
       reason: Documentation example
   ```

## Integration Points

### Pre-Commit Check
```bash
ace-git-secrets check-release --strict
```

### CI/CD Pipeline
```yaml
- name: Security Audit
  run: ace-git-secrets check-release --strict
```

### Scheduled Audits
Run periodic full audits:
```bash
ace-git-secrets scan --format json --output weekly-audit.json
```

## Common Audit Scenarios

### Pre-Release Audit
```bash
# Before publishing a gem or pushing to public repo
ace-git-secrets check-release --strict
```

### Post-Incident Audit
```bash
# After suspected token exposure
ace-git-secrets scan --format json --output incident-audit.json
```

### New Repository Audit
```bash
# When onboarding a new repository
ace-git-secrets scan --confidence medium --format table
```

### Pull Request Audit
```bash
# Check only changes in PR
ace-git-secrets scan --branch feature-branch --since "$(git merge-base main feature-branch)"
```

## Important Notes

- **Detection Only**: This workflow identifies issues but does not automatically remediate
- **Token Safety**: Never log or display full token values
- **Gitleaks Priority**: Uses gitleaks when available for comprehensive detection
- **False Positives**: Always verify medium/low confidence findings
- **Remediation Workflow**: For cleanup, use `ace-bundle wfi://git/token-remediation`

## Command Reference

### scan
- `--since SINCE`: Scan since date (e.g., "30 days ago")
- `--branch BRANCH`: Scan specific branch
- `--confidence LEVEL`: Minimum confidence (low, medium, high)
- `--format FORMAT`: Output format (table, json, summary)
- `--output FILE`: Save to file

### check-release
- `--strict`: Fail on any findings
- `--format FORMAT`: Output format