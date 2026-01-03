# Changelog

All notable changes to ace-test-runner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.6.2] - 2026-01-03

### Changed

* **Test Performance Optimization**: Reduce test suite execution time by 46% (3.3s → 1.78s)
  * Convert 2 E2E integration tests to use mocked subprocess execution
  * Retain 1 representative E2E test for genuine CLI validation
  * Improve assertions per second from 105 to 194 (85% improvement)
  * Add E2E Coverage Analysis documenting risk mitigation

### Technical

* Enhanced code comments explaining E2E test rationale
* Added performance measurement commands to documentation
* Documented CI benchmark/regression guard (5s threshold)

## [0.6.1] - 2025-12-30

### Changed

* Replace ace-support-core dependency with ace-config for configuration cascade
* Migrate from Ace::Core to Ace::Config.create() API

## [0.6.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.5.0] - 2025-12-29

### Changed
- Migrate ProjectRootFinder dependency from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.4.0] - 2025-12-27

### Added
- **ADR-022 Configuration Pattern**: Migrate configuration to load defaults from `.ace.example/` and merge with user overrides
  - Defaults loaded from `.ace.example/test-runner/config.yml` at runtime
  - User config from `.ace/test/runner.yml` merged over defaults (deep merge)
  - Removed hardcoded defaults from Ruby code
  - New `normalize_config` method for consistent configuration normalization

### Fixed
- **Test Isolation**: Improved test isolation for config-dependent tests
  - Tests now properly stub configuration loading to avoid interference
  - Better cleanup of configuration state between tests

### Technical
- Optimized integration tests with stubbing and better config handling

## [0.3.0] - 2025-12-20

### Added
- **Package Argument Support**: Run tests for any package in the mono-repo from any directory
  - `ace-test ace-context` runs all tests in ace-context package
  - `ace-test ace-nav atoms` runs only atom tests in ace-nav
  - `ace-test ./ace-search` supports relative paths
  - `ace-test /path/to/ace-docs` supports absolute paths
  - `ace-test ace-context/test/foo_test.rb` supports package-prefixed file paths
  - `ace-test ace-context/test/foo_test.rb:42` supports package-prefixed file paths with line numbers
  - Automatically detects and changes to package directory for test execution
  - Restores original directory after test completion
  - New `PackageResolver` atom for package name/path resolution
  - Integration tests for package argument functionality

### Changed
- CLI help updated with package examples
- README updated with package argument documentation

## [0.2.1] - 2025-12-13

### Fixed

- **File Not Found Error Message**: Improved error message when target file doesn't exist
  - Changed from confusing "Unknown target: <path>" to clear "File not found: <path>"
  - Added helpful guidance: "Make sure you're running from the correct directory or use an absolute path"
  - Distinguishes between file paths (contain "/" or end with ".rb") and unknown target names
  - Location: `lib/ace/test_runner/molecules/pattern_resolver.rb:27-29,76-78`

## [0.2.0] - 2025-11-17

### Fixed
- **Explicit File Execution**: Fixed ace-test to respect explicit file path arguments and bypass group execution
  - Running `ace-test test/atoms/foo_test.rb` now executes ONLY that file, not configured test groups
  - File arguments always take precedence over group targets
  - Supports single files, multiple files, and file:line syntax
  - Dramatically improves feedback loop during development and debugging
  - Technical: Modified `TestOrchestrator#should_execute_sequentially?` to check for explicit files before entering group execution mode

### Technical
- Strengthened integration test assertions for explicit file execution
  - Replaced non-deterministic boolean assertions with specific expected values
  - Added explicit target configuration for grouped execution tests
  - Improved test documentation explaining behavior with config cascade

## [0.1.7] - 2025-11-13

### Added
- **Skipped Test Reporting**: Added comprehensive skipped test reporting to console output and suite summaries
  - Displays count and visual indicators for skipped tests in execution summaries
  - Shows detailed skipped test information including reason when available
  - Includes skipped tests in final statistics with skip percentage
  - Helper methods for status icons and skipped test text formatting

### Changed
- **Refactoring**: Extracted helper methods for status icons and skipped text handling
  - Consolidated status icon generation into reusable helper methods
  - Improved code organization for test result display formatting
  - Enhanced maintainability of output formatting logic

### Technical
- Updated documentation references from ace-core to ace-support-core
- Improved code hygiene based on code review feedback

## [0.1.6] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Changed dependency from `ace-test-support` to `ace-support-test-helpers`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.1.5] - 2025-10-08

### Added

- **Smoke Test Pattern**: Added support for root-level smoke tests
  - New pattern: `smoke: "test/*_test.rb"` for basic sanity checks
  - Added to `unit` test group as first item
  - Enables discovery of module-level tests (e.g., `core_test.rb`, `nav_test.rb`)
  - Updated documentation and example configurations

## [0.1.4] - 2025-10-08

### Changed

- **Test Structure Migration**: Migrated to flat ATOM structure
  - From: `test/ace/test_runner/atoms/`, `test/unit/molecules/`
  - To: `test/atoms/`, `test/molecules/`, `test/models/`
  - Consolidated nested test structures into standard flat organization
  - Updated require paths to match new structure

- **Configuration Patterns**: Added support for `commands` and `edge` test patterns
  - `commands: "test/commands/**/*_test.rb"` for CLI command tests
  - `edge: "test/edge/**/*_test.rb"` for edge case tests
  - Updated both global config and example config

## [0.1.3] - 2025-10-08

### Added

- **Configuration Cascade**: Integrated ace-core for hierarchical configuration discovery
  - Automatically searches parent directories for `.ace/test/runner.yml`
  - Enables project-wide configuration from repository root
  - Graceful fallback if ace-core is not available
  - Location: `lib/ace/test_runner/molecules/config_loader.rb:6-10,103-114`

- **Dual Execution Modes**: New high-level execution mode configuration
  - `execution.mode: grouped` - Run test groups sequentially with headers
  - `execution.mode: all-at-once` - Run all tests together (default, faster)
  - Replaces low-level `sequential_groups_mode` with user-friendly controls
  - Location: `lib/ace/test_runner/models/test_configuration.rb:57-60`

- **Group Isolation Control**: New `group_isolation` boolean configuration
  - `true` - Run each group in separate subprocess (slower, better isolation)
  - `false` - Run groups in same process (15.6x faster for simple tests)
  - Only applies when `mode: grouped`
  - Location: `lib/ace/test_runner/models/test_configuration.rb:62-68`

### Fixed

- **Boolean Configuration Handling**: Fixed `group_isolation: false` being ignored
  - Previous code used `||` operator which treated `false` as falsy
  - Changed to explicit nil checks to properly handle boolean values
  - Location: `lib/ace/test_runner/models/test_configuration.rb:62-68`

- **Test Accumulation in In-Process Mode**: Fixed test count inflation in grouped mode
  - Cleared `Minitest::Runnable.runnables` between groups to prevent re-running previous tests
  - Was showing 90 tests instead of 65 (re-running atoms when executing molecules)
  - Location: `lib/ace/test_runner/molecules/in_process_runner.rb:77-85`

- **Grouped Mode Default Target**: Added automatic "all" target when none specified
  - `mode: grouped` without explicit target now defaults to running "all" group
  - Prevents need to always specify target when using grouped mode
  - Location: `lib/ace/test_runner/organisms/test_orchestrator.rb:51-54,263-273`

### Changed

- **Configuration Structure**: Simplified execution configuration
  - Old: `sequential_groups_mode: subprocess | in-process`
  - New: `group_isolation: true | false` (clearer intent)
  - Example configs updated in `.ace.example/test-runner/config.yml`

- **Formatter Initialization**: Disabled duplicate group headers
  - Set `show_groups: false` to prevent `on_test_complete` from printing headers
  - Avoids duplicate headers when using `SequentialGroupExecutor`
  - Headers now only come from `on_group_start`/`on_group_complete`
  - Location: `lib/ace/test_runner/organisms/test_orchestrator.rb:40-42`

### Known Limitations

- **In-Process Mode Progress Dots**: Progress dots only show for first group in grouped in-process mode
  - Subsequent groups show correct test counts and results but no progress dots
  - This is a Minitest::Reporters state management limitation
  - Workaround: Use `group_isolation: true` for full progress output
  - Test results remain 100% accurate

## [0.1.2] - 2025-10-08

### Fixed

- **Progress Formatter**: Improved test name pattern matching
  - Updated regex to handle underscores in test names (e.g., `test_create_idea_with_git_commit`)
  - Previously only matched `test_\w+` which stopped at the first underscore
  - Now matches `test_[\w_]+` to capture full test names with multiple underscores
  - Location: `lib/ace/test_runner/formatters/progress_formatter.rb:168`

- **Minitest::Reporters Setup**: Fixed reporter initialization timing
  - Moved reporter setup to before loading test files
  - Ensures reporter is configured before Minitest initializes
  - Prevents conflicts with test file initialization
  - Location: `lib/ace/test_runner/molecules/in_process_runner.rb:77-80`

### Changed

- Progress formatter now properly handles ANSI-colored output from Minitest::Reporters
- Improved documentation of regex pattern for test result line matching

## [0.1.1] - 2025-10-08

### Fixed
- **InProcessRunner Minitest::Reporters initialization**: Fixed `undefined method 'fetch' for StringIO` error
  - Changed `Minitest::Reporters::DefaultReporter.new($stdout)` to use `io:` parameter
  - Fixes error when running tests with direct/in-process execution mode
  - Location: `lib/ace/test_runner/molecules/in_process_runner.rb:208`

- **Double test execution**: Fixed tests running twice (once by ace-test, once by Minitest autorun)
  - Preserved `ENV['MT_NO_AUTORUN']` value instead of deleting it in InProcessRunner cleanup
  - Changed main executable to use `exit!` instead of `exit` to skip at_exit handlers
  - Prevents Minitest autorun from executing after ace-test completes
  - Locations:
    - `lib/ace/test_runner/molecules/in_process_runner.rb:30,121-125`
    - `exe/ace-test:299-301`

## [0.1.0] - 2025-10-05

Initial release with test execution and reporting capabilities.
