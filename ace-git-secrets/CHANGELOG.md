# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.2] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.7.1] - 2026-01-15

### Changed
- Migrate CLI commands to Hanami pattern
  - Move commands from `commands/` to `cli/commands/`
  - Update namespace from `Commands::*` to `CLI::Commands::*`
  - Business logic command classes (`*Command`) remain in `commands/`

## [0.7.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.09)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command wrappers (Scan, Rewrite, Revoke, CheckRelease)
  - Maintained complete command parity and user-facing behavior

## [0.6.0] - 2026-01-07

### Changed
- **BREAKING**: Scan report filenames changed from 14-character timestamps to 6-character Base36 compact IDs
  - Example: `20251129-143000-report.json` → `i50jj3-report.json`
  - Reports now stored in `sessions/` subdirectory: `.cache/ace-git-secrets/sessions/`
- Migrate to Base36 compact IDs for session and file naming (via ace-timestamp)

### Added
- Dependency on ace-timestamp for compact ID generation
- Organized report storage with `sessions/` subdirectory

## [0.5.0] - 2026-01-05

### Added
- Thor CLI migration with standardized command structure
- ConfigSummary display for effective configuration with sensitive key filtering
- Comprehensive CLI help documentation across all commands
- --help support for all subcommands
- exit_on_failure and version mapping standardization

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Migrated from OptionParser to Thor framework
- Added method_missing for default subcommand support

## [0.4.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.3.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.3.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.2.0] - 2025-12-22

### Added

- Raw token persistence in scan results for remediation workflow
- Thread-safe blob caching for improved performance
- ADR-023 documenting security model decisions
- Enhanced audit logging for compliance tracking
- Configurable user-agent header for API client
- Configurable binary file extensions via `binary_extensions` parameter
- `--quiet` flag for CI-friendly minimal output

### Changed

- **BREAKING**: Gitleaks is now required for scanning (removed internal Ruby pattern detection fallback)
- Simplified architecture by delegating all pattern matching to gitleaks
- Use `Ace::Core::Atoms::DeepMerger` from ace-support-core instead of local deep_merge
- Improved error messages for gitleaks validation and missing patterns files
- Log batch fallback reason when git cat-file --batch fails

### Removed

- Internal Ruby pattern detection (TokenPatternMatcher) - now delegates entirely to gitleaks
- GitBlobReader complex blob parsing - simplified to use gitleaks output
- ThreadSafeBlobCache - no longer needed without internal pattern matching

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
