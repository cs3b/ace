# Changelog

All notable changes to ace-core will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.12.0] - 2025-12-29

### Changed
- Migrate internal components to use `Ace::Support::Fs` directly instead of local aliases
- Update ConfigFinder, EnvLoader, EnvironmentManager, FileAggregator, PromptCacheManager, and VirtualConfigResolver to import from ace-support-fs

### Removed
- **BREAKING**: Remove backward compatibility aliases for filesystem utilities
  - Removed `Ace::Core::Atoms::PathExpander` (use `Ace::Support::Fs::Atoms::PathExpander`)
  - Removed `Ace::Core::Molecules::ProjectRootFinder` (use `Ace::Support::Fs::Molecules::ProjectRootFinder`)
  - Removed `Ace::Core::Molecules::DirectoryTraverser` (use `Ace::Support::Fs::Molecules::DirectoryTraverser`)
  - Removed related test files for backward compatibility wrappers

## [0.11.1] - 2025-11-17

### Added

- **PromptCacheManager Error Handling**: Enhanced robustness and validation
  - Added `PromptCacheError` custom exception for clearer error reporting
  - Comprehensive argument validation for all public methods with descriptive error messages
  - File operation error handling for permissions, disk space, and I/O issues
  - Configurable timestamp formatting via optional `timestamp_formatter` parameter
  - Metadata schema validation with required field checks (`timestamp`, `gem`, `operation`)
  - Optional validation support with `validate: false` parameter for flexibility
  - Field type validation ensuring data integrity
  - Enhanced test coverage: 17 tests, 55 assertions covering all new functionality

### Changed

- **PromptCacheManager Refactoring**: Simplified to stateless utility class
  - Removed instance methods and `initialize` - all methods are now class methods
  - Eliminated unnecessary state (gem_name, project_root) from instance variables
  - Clarified stateless nature of the utility in class documentation
  - Updated all tests to use stateless API (no breaking changes to public API)
  - Improved code clarity and maintainability per code review feedback

## [0.11.0] - 2025-11-16

### Added

- **PromptCacheManager Molecule**: Standardized prompt cache management for ace-* gems
  - Provides `create_session(gem_name, operation)` for creating timestamped session directories
  - Provides `save_system_prompt(content, session_dir)` for saving system prompts
  - Provides `save_user_prompt(content, session_dir)` for saving user prompts
  - Provides `save_metadata(metadata, session_dir)` for saving session metadata
  - Uses standardized structure: `.cache/{gem}/sessions/{operation}-{timestamp}/`
  - Uses standardized file names: `system.prompt.md`, `user.prompt.md`, `metadata.yml`
  - Integrates with ProjectRootFinder for git worktree support
  - Comprehensive test coverage: 9 tests, 25 assertions

### Changed

- **Code Style Improvement**: Refactored PromptCacheManager class method structure
  - Updated from `private_class_method :save_prompt` to `class << self` block pattern
  - Improved readability and follows common Ruby idioms
  - Enhanced code organization for better maintainability

## [0.10.1] - 2025-11-15

### Added

- **Git Worktree Detection Test**: Added `test_finds_git_worktree_root` to ProjectRootFinder test suite
  - Verifies ProjectRootFinder correctly handles `.git` as both file (worktree) and directory (main repo)
  - Creates test worktree structure with `.git` file containing gitdir reference
  - Confirms project root detection works from nested directories in worktrees
  - Supports ace-review cache path resolution fix (task 111)

### Changed

- **Test Coverage**: Enhanced ProjectRootFinder test suite for worktree compatibility
  - All 262 tests pass with comprehensive worktree scenario coverage
  - No breaking changes to existing functionality

## [0.10.0] - 2025-10-26

### Added

- **Unified Path Resolution System**: PathExpander converted from module to class with instance-based API
  - Factory methods: `PathExpander.for_file(source_file)` and `PathExpander.for_cli()` with automatic context inference
  - Instance method: `resolve(path)` supporting source-relative, project-relative, absolute, env vars, and protocol URIs
  - Protocol URI support via plugin system: `register_protocol_resolver(resolver)` for ace-nav integration
  - Comprehensive test suite: 76 new tests covering all path resolution scenarios
  - Full backward compatibility: All existing class methods (expand, join, dirname, basename, absolute?, relative, normalize) preserved
  - Updated README with usage examples and documentation

### Changed

- **PathExpander Architecture**: Converted from module to class for context-aware path resolution
  - Enables efficient resolution of multiple paths from single source with inferred context
  - Provides consistent path handling across all ACE tools
  - Supports wfi://, guide://, tmpl://, task://, prompt:// protocol URIs

## [0.9.3] - 2025-10-08

### Changed

- **Test Structure Reorganization**: Reorganized tests for consistency
  - Moved `test/ace/core_test.rb` → `test/core_test.rb`
  - Moved `test/config_discovery_path_resolution_test.rb` → `test/integration/`
  - Aligns with standardized flat ATOM structure across all ACE packages

## [0.9.2] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.1] - 2025-10-06

### Added
- **Git diff formatting support** in `OutputFormatter`
  - Added diffs section rendering in `format_markdown` (with ```diff blocks)
  - Added diffs section rendering in `format_xml` (<diffs> with CDATA)
  - Added diffs section rendering in `format_markdown_xml` (<diff> with attributes)
  - Supports rendering git diff output from ace-context

### Changed
- `OutputFormatter` now handles `data[:diffs]` array in all output formats

## [0.9.0] - 2025-10-05

Initial release with core functionality for ACE ecosystem.
