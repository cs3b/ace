# Changelog

All notable changes to ace-test-support will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.14.2] - 2026-04-13

### Changed

- **ace-support-test-helpers v0.14.2**: Standardized shared package tests to the fast-only layout and updated testing flow defaults.

### Technical
- Relaxed config-helper version assertions to validate semantic-version shape instead of a pinned placeholder value.
## [0.14.1] - 2026-04-11

### Changed
- Migrated deterministic tests from `test/{atoms,molecules,fixtures}` to `test/fast/{atoms,molecules,fixtures}` to align with the fast/feat/e2e model as a fast-only package.
- Updated README testing guidance to document the fast-only contract and canonical `ace-test` commands for this package.

## [0.14.0] - 2026-04-10

### Added
- Added `SandboxPackageCopy`, a reusable helper for copying a target package into an isolated sandbox and owning the sandbox environment contract for restarted E2E flows.

## [0.13.1] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.13.0] - 2026-03-23

### Fixed
- Corrected `source_code_uri` gemspec metadata to point to package-specific path instead of repository root.

### Technical
- Removed phantom `handbook/**/*` glob from gemspec (no handbook directory exists).

## [0.12.6] - 2026-03-22

### Changed
- Refreshed README structure for support-library consistency while preserving existing usage and utility documentation.
- Added the canonical `Part of ACE` footer and explicit `License` section to the package README.

## [0.12.5] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.12.4] - 2026-03-09

### Fixed
- `with_temp_dir` now resets cached `Ace::Bundle` configuration alongside project-root cache state so temp-dir tests remain order-independent under full non-E2E suite execution.

## [0.12.3] - 2026-03-04

### Fixed
- `with_cascade_configs` now isolates HOME into a temporary directory when creating home-level config fixtures, preventing permission errors in sandboxed environments.

## [0.12.2] - 2026-01-31

### Fixed
- Add `respond_to?(:get)` check to `test_stub_ace_core_config_integration` skip condition

## [0.12.1] - 2026-01-31

### Fixed
- Improve `stub_ace_core_config` isolation with `respond_to?` guard and `define_singleton_method`

## [0.11.1] - 2026-01-15

### Changed
- **Context Mocks Migration**: Updated ContextMocks to use Ace::Bundle
  - Renamed all `Ace::Context` references to `Ace::Bundle`
  - Updated mock methods: `stub_load_file`, `stub_load_auto`, `restore_load_file`, `restore_load_auto`
  - Comments now reference ace-bundle instead of ace-context
- Updated TestRunnerMocks default package from ace-context to ace-bundle

### Technical
- Updated contract tests to check for Ace::Bundle availability

## [0.11.0] - 2026-01-07

### Added
- **CLI test helpers** for dry-cli based CLIs (task 179)
  - `CliHelpers` module with reusable patterns for testing CLI commands
  - `invoke_cli` - Invoke CLI and capture stdout/stderr/result
  - `invoke_cli_stdout` - Convenience method for stdout only
  - `assert_cli_success` - Assert CLI returns exit code 0
  - `assert_cli_output_matches` - Assert CLI output matches pattern

## [0.10.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.2.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.9.3] - 2025-12-27

### Changed

- **Contract Test Enhancement**: Added guarded require for ace-git in git contract tests
  - Enables integration test to exercise CommandExecutor stub with ace-git when available
  - Part of ace-git-diff to ace-git migration

## [0.9.2] - 2025-10-08

### Changed

- **Test Structure Migration**: Migrated to flat ATOM structure
  - From: `test/unit/atoms/` and `test/unit/molecules/`
  - To: `test/atoms/` and `test/molecules/`
  - Aligns with standardized test organization across all ACE packages
  - Simplifies test discovery and maintenance

## [0.9.1] - 2025-10-08

### Changed
- **Test directory structure**: Reorganized tests to follow ATOM architecture
  - Moved tests from flat `test/*.rb` structure to `test/unit/atoms/` and `test/unit/molecules/`
  - Makes tests discoverable by ace-test-runner
  - Aligns with project-wide ATOM architecture pattern (ADR-011)
  - Files organized as:
    - `test/unit/atoms/`: base_test_case_test.rb, test_helper_test.rb
    - `test/unit/molecules/`: config_helpers_test.rb, test_environment_test.rb

## [0.9.0] - 2025-10-05

Initial release with shared test utilities for ACE ecosystem.
