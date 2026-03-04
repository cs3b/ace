# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.1] - 2026-03-04

### Fixed
- README and usage docs updated to short-name path convention (`.ace-local/git-secrets` not `.ace-local/ace-git-secrets`)

## [0.8.0] - 2026-03-04

### Changed
- Default session/report directory migrated from `.cache/ace-git-secrets/sessions` to `.ace-local/git-secrets/sessions`
- Gitleaks workspace now uses `Ace::Support::Items::Atoms::TmpWorkspace` for deterministic `.ace-local/tmp` paths

## [0.7.11] - 2026-02-24

### Technical
- Correct TS-SECRETS-001 E2E runner config path references to `.ace/git-secrets/config.yml` and document whitelist file-rule setup for fixture exclusions.

## [0.7.10] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.7.9] - 2026-02-22

### Changed
- Migrate top-level CLI help to the standard multi-command help pattern with explicit `help`, `--help`, and `-h` commands.

### Technical
- Remove custom default-routing (`CLI.start`, `KNOWN_COMMANDS`, `DEFAULT_COMMAND`) from CLI registry.
- Move config preloading and no-args help handling to `exe/ace-git-secrets` before dry-cli dispatch.
- Update CLI command tests to assert executable-equivalent dry-cli dispatch behavior.

## [0.7.7] - 2026-02-19

### Technical
- Namespace security workflow instructions into git/ subdirectory

## [0.7.6] - 2026-02-11

### Technical
- Remove legacy MT-SECRETS-002 E2E test file (functionality covered by TS-SECRETS-002)

## [0.7.5] - 2026-02-11

### Added
- E2E tests for scan, rewrite, and configuration workflows
- Full workflow and config cascade E2E tests

### Fixed
- Ensure proper exit codes for scan, revoke, rewrite commands (CLI wrappers now
  raise Error with correct exit_code instead of returning 0)
- Move broken-report fixture out of .cache to avoid gitignore
- Resolve non-zero exit code for --help flag

### Changed
- Migrate E2E tests to per-TC directory format

## [0.7.4] - 2026-01-31

### Fixed
- Optimize slow tests by stubbing subprocess calls
  - Convert clean_working_directory? tests from real git calls to stubbed Open3.capture2
  - Remove flaky test_available_returns_true_when_git_filter_repo_installed
  - Suite time improved from ~1.4s to ~1.1s (~23% faster)

## [0.7.3] - 2026-01-31

### Performance
- Moved git integration tests to E2E test suite
  - Tests now run via `/ace:run-e2e-test ace-git-secrets MT-SECRETS-001`
  - Added HistoryScanner unit tests with mocked gitleaks
  - Test execution time reduced from 4.5s to ~1.8s (60% reduction)

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


## [0.7.8] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
