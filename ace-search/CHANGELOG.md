# Changelog

All notable changes to ace-search will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.21.7] - 2026-03-15

### Fixed
- Updated E2E content-search test to use unambiguous search pattern avoiding false substring match failures

## [0.21.6] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.21.5] - 2026-03-13

### Technical
- Updated canonical search workflow skill metadata for bundled workflow execution.

## [0.21.4] - 2026-03-13

### Changed
- Updated canonical search research skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.21.3] - 2026-03-13

### Changed
- Replaced provider-specific Codex execution metadata on the canonical `as-search-run` skill with a unified canonical skill body that declares arguments, variables, and explicit workflow-execution guidance.
- Limited provider-specific forking for `as-search-run` to Claude frontmatter only.

## [0.21.2] - 2026-03-12

### Added
- Added a public `--count` CLI flag and threaded it through search option building so count-oriented ripgrep execution is available through `ace-search`.

### Changed
- Updated search E2E runner guidance to use deterministic project-root paths for file and count mode coverage.

### Technical
- Added CLI and option-builder regression coverage for the new count flag.

## [0.21.1] - 2026-03-12

### Changed
- Updated handbook search-agent examples to use current `ace-*/handbook/**/*` paths instead of legacy shared handbook locations.

## [0.21.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-search-run` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

## [0.20.0] - 2026-03-10

### Added
- Added canonical handbook-owned search and research skills for feature research, multi-search analysis, and direct search execution.


## [0.19.8] - 2026-03-05

### Changed
- Search result parsing now selects file-only mode when `files_with_matches` is requested, avoiding text-parse assumptions.

## [0.19.7] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.19.6] - 2026-02-22

### Changed
- Migrate CLI from registry/default-routing to single-command entrypoint (`Dry::CLI.new(Ace::Search::CLI::Commands::Search).call`).
- Treat no-argument invocation as help (`--help`) in `exe/ace-search`.

### Fixed
- Handle `--version` directly in the search command path, ensuring version output works in single-command mode.

### Technical
- Update workflow/guide references to use `ace-search "pattern"` (no `search` subcommand).
- Align CLI routing and integration tests with single-command behavior.

## [0.19.4] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.19.3] - 2026-02-19

### Technical
- Namespace workflow instructions into search/ subdirectory with updated wfi:// URIs

## [0.19.2] - 2026-01-31

### Fixed
- Reset config in test setup to prevent test isolation issues

## [0.19.1] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.19.0] - 2025-01-14

### Added
- Migrate CLI to Hanami pattern (task 213)
  - Move command implementation from `commands/` to `cli/commands/` directory
  - Update module namespace to `CLI::Commands::Search` following Hanami/dry-cli standard
  - Clean up model requires by moving them from `cli.rb` into the command file

### Fixed
- Fix critical search_path bug where local variable was used instead of instance variable
  - Changed `search_path = options[:search_path]` to `@search_path = options[:search_path]`
  - This ensures resolve_search_path receives the correct search path value

### Technical
- Update CLI pattern documentation to reflect Hanami standard
- Remove obsolete `commands/` directory structure


## [0.18.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Search` dry-cli command class
  - Deleted `search_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.18.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.02)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Added `ace-support-core ~> 0.19` dependency for dry-cli infrastructure
  - All user-facing commands, options, and behavior remain identical
  - Single-command usage supported (`ace-search pattern`)
  - Numeric option type-conversion handled for parity with Thor implementation
  - Standardized `KNOWN_COMMANDS` pattern across dry-cli gems

## [0.17.0] - 2026-01-05

### Added
- Thor CLI migration with standardized command structure
- ConfigSummary display for effective configuration with sensitive key filtering
- Comprehensive CLI help documentation across all commands
- self.help overrides for custom command descriptions

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Migrated from OptionParser to Thor framework
- Added method_missing for default subcommand support

### Fixed
- CLI routing and dependency management for feature parity
- --help dispatch for all ACE commands
- Resolved -v flag conflict and search interactive mode bug
- Add handle_no_command_error for command name patterns
- Addressed PR #123 review findings for Medium and higher priority issues

## [0.16.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.15.2] - 2026-01-01

### Changed

* Add configurable timeout in `.ace-defaults/search/config.yml`
* Centralize fd executor timeout from config instead of hardcoded value

## [0.15.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.15.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.14.0] - 2025-12-29

### Changed
- Migrate ProjectRootFinder dependency from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.13.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/search/config.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

### Fixed
- **Debug Check Consistency**: Standardized `debug?` method to use `== "1"` pattern across all gems

## [0.12.0] - 2025-12-27

### Changed

- **Dependency Migration**: Migrated GitScopeFilter to ace-git package
  - Now uses `Ace::Git::Atoms::GitScopeFilter` from ace-git (~> 0.3)
  - Removed local `Ace::Search::Molecules::GitScopeFilter` implementation
  - Centralizes Git file scope operations across ACE ecosystem

## [0.11.4] - 2025-11-16

### Changed

- **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  - Provides access to latest PromptCacheManager and infrastructure improvements
  - Maintains compatibility with standardized ACE ecosystem patterns

## [0.11.3] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems


## [0.11.2] - 2025-10-25

### Changed
- Implement code review suggestions for clarity and documentation
- Add design rationale comment to SearchPathResolver explaining ENV var validation
- Add upgrade note in README linking to Troubleshooting section
- Document DebugLogger threading context and caching behavior
- Condense CLI warning message for non-existent paths

## [0.11.1] - 2025-10-25

### Added
- Centralized DebugLogger module for unified debug output formatting
- Path validation warnings for non-existent explicit search paths
- Comprehensive troubleshooting guide in README
- DEBUG environment variable documentation with example output

### Technical
- Edge case test coverage for SearchPathResolver (symlinks, non-existent paths, relative paths)
- Improved debug output consistency across executors
- 21 additional test cases (17 DebugLogger, 4 edge cases)

## [0.11.0] - 2025-10-25

### Added
- Project-wide search by default: `ace-search` now searches entire project from root regardless of current directory
- Optional search path argument: `ace-search "pattern" [SEARCH_PATH]` to limit scope when needed
- SearchPathResolver atom with 4-step resolution: explicit path → PROJECT_ROOT_PATH env → project root detection → current directory fallback
- Support for `PROJECT_ROOT_PATH` environment variable to override project root detection
- Integration with `Ace::Core::Molecules::ProjectRootFinder` for automatic project root detection
- Display search path in output context for transparency

### Fixed
- Fixed search_path propagation through UnifiedSearcher option builders (critical bug)
- Fixed inconsistent search results when running from different directories
- Execute ripgrep/fd from search directory using chdir for correct .gitignore processing

### Changed
- **BEHAVIOR CHANGE**: Default search scope is now project-wide instead of current directory
  - To maintain old behavior (search current directory only), use: `ace-search "pattern" ./`
- CLI banner updated to show optional SEARCH_PATH argument: `ace-search [options] PATTERN [SEARCH_PATH]`

### Technical
- Add comprehensive DEBUG output for troubleshooting search path resolution

## [0.10.0] - 2025-10-14

### Added
- Standardize Rakefile test commands and add CI fallback

## [0.9.0] - 2025-10-08

### Added

**Core Architecture**
- Initial release of ace-search gem with full ATOM architecture
- Complete migration from dev-tools/exe/search to standalone gem
- Atoms: ripgrep_executor, fd_executor, pattern_analyzer, result_parser, tool_checker
- Molecules: preset_manager, git_scope_filter, dwim_analyzer, time_filter, fzf_integrator
- Organisms: unified_searcher, result_formatter, result_aggregator
- Models: search_result, search_options, search_preset

**CLI Features**
- Full CLI compatibility with original search tool
- All search modes: file, content, hybrid with auto-detection (DWIM)
- Pattern matching: case-insensitive, whole-word, multiline
- Context options: before, after, and surrounding lines
- Filtering: glob patterns, include/exclude paths, git scopes (staged/tracked/changed)
- Output formats: text (with clickable terminal links), JSON, YAML
- Interactive mode: fzf integration for result selection
- Time-based filtering: search files modified since/before timestamps

**Configuration System**
- Integration with ace-core for configuration cascade
- Support for all CLI flags as configuration defaults in `.ace/search/config.yml`
- Preset system: organize common searches in `.ace/search/presets/*.yml`
- Example configuration and presets included in `.ace.example/`
- Configuration cascade: defaults → global config → project config → preset → CLI flags

**Development Tools**
- Binstub (`bin/ace-search`) for development use
- Comprehensive test suite: 43 tests, 158 assertions, 0 failures
- Flat test structure following ACE patterns (test/atoms/, test/molecules/, etc.)
- Test runner script for workspace context
- Integration with ace-test-support

**Documentation**
- Comprehensive README with usage examples
- Full usage guide with CLI flag reference
- Migration guide from dev-tools/exe/search
- Architecture documentation following ATOM patterns
- Example configurations and presets

### Changed

**Improvements Over Legacy**
- File search now matches full paths, not just filenames
- Configuration supports all CLI flags as defaults (not possible in legacy)
- Presets organized in separate .yml files for better maintainability
- Direct ripgrep/fd calls for better performance
- Clean separation of concerns with ATOM architecture

### Removed

- Editor integration (removed - use terminal's built-in file:line clicking instead)
- Custom project_root_detector (replaced with ace-core's ConfigDiscovery)

### Fixed

- Pattern analyzer properly detects file globs vs content regex
- Result parser handles all ripgrep output formats (text, JSON, column numbers)
- Tool availability checking works across different environments

### Migration Notes

From dev-tools/exe/search (0.8.0):
- All CLI flags work identically (except editor integration)
- Use bin/ace-search for development instead of dev-tools/exe/search
- Configuration moved from custom files to .ace/search/config.yml
- Presets moved to .ace/search/presets/ directory
- Performance maintained or improved with direct backend calls

### Dependencies

- ace-core (~> 0.9) for configuration and utilities
- ripgrep (external) for content search
- fd (external) for file search
- fzf (external, optional) for interactive selection

[0.9.0]: https://github.com/your-org/ace-meta/releases/tag/ace-search-v0.9.0


## [0.19.5] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
