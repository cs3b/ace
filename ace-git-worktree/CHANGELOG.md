# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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