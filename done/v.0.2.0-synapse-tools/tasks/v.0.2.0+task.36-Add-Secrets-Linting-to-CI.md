---
id: v.0.2.0+task.36
status: done
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

* [x] Research GitHub's native secret scanning capabilities and limitations
  > TEST: GitHub Protection Understanding
  > Type: Pre-condition Check
  > Assert: Document GitHub's push protection features and when local scanning adds value
  > Manual Verification: Test push protection with sample secret
  > COMPLETED: GitHub's push protection is now enabled by default for all public repos (as of Feb 2024). It scans for highly identifiable secrets before push, but has limitations: only detects specific/prefixed secret types, no historical scanning, pattern pairs must be in same file, large pushes may be skipped, and older token versions may not be detected. Local scanning with Gitleaks adds value by: catching secrets during development (faster feedback), supporting broader pattern detection, scanning entire codebase including history, and working offline without relying on push-time blocking.
* [x] Evaluate Gitleaks integration approach with existing `bin/lint` script
  > COMPLETED: Gitleaks supports `gitleaks detect` command which can be run after StandardRB in the existing bin/lint script. The tool has excellent CLI integration with configurable exit codes and can be checked for availability using `which gitleaks` or `command -v gitleaks`.
* [x] Determine performance impact on local development workflow
  > COMPLETED: Gitleaks is designed for speed and typically completes in 1-3 seconds for most repositories. It can scan entire git history efficiently and has minimal impact on development workflow.
* [x] Plan configuration for common false positives in Ruby projects (VCR cassettes, test fixtures)
  > COMPLETED: Will use .gitleaks.toml config file to exclude VCR cassettes (spec/cassettes/**), test fixtures with filtered secrets, and documentation examples. Gitleaks supports path-based exclusions and allowlist patterns for known safe content.

### Execution Steps

- [x] Integrate Gitleaks into `bin/lint` script:
  - [x] Modify `bin/lint` to run Gitleaks after StandardRB
  - [x] Add check for Gitleaks binary availability
  - [x] Configure graceful fallback when Gitleaks is missing
  - [x] Preserve existing StandardRB argument passing
  > TEST: Lint Integration
  > Type: Action Validation
  > Assert: `bin/lint` runs both StandardRB and Gitleaks (when available)
  > Command: bin/lint --help | grep -E "(standardrb|gitleaks)" || echo "Check manual execution"
  > COMPLETED: Successfully integrated Gitleaks into bin/lint script. When Gitleaks is available, it runs after StandardRB with `gitleaks detect --verbose --no-git`. When not available, shows informative message with installation instructions.
- [x] Create Gitleaks configuration file:
  - [x] Set up `.gitleaks.toml` with Ruby project rules
  - [x] Configure exclusions for VCR cassettes and test fixtures
  - [x] Set appropriate sensitivity levels
- [x] Test scanner integration:
  - [x] Verify detection of common API key formats with `bin/lint`
  - [x] Verify detection of private keys with `bin/lint`
  - [x] Ensure VCR cassettes with filtered keys don't trigger false positives
  - [x] Test graceful handling when Gitleaks is not installed
  > TEST: Scanner Integration
  > Type: Action Validation
  > Assert: `bin/lint` detects test secret but ignores filtered VCR cassettes and handles missing binary
  > Manual Verification: Test with/without Gitleaks installed, verify behavior in both cases
  > COMPLETED: Verified Gitleaks detects secrets (tested with sk-* format), properly excludes VCR cassettes with <GEMINI_API_KEY> placeholders, ignores .env files and test fixtures, and shows helpful message when not installed.
- [x] Update documentation:
  - [x] Add secrets scanning section to CONTRIBUTING.md
  - [x] Create comprehensive guide in docs/dev-guides/
  - [x] Update DEVELOPMENT.md with optional Gitleaks dependency
  - [x] Document GitHub's native push protection as primary security layer
- [x] Configure exceptions and baselines:
  - [x] Exclude example API keys in documentation
  - [x] Handle test fixtures appropriately
  - [x] Set up baseline for existing code if needed

### Additional Improvements Applied (Based on Feedback)

- [x] Create standalone `bin/lint-security` script with advanced options:
  - [x] `--full` flag to scan files larger than 1MB
  - [x] `--git-past` flag to scan entire git history
  - [x] `--verbose` flag for detailed output
  - [x] `--help` flag for usage information
- [x] Modify `bin/lint` to call `bin/lint-security` as a separate step
- [x] Implement automatic .gitignore file respect (files matching .gitignore patterns are automatically excluded)
- [x] Configure 1MB file size limit by default to avoid scanning logs and large data files
- [x] Test gitignore integration (verified files in tmp/ directory are properly excluded)
- [x] Test file size limits (large files are handled appropriately)
- [x] Test git history scanning functionality
- [x] Update all documentation to reflect new standalone script architecture

## Acceptance Criteria

- [x] Secrets scanning runs as part of `bin/lint` command (used in CI)
- [x] Scanner detects common secret patterns when Gitleaks is available
- [x] Graceful fallback with informative message when Gitleaks is missing
- [x] False positives are minimized through proper `.gitleaks.toml` configuration
- [x] `bin/lint` fails when secrets are detected (maintaining existing StandardRB behavior)
- [x] Clear error messages guide developers on remediation and Gitleaks installation
- [x] Documentation explains GitHub's native protection and local scanning benefits
- [x] Performance impact on `bin/lint` is less than 5 seconds (measured: 1.329s total)
- [x] VCR cassettes with filtered secrets don't trigger alerts
- [x] Existing StandardRB argument passing in `bin/lint` is preserved

### Additional Acceptance Criteria (From Feedback)

- [x] Standalone `bin/lint-security` script with advanced options
- [x] `--full` flag scans files larger than 1MB
- [x] `--git-past` flag scans entire git history for historical secrets
- [x] Files matching .gitignore patterns are automatically excluded
- [x] 1MB file size limit by default to avoid scanning logs and data dumps
- [x] Comprehensive documentation covers new script architecture
- [x] All options work correctly and provide expected functionality

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
