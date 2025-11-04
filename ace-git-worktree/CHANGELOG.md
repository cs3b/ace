# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.7] - 2025-11-04

### Fixed
- **Worktree Detection**: Fix critical issue where `ace-git-worktree list` showed "No worktrees found" despite existing worktrees
- **Git Output Parsing**: Update porcelain format parsing to handle 3-line format per worktree (worktree/HEAD/branch lines)
- **CommandExecutor Integration**: Fix timeout parameter mismatch causing git help output instead of worktree listing
- **Module Path**: Correct require path from `ace/git/diff/atoms/command_executor` to `ace/git_diff/atoms/command_executor`
- **YAML Loading**: Add missing `require "yaml"` to ConfigLoader classes

### Added
- **Full Worktree Support**: Now detects and displays all 7 existing worktrees (6 task-associated + 1 main)
- **Task Association**: Proper task ID extraction from existing worktree paths (086, 089, 090, 091, 093, 097)
- **Mixed Environment**: Support for both task-aware and traditional worktrees in unified view

### Changed
- **Porcelain Parsing**: Complete rewrite of `from_git_output_list()` to handle structured porcelain format
- **Worktree Information**: Enhanced display showing Task, Branch, Path, and Status for all worktrees

## [0.1.6] - 2025-11-04

### Fixed
- **Binstub**: Fix hardcoded path from `.ace-wt/task.089-zai/ace-git-worktree/` to `ace-git-worktree/`
- **VERSION**: Eliminate duplicate VERSION constant warnings by loading from correct gem location
- **Open3**: Add fallback for `Open3::CommandTimeout` constant for Ruby installations where it's not available
- **Configuration**: Improve template validation to be template-specific rather than overly strict
- **Configuration**: Add YAML fallback loading when `ace-support-core` is not available

### Changed
- **Template Validation**: Directory format requires `{task_id}`, branch format requires `{id, slug}`, commit format requires `{release, task_id, slug}`
- **Configuration Loading**: Now loads from `.ace/git/worktree.yml` even when ace-support-core gem is missing

## [0.1.5] - 2025-11-04

### Fixed
- **Documentation**: Remove duplicate changelog entry for version [0.9.109] in project CHANGELOG.md
- **Documentation**: Remove duplicated retrospective template content from task 0891 retro document
- Clean up placeholder template sections that were accidentally included in documentation
- Improve professional documentation quality by eliminating redundancies

### Added
- Comprehensive review documentation including GPT-5 codex review and Google Pro review reports
- Complete documentation of all review feedback implementations and resolutions
- Enhanced project documentation with detailed review metadata and analysis

### Documentation
- Verified README.md version flag documentation is correct
- Clean changelog without duplicate entries for better maintainability
- Professional documentation standards meeting Google Pro review recommendations

## [0.1.4] - 2025-11-04

### Fixed
- **CRITICAL**: Fix CLI override flags being ignored (--no-mise-trust, --no-status-update, --no-commit, --commit-message)
- **CRITICAL**: Fix overly restrictive branch validation that rejected / characters and main/master branches
- WorktreeManager now properly respects --no-mise-trust flag before applying configuration defaults
- TaskWorktreeOrchestrator respects all CLI override flags instead of always using configuration defaults
- Branch validation now follows Git's actual branch naming rules while maintaining security
- Fix regex syntax errors in task_fetcher.rb and mise_trustor.rb character classes

### Added
- Comprehensive test coverage for branch validation with slash characters and main/master branches
- Integration tests for CLI override functionality across all override flags
- Tests for custom commit message functionality
- Enhanced CLI command tests with override flag verification

### Technical
- Updated valid_branch_name? to allow legitimate Git branch patterns (feature/login, bugfix/issue-123, etc.)
- Enhanced option merging logic in WorktreeManager and TaskWorktreeOrchestrator
- Fixed CreateCommand initialization to use fully qualified constant names
- Maintained all existing security protections while fixing functional regressions

## [0.1.3] - 2025-11-04

### Security
- **CRITICAL**: Fix path traversal vulnerability in PathExpander atom
- **CRITICAL**: Fix command injection vulnerability in MiseTrustor and TaskFetcher
- Add comprehensive input validation for task IDs and file paths
- Implement command whitelisting and argument sanitization
- Add protection against symlink-based attacks with realpath resolution

### Fixed
- Update gemspec metadata from placeholder ACE team values to correct author information
- Fix Gemfile to use eval_gemfile pattern following ACE standards
- Modernize Rakefile to use ace-test patterns instead of outdated rake/testtask
- Remove Gemfile.lock from gem directory to follow ACE conventions

### Added
- Comprehensive test coverage for all CLI commands (6/6 commands)
- Security tests for path traversal and command injection prevention
- Integration tests for molecules and organisms
- Graceful error handling when ace-taskflow is unavailable
- Helpful error messages with installation guidance
- Troubleshooting section in README.md with step-by-step solutions

### Technical
- Enhanced security validation across all user input points
- Improved dependency management with graceful degradation
- Better error reporting with specific guidance for common issues
- Comprehensive security test suite with attack vector coverage

## [0.1.2] - 2025-11-04

### Fixed
- Update dependency from ace-core to ace-support-core in gemspec
- Add required support gems (ace-support-markdown, ace-support-mac-clipboard) to Gemfile
- Resolves dependency conflicts after ace-core → ace-support-core migration

## [0.1.1] - 2025-11-04

### Fixed
- Resolve syntax and runtime errors in ace-git-worktree gem
- Fix comment formatting errors in model files (task_metadata.rb, worktree_metadata.rb)
- Fix Ruby syntax errors (hash conditional values, constant assignment in methods)
- Fix initialization order in WorktreeManager
- Implement lazy loading for CLI commands to prevent configuration validation during help

### Technical
- Update gemspec dependencies to use less restrictive version constraints
- Improve CLI command registration with lazy loading pattern

## [0.1.0] - 2025-11-04

### Added
- Initial release of ace-git-worktree gem
- Task-aware worktree creation with ace-taskflow integration
- Configuration-driven naming conventions
- Automatic mise trust execution
- Traditional worktree operations (create, list, remove, prune, switch)
- ATOM architecture implementation
- CLI interface with comprehensive commands
- Configuration cascade support via ace-core

### Features
- Task metadata fetching from ace-taskflow
- Automatic task status updates
- Worktree metadata tracking in task frontmatter
- Configurable directory and branch naming
- Support for multiple worktrees per task
- Error handling and validation
- Comprehensive test coverage

[Unreleased]: https://github.com/ace-ecosystem/ace-meta/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ace-ecosystem/ace-meta/releases/tag/v0.1.0