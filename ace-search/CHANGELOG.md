# Changelog

All notable changes to ace-search will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
