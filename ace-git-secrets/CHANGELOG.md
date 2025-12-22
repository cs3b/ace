# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Azure Storage Key and GCP token pattern detection
- Configurable user-agent header for API client
- Configurable binary file extensions via `binary_extensions` parameter
- `--quiet` flag for CI-friendly minimal output
- ReleaseGate organism tests
- Tests for custom patterns with special characters

### Changed

- Use `Ace::Core::Atoms::DeepMerger` from ace-support-core instead of local deep_merge
- Improved error messages for empty or missing patterns files
- Log batch fallback reason when git cat-file --batch fails

### Fixed

- Repository path validation in GitRewriter to prevent operations on invalid paths

## [0.1.0] - 2025-12-20

### Added

- Initial release of ace-git-secrets gem
- `ace-git-secrets scan` - Scan Git history for authentication tokens
  - Supports GitHub PATs (classic, OAuth, App, fine-grained)
  - Supports LLM API keys (Anthropic, OpenAI)
  - Supports AWS credentials (Access Key, Session Token)
  - Uses gitleaks when available, falls back to Ruby patterns
  - Output formats: table, JSON, YAML
- `ace-git-secrets rewrite-history` - Remove tokens from Git history
  - Uses git-filter-repo for safe history rewriting
  - Dry-run mode for preview
  - Automatic backup creation
  - Confirmation required for destructive operations
- `ace-git-secrets revoke` - Revoke tokens via provider APIs
  - GitHub token revocation via Credential Revocation API
  - Instructions for manual revocation (Anthropic, OpenAI, AWS)
- `ace-git-secrets check-release` - Pre-release security gate
  - CI-friendly exit codes (0=pass, 1=fail)
  - Strict mode for medium confidence matches
- Models: DetectedToken, RevocationResult, ScanReport
- Atoms: TokenPatternMatcher, GitleaksRunner, GitBlobReader, ServiceApiClient
- Molecules: HistoryScanner, GitRewriter, TokenRevoker
- Organisms: SecurityAuditor, HistoryCleaner, ReleaseGate
- Configuration via ace-core config cascade (.ace/git-secrets/config.yml)
- ATOM architecture following ACE gem standards
