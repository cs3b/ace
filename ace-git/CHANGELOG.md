# Changelog

All notable changes to ace-git will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.8.1] - 2026-01-13

### Added
- PID-based orphan detection for git lock files
  - New `orphaned?` method checks if lock-owning process still exists
  - Instant cleanup of orphaned locks (dead PID) regardless of age
  - Age-based stale detection remains as fallback for edge cases

### Changed
- Lock retry now uses fixed 500ms delay (was exponential 50→100→200→400ms)
- Lock cleanup attempted on every retry (was only first retry)
- Updated `initial_delay_ms` default from 50 to 500 in config
- Updated create-pr workflow to use worktree metadata for target_branch detection
  - Added `yq` command to read `target_branch` from `.ace-taskflow/task.yml`
  - Worktree metadata is now the preferred method for determining PR target branch
  - Falls back to legacy parent task detection when metadata unavailable
- Updated rebase workflow with auto-detection from worktree metadata
  - Added example for rebasing subtasks against parent branch
  - `target_branch` now auto-detects from worktree metadata → origin/main fallback

## [0.8.0] - 2026-01-12

### Added
- Git index lock retry with stale lock cleanup (task 210)
  - `LockErrorDetector` atom to detect git index lock errors from stderr
  - `StaleLockCleaner` atom to detect and remove stale lock files (>60s old)
  - Automatic retry with exponential backoff (50ms → 100ms → 200ms → 400ms)
  - `lock_retry` configuration section in `.ace-defaults/git/config.yml`
  - Configurable retry behavior: `enabled`, `max_retries`, `initial_delay_ms`, `stale_cleanup`, `stale_threshold_seconds`

### Changed
- Modified `CommandExecutor.execute()` to wrap git commands with lock retry logic
- Updated `CommandExecutor.repo_root()` to use `execute_once()` directly to prevent recursion
- All 459 tests pass including 30 new tests for lock retry behavior

## [0.7.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `Branch`, `Diff`, `PR`, and `Status` dry-cli command classes
  - Deleted `branch_command.rb`, `diff_command.rb`, `pr_command.rb`, and `status_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.7.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.06)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command wrappers for all commands (diff, status, branch, pr)
  - Maintained magic git range routing (HEAD~5..HEAD -> diff)
  - All 423 tests pass with complete feature parity

## [0.6.1] - 2026-01-05

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Added method_missing for default subcommand support

### Fixed
- Resolved -v flag conflict between --verbose and --version
- Addressed PR #123 review findings for Medium and higher priority issues

## [0.6.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.2.0)
- Standardized gemspec file patterns with deterministic Dir.glob
