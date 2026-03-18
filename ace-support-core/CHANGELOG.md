# Changelog

All notable changes to ace-core will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.28.0] - 2026-03-18

### Changed
- Migrated CLI infrastructure classes (`Error`, `Base`, `StandardOptions`, `RegistryDsl`, `VersionCommand`, `HelpCommand`) to ace-support-cli. Consumers now use `Ace::Support::Cli::*` namespace directly.
- Removed thin wrappers (`HelpConcise`, `DefaultRouting`, `HelpRouter`, `CommandGroups`) that are no longer needed.
- Updated ace-support-cli dependency constraint from `~> 0.3` to `~> 0.6`.
- `ConfigSummaryMixin` remains in ace-support-core (depends on `Ace::Core::Atoms::ConfigSummary`).

## [0.27.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.26.0] - 2026-03-15

### Changed
- Migrated CLI support modules from `Ace::Core::CLI::DryCli::*` to `Ace::Core::CLI::*` with new files under `lib/ace/core/cli/`.
- Replaced `dry-cli` runtime dependency with `ace-support-cli`.
- Updated `lib/ace/core.rb` requires to load new CLI module paths.
- Added backward-compatible `DryCli` constant shims and `dry_cli/` require stubs for downstream consumers pending migration.

### Removed
- Deleted original `lib/ace/core/cli/dry_cli/` implementation (formatter monkey-patches, `ArgvCoalescer`).

## [0.25.4] - 2026-03-13

### Added
- Added `dev/spikes/option_parser_cli_spike.rb` and `dev/spikes/run_option_parser_cli_spike.rb` to validate OptionParser end-to-end coercion, positional parsing, and error behavior for the upcoming `ace-support-cli` migration.

## [0.25.3] - 2026-03-12

### Fixed
- Re-exported `Ace::Core::Atoms::CommandExecutor` from `ace/core` so callers using the shared core entrypoint can access the command executor without an extra direct require.

## [0.25.2] - 2026-03-04

### Changed
- PromptCacheManager session paths now use `.ace-local/<short-name>/sessions`.


## [0.25.1] - 2026-03-04

### Changed
- Remove dependency on `ace-b36ts` and `ace-support-items` (no longer needed after moving `TmpWorkspace` to `ace-support-items`)

## [0.25.0] - 2026-02-26

### Added
- `ArgvCoalescer` utility for coalescing repeated CLI flags into comma-separated values, working around dry-cli's `type: :array` limitation

## [0.24.1] - 2026-02-23

### Removed
- Removed legacy ConfigResolver wrapper with deprecated search_paths/file_patterns API
- Removed legacy integration tests superseded by ace-support-config

### Technical
- Updated internal dependency version constraints to current releases

## [0.24.0] - 2026-02-22

### Added
- `HelpCommand.build` helper for creating standard top-level help commands in dry-cli registries

### Changed
- Drop DWIM default routing from `DefaultRouting` — empty args now show help instead of routing to a default command
- Simplify `DefaultRouting` and `HelpRouter` to thin compatibility shims
- Remove DWIM-dependent integration tests from usage_formatter_test

## [0.23.2] - 2026-02-22

### Added
- Integration tests for two-tier help routing (-h concise vs --help full) via DefaultRouting.start

### Technical
- Documented dry-cli 1.4.1 version coupling in COMPATIBILITY comments for monkey-patch modules

## [0.23.1] - 2026-02-22

### Fixed
- Clear `@_original_arguments` after use in help method to prevent state leakage across CLI calls
- Add nil-safe navigation (`command&.description`) for subcommand description access
- Standardize hidden check to use `respond_to?(:hidden)` guard in all usage_formatter locations
- Replace `instance_variable_set` on external dry-cli Node objects with local Hash mapping for command name tracking
- Fix CHANGELOG entry ordering (0.23.0 was appended at end instead of after [Unreleased])

## [0.23.0] - 2026-02-22

### Added
- Two-tier CLI help: `-h` shows concise format, `--help` shows full ALL-CAPS reference (NAME, USAGE, DESCRIPTION, ARGUMENTS, OPTIONS, EXAMPLES)
- `help_formatter.rb` - Monkey-patch `Dry::CLI::Banner` with ALL-CAPS sections and duplicate command name fix in examples
- `help_concise.rb` - Concise `-h` format with compact options (no descriptions), max 3 examples, footer
- `usage_formatter.rb` - Monkey-patch `Dry::CLI::Usage` with COMMANDS header, first-line-only descriptions, command group support
- `command_groups.rb` - Mixin for CLI registries to define COMMAND_GROUPS for grouped `--help` output
- `standard_options.rb` - Canonical description constants (QUIET_DESC, VERBOSE_DESC, DEBUG_DESC, HELP_DESC)
- Updated `default_routing.rb` to distinguish `-h` (concise) from `--help` (full) at registry level

### Fixed
- Duplicate command name in examples (Banner strips prefix automatically)
- Hidden subcommands now filtered from help output

### Changed
- `default_routing.rb` routes `-h` to concise format, `--help` to full format
- `base.rb` wires all new formatter modules
- Renamed `Ace::Core::CLI` class to `Ace::Core::FrameworkCLI` to avoid collision with CLI module
- Fixed ace-framework exe path and help output formatting

## [0.22.2] - 2026-01-31

### Fixed
- Preserve original message in `CLI::Error#message` while keeping "Error:" prefix only in `to_s`
- Fix Ruby 3 keyword argument handling in ConfigSummaryMixin tests (use explicit hash braces)
- Fix VersionCommandTest to use `AceTestCase` base class for `capture_stdout` access
- Fix `test_version_command_in_registry` to properly extend `Dry::CLI::Registry` module

## [0.22.1] - 2026-01-31

### Fixed
- Move GemClassMixin inside ConfigSummaryMixin to fix test isolation constant reference issues

## [0.20.1] - 2026-01-16

### Changed
- **ContextMerger moved to ace-bundle**: ContextMerger relocated to ace-bundle package as BundleMerger (task 206)
  - Removed `lib/ace/core/molecules/context_merger.rb`
  - Functionality now provided by `Ace::Bundle::Molecules::BundleMerger`
  - Tests removed from ace-support-core test suite

## [0.20.0] - 2026-01-11

### Changed
- **ContextChunker moved to ace-context**: ContextChunker and BoundaryFinder relocated to ace-context package (only consumer)
- **Config key renamed**: `chunk_limit` renamed to `max_lines` for clarity
- Removed orphaned `context_chunker` section from settings.yml

## [0.19.1] - 2026-01-10

### Added
- **DefaultRouting Module**: Shared CLI routing logic for dry-cli based gems
  - `Ace::Core::CLI::DryCli::DefaultRouting` module with `start` and `known_command?` methods
  - Eliminates duplicate routing code across CLI gems
  - Provides consistent default command routing behavior
  - Used by ace-docs, ace-git-commit, ace-prompt, and others

### Removed
- **Thor base class deleted**: `Ace::Core::CLI::Base` removed as all gems now use dry-cli (task 179.16)
  - Thor dependency removed from gemspec
  - `lib/ace/core/cli/base.rb` deleted
  - All CLI gems now use `Ace::Core::CLI::DryCli::Base` module instead

## [0.19.0] - 2026-01-07

### Added
- **dry-cli Infrastructure**: Foundation for dry-cli based CLIs (task 179.01)
  - `Ace::Core::CLI::DryCli::Base` module with common CLI patterns
    - Standard option checks (`verbose?`, `quiet?`, `debug?`)
    - Exit code helpers (`exit_success`, `exit_failure`)
    - Debug logging (`debug_log`)
    - Option validation (`validate_required!`)
    - Hash formatting (`format_pairs`)
    - Reserved flags constant (`RESERVED_FLAGS`)
  - `Ace::Core::CLI::DryCli::ConfigSummaryMixin` for config display integration
    - `display_config_summary` method with quiet/verbose mode support
    - `GemClassMixin` variant with gem class configuration support
    - Integration with existing `Ace::Core::Atoms::ConfigSummary`
  - `Ace::Core::CLI::DryCli::VersionCommand` helper for version commands
    - `VersionCommand.build` factory for creating command classes
    - `VersionCommand.module` for creating version mixins
    - Supports both class-level and proc-based version strings
  - Comprehensive test coverage: 3 test files with 26+ tests
  - dry-cli ~> 1.1 dependency added to gemspec
- **convert_types helper**: Type conversion utility for dry-cli options
  - Converts string options to specified types (integer, float, boolean)
  - Handles dry-cli's string-only option return values
  - Supports batch type conversion with keyword arguments

### Changed
- Updated `lib/ace/core.rb` to require dry-cli infrastructure modules
- Standardized dry-cli dependency to ~> 1.0 across all gems

## [0.18.0] - 2026-01-05

### Added
- `ConfigSummary.display_if_needed` method to conditionally display configuration
  - Checks for help flags (`--help`, `-h`) before displaying config
  - Added `ConfigSummary.help_requested?` helper to detect help flag presence
  - Prevents config summary from polluting help text output

### Changed
- ConfigSummary now requires `--verbose` flag to display configuration details
  - Standard command output remains clean and uncluttered
  - Debug configuration available when explicitly requested
  - Improved help text clarity by separating concerns

### Fixed
- Config summary output appearing with `--help` commands
  - Configuration now only shows when both not in help mode AND verbose is enabled
  - Added tests for `help_requested?` detection logic

## [0.17.0] - 2026-01-04

### Added
- `ConfigSummary` atom for standardized CLI configuration output to stderr
  - Displays effective configuration state with config-diffing (only non-default values)
  - Sensitive key filtering (keys ending with: token, password, secret, credential, key, api_key)
  - Nested key flattening with dot notation (e.g., `llm.provider=google`)
  - Allowlist support via `summary_keys` parameter
  - Quiet mode support (suppress output with `--quiet`)
  - Deterministic sorted key output
  - 18 comprehensive tests covering all functionality

## [0.16.0] - 2026-01-03

### Added
- `BoundaryFinder` atom for semantic boundary detection in XML-structured content
  - Parses content into semantic blocks (`<file>`, `<output>` elements)
  - Ensures XML elements are never split mid-element during chunking
  - Documents whitespace handling behavior
- `ContextChunker` integration tests for semantic boundary splitting

### Changed
- `ContextChunker.split_into_chunks` now uses semantic boundaries when content contains XML elements
  - Falls back to line-based splitting for plain text content
  - Single large elements kept whole even if exceeding chunk limit

## [0.15.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.2.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.14.2] - 2026-01-01

### Changed

* Add configurable timeouts and limits in `.ace-defaults/core/config.yml`
* Add `configured_timeout` to CommandExecutor for timeout configuration

## [0.14.1] - 2025-12-30

### Changed

* Add ace-config dependency for configuration cascade delegation

## [0.14.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.13.0] - 2025-12-30

### Changed
- **Configuration Cascade Migration**: Now powered by ace-config gem
  - Configuration resolution delegated to ace-config with `.ace` and `.ace-defaults` directories
  - Added resolver caching for improved performance (avoids repeated FS traversal)
  - Added `Ace::Core.reset_config!` to clear cached resolver for test isolation

### Deprecated
- `Ace::Core.config(search_paths:, file_patterns:)` parameters are deprecated
  - Use `Ace::Config.create(config_dir:, defaults_dir:)` for custom paths
  - Deprecated parameters emit warning and are ignored
  - **Will be removed in a future minor version**
- `Ace::Core::Organisms::ConfigResolver.new(search_paths:)` is deprecated
  - Backward-compatible wrapper maintains old behavior with deprecation warning
  - Use new API with `config_dir:` and `defaults_dir:` parameters
  - **Will be removed in a future minor version**

### Added
- **Runtime Dependencies**: ace-config (~> 0.2), ace-support-fs (~> 0.1)
  - ace-config provides generic configuration cascade management
  - ace-support-fs provides filesystem utilities (added in v0.12.0)
- **Migration Fallback**: `.ace.example` fallback for gem defaults during migration period
- **Test Coverage**: Added deprecation warning and caching tests (10 new tests)

### Migration Guide

**Old API (deprecated, will be removed soon):**
```ruby
# Custom search paths (deprecated)
config = Ace::Core.config(search_paths: ['./.custom', '~/.myapp'])

# ConfigResolver with search_paths (deprecated)
resolver = Ace::Core::Organisms::ConfigResolver.new(
  search_paths: ['./.ace', '~/.ace', '/defaults'],
  file_patterns: ['*.yml']
)
```

**New API (recommended):**
```ruby
# Use Ace::Config directly for custom paths
resolver = Ace::Config.create(
  config_dir: ".custom",
  defaults_dir: ".custom-defaults"
)
config = resolver.resolve

# Standard ace configuration (no changes needed)
config = Ace::Core.config  # Uses .ace and .ace-defaults
```

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
