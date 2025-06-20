---
id: v.0.2.0+task.36
status: ready
priority: high
estimate: 3h
dependencies: []
---

# Add Secrets Linting to Development Workflow

## Objective

Integrate secrets detection into the local development workflow by adding it to the existing `bin/lint` command. This complements GitHub's native push protection (which already blocks commits with known secrets) by catching secrets during local development, reducing developer friction and providing immediate feedback without relying on push-time blocking.

## Scope of Work

- Integrate Gitleaks secrets detection into existing `bin/lint` command
- Configure tool to scan code, tests, and documentation (when Gitleaks is available)
- Provide graceful fallback when Gitleaks is not installed
- Add optional dependency documentation for contributors
- Document GitHub's native push protection as primary security layer

### Deliverables

#### Create

- `.gitleaks.toml` config file for Gitleaks configuration
- `docs/dev-guides/security-secrets-scanning.g.md` (usage and configuration guide)

#### Modify

- `bin/lint` (integrate Gitleaks scanning after StandardRB)
- `.github/CONTRIBUTING.md` (add section about secrets scanning)
- `docs/DEVELOPMENT.md` (add optional Gitleaks dependency documentation)

## Phases

1. Tool Integration - Integrate Gitleaks into existing `bin/lint` script
2. Configuration - Set up rules and exclusions for Ruby projects
3. Graceful Degradation - Handle missing Gitleaks binary elegantly
4. Documentation - Update development guides and dependency docs
5. Testing - Verify integration works locally and in CI

## Implementation Plan

### Planning Steps

* [ ] Research GitHub's native secret scanning capabilities and limitations
  > TEST: GitHub Protection Understanding
  > Type: Pre-condition Check
  > Assert: Document GitHub's push protection features and when local scanning adds value
  > Manual Verification: Test push protection with sample secret
* [ ] Evaluate Gitleaks integration approach with existing `bin/lint` script
* [ ] Determine performance impact on local development workflow
* [ ] Plan configuration for common false positives in Ruby projects (VCR cassettes, test fixtures)

### Execution Steps

- [ ] Integrate Gitleaks into `bin/lint` script:
  - [ ] Modify `bin/lint` to run Gitleaks after StandardRB
  - [ ] Add check for Gitleaks binary availability
  - [ ] Configure graceful fallback when Gitleaks is missing
  - [ ] Preserve existing StandardRB argument passing
  > TEST: Lint Integration
  > Type: Action Validation
  > Assert: `bin/lint` runs both StandardRB and Gitleaks (when available)
  > Command: bin/lint --help | grep -E "(standardrb|gitleaks)" || echo "Check manual execution"
- [ ] Create Gitleaks configuration file:
  - [ ] Set up `.gitleaks.toml` with Ruby project rules
  - [ ] Configure exclusions for VCR cassettes and test fixtures
  - [ ] Set appropriate sensitivity levels
- [ ] Test scanner integration:
  - [ ] Verify detection of common API key formats with `bin/lint`
  - [ ] Verify detection of private keys with `bin/lint`
  - [ ] Ensure VCR cassettes with filtered keys don't trigger false positives
  - [ ] Test graceful handling when Gitleaks is not installed
  > TEST: Scanner Integration
  > Type: Action Validation
  > Assert: `bin/lint` detects test secret but ignores filtered VCR cassettes and handles missing binary
  > Manual Verification: Test with/without Gitleaks installed, verify behavior in both cases
- [ ] Update documentation:
  - [ ] Add secrets scanning section to CONTRIBUTING.md
  - [ ] Create comprehensive guide in docs/dev-guides/
  - [ ] Update DEVELOPMENT.md with optional Gitleaks dependency
  - [ ] Document GitHub's native push protection as primary security layer
- [ ] Configure exceptions and baselines:
  - [ ] Exclude example API keys in documentation
  - [ ] Handle test fixtures appropriately
  - [ ] Set up baseline for existing code if needed

## Acceptance Criteria

- [ ] Secrets scanning runs as part of `bin/lint` command (used in CI)
- [ ] Scanner detects common secret patterns when Gitleaks is available
- [ ] Graceful fallback with informative message when Gitleaks is missing
- [ ] False positives are minimized through proper `.gitleaks.toml` configuration
- [ ] `bin/lint` fails when secrets are detected (maintaining existing StandardRB behavior)
- [ ] Clear error messages guide developers on remediation and Gitleaks installation
- [ ] Documentation explains GitHub's native protection and local scanning benefits
- [ ] Performance impact on `bin/lint` is less than 5 seconds
- [ ] VCR cassettes with filtered secrets don't trigger alerts
- [ ] Existing StandardRB argument passing in `bin/lint` is preserved

## Out of Scope

- ❌ Scanning git history for historical secrets
- ❌ Automatic remediation of found secrets
- ❌ Integration with external secret management systems
- ❌ Custom secret pattern development (use Gitleaks defaults)
- ❌ Mandatory Gitleaks installation for all developers
- ❌ Separate CI workflow (leverage existing `bin/lint` in CI)

## References

- Architecture note on secrets: `docs/architecture.md` (Security Considerations)
- Current `bin/lint` script: `bin/lint`
- Development dependencies: `docs/DEVELOPMENT.md`
- Gitleaks documentation: https://github.com/gitleaks/gitleaks
- GitHub Secret Scanning: https://docs.github.com/en/code-security/secret-scanning
- GitHub Push Protection: https://docs.github.com/en/code-security/secret-scanning/push-protection-for-repositories-and-organizations
- VCR configuration: `spec/support/vcr.rb` (for understanding filtered secrets)
