---
id: v.0.2.0+task.36
status: ready
priority: high
estimate: 3h
dependencies: []
---

# Add Secrets Linting to CI

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 .github | sed 's/^/    /'
```

_Result excerpt:_

```
    .github
    ├── CONTRIBUTING.md
    ├── ISSUE_TEMPLATE
    └── workflows
        └── ci.yml
```

## Objective

Add automated secrets detection to the CI pipeline to ensure no plaintext secrets, API keys, or sensitive information are accidentally committed to the repository or exposed in logs. This provides a double-check mechanism beyond code review to maintain security best practices.

## Scope of Work

- Research and select appropriate secrets detection tools for Ruby projects
- Integrate secrets scanning into GitHub Actions CI workflow
- Configure tool to scan code, tests, and documentation
- Add pre-commit hook option for local development
- Document usage and configuration for contributors

### Deliverables

#### Create

- `.github/workflows/secrets-scan.yml` (dedicated secrets scanning workflow)
- `docs/dev-guides/secrets-scanning.md` (usage and configuration guide)
- `.gitleaks.toml` or similar config file (if using Gitleaks)

#### Modify

- `.github/workflows/ci.yml` (add secrets scanning step)
- `.github/CONTRIBUTING.md` (add section about secrets scanning)
- `docs/DEVELOPMENT.md` (add pre-commit hook setup instructions)

## Phases

1. Tool Selection - Research and choose appropriate secrets detection tool
2. CI Integration - Add secrets scanning to GitHub Actions
3. Configuration - Set up rules and exclusions
4. Documentation - Create guides for developers
5. Local Setup - Add optional pre-commit hooks

## Implementation Plan

### Planning Steps

* [ ] Research secrets detection tools suitable for Ruby projects
  > TEST: Tool Research Complete
  > Type: Pre-condition Check
  > Assert: At least 3 tools evaluated with pros/cons documented
  > Manual Verification: Document comparison of tools like Gitleaks, TruffleHog, detect-secrets
* [ ] Evaluate GitHub's native secret scanning vs third-party tools
* [ ] Determine performance impact on CI pipeline
* [ ] Plan configuration for common false positives in Ruby projects

### Execution Steps

- [ ] Install and configure chosen secrets detection tool:
  - [ ] Add tool to CI workflow
  - [ ] Configure scanning rules
  - [ ] Set up exclusions for test fixtures and examples
  > TEST: Tool Installation
  > Type: Action Validation
  > Assert: Secrets scanner runs successfully in CI
  > Command: grep -q "secrets.*scan" .github/workflows/ci.yml
- [ ] Create dedicated secrets scanning workflow:
  - [ ] Set up workflow triggers (push, PR)
  - [ ] Configure scanning scope (files to include/exclude)
  - [ ] Set up failure conditions and reporting
- [ ] Test scanner with known patterns:
  - [ ] Verify detection of common API key formats
  - [ ] Verify detection of private keys
  - [ ] Ensure VCR cassettes with filtered keys don't trigger false positives
  > TEST: Scanner Effectiveness
  > Type: Action Validation
  > Assert: Scanner detects test secret but ignores filtered VCR cassettes
  > Manual Verification: Create test file with fake secret, verify detection, then remove
- [ ] Add pre-commit hook setup:
  - [ ] Create optional pre-commit configuration
  - [ ] Document installation steps
  - [ ] Make it opt-in to avoid forcing dependencies
- [ ] Update documentation:
  - [ ] Add secrets scanning section to CONTRIBUTING.md
  - [ ] Create comprehensive guide in docs/dev-guides/
  - [ ] Update DEVELOPMENT.md with pre-commit setup
- [ ] Configure exceptions and baselines:
  - [ ] Exclude example API keys in documentation
  - [ ] Handle test fixtures appropriately
  - [ ] Set up baseline for existing code if needed

## Acceptance Criteria

- [ ] Secrets scanning runs automatically on all PRs and pushes
- [ ] Scanner detects common secret patterns (API keys, tokens, passwords)
- [ ] False positives are minimized through proper configuration
- [ ] CI fails when secrets are detected
- [ ] Clear error messages guide developers on remediation
- [ ] Documentation explains how to handle false positives
- [ ] Pre-commit hook is available but optional
- [ ] Performance impact on CI is less than 30 seconds
- [ ] VCR cassettes with filtered secrets don't trigger alerts

## Out of Scope

- ❌ Scanning git history for historical secrets
- ❌ Automatic remediation of found secrets
- ❌ Integration with external secret management systems
- ❌ Custom secret pattern development (use tool defaults)
- ❌ Mandatory pre-commit hooks for all developers

## References

- Architecture note on secrets: `docs/architecture.md` (Security Considerations)
- GitHub Actions docs: https://docs.github.com/en/actions
- Potential tools:
  - Gitleaks: https://github.com/gitleaks/gitleaks
  - TruffleHog: https://github.com/trufflesecurity/trufflehog
  - detect-secrets: https://github.com/Yelp/detect-secrets
- VCR configuration: `spec/support/vcr.rb` (for understanding filtered secrets)