# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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