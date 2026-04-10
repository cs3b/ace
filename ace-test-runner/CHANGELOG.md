# Changelog

All notable changes to ace-test-runner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Added a suite-completeness regression guard in `PackageResolverTest` that fails when `.ace/test/suite.yml` omits testable packages discovered from the mono-repo.

## [0.19.3] - 2026-04-07

### Technical
- Expanded suite process-monitor timeout coverage for the full-suite integration queue scenario and improved failure-window robustness under concurrent execution.

## [0.19.2] - 2026-04-07

### Technical
- Stabilized suite process-monitor integration coverage by increasing the timeout budget for the queued-package timeout scenario under full-suite load.

## [0.19.1] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

### Added
- **ace-test-runner v0.19.0**: Added suite-level per-package timeout support via `ace-test-suite --timeout` and `test_suite.timeout`, allowing hung package runs to fail and free their worker slot instead of stalling the rest of the suite.

### Fixed
- **ace-test-runner v0.19.0**: Terminate active package process groups on suite timeout or interrupt so `ace-test-suite` no longer leaves orphaned `ace-test` subprocesses behind after stuck or cancelled runs.

## [0.18.1] - 2026-03-29

### Fixed
- **ace-test-runner v0.18.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.18.0] - 2026-03-24

### Changed
- Updated README intro to highlight Minitest wrapping, smart grouping, and cross-package resolution.
- Updated gemspec description to mention Minitest explicitly.
- Streamlined handbook to defer skill catalog to ace-test; fixed capitalization in workflow table.
- Re-recorded getting-started demo with real `ace-b36ts` test runs and suite execution.
- Simplified getting-started guide installation section.

## [0.17.2] - 2026-03-23

### Changed
- Refreshed `README.md` structure and navigation links to align with the current package README layout pattern.

## [0.17.1] - 2026-03-22

### Changed
- Replaced the getting-started demo placeholder command with real `ace-test` workflow commands (`--help` and atoms run) so the recording demonstrates actual package usage.

## [0.17.0] - 2026-03-22

### Changed
- Rewrote README as concise landing page (~60 lines, down from 275)
- Updated gemspec summary and description to match new tagline

### Added
- New `docs/getting-started.md` tutorial-style guide
- New `docs/usage.md` with full CLI reference
- New `docs/handbook.md` with skills and workflows catalog
- Demo VHS tape and GIF in `docs/demo/`

## [0.16.1] - 2026-03-22

### Fixed
- Suite report-dir now includes the package subdirectory so the result aggregator finds reports at `<root>/<package>/<timestamp>/` instead of flat `<root>/<timestamp>/`.

## [0.16.0] - 2026-03-20

### Changed
- Tightened E2E verifier contracts for `TS-TEST-001` and `TS-TEST-002` with explicit `.exit`, command-capture, and report-artifact evidence requirements to improve assertion reliability.

## [0.15.17] - 2026-03-18

### Fixed
- Fixed CLI option precedence so `--report-dir` now properly overrides config defaults.

## [0.15.16] - 2026-03-18

### Fixed
- Fixed explicit `--report-dir` resolution for package-scoped and single-file execution so report artifacts are written exactly where the user requested.

### Technical
- Clarified E2E failure-propagation cleanup requirements by documenting fixture removal for intentional-failure injection scenarios.

## [0.15.15] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.15.14] - 2026-03-17

### Fixed
- Updated CLI routing help tests for direct command invocation to align with current help and exit behavior.

## [0.15.13] - 2026-03-15

### Fixed
- Made E2E report-files.txt capture instructions explicit with `find`/`ls -R` for reliable artifact listing
- Updated suite E2E sandbox to preserve real monorepo root path so `ace-test-suite` can discover packages

## [0.15.12] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.15.11] - 2026-03-13

### Fixed
- Updated `ace-test` to propagate test failures via the process exit code and made `ace-test-suite` emit a clear configuration error when suite YAML is missing or malformed.
- Ensured `ace-test-suite` E2E sandbox setup includes the suite configuration so full-suite aggregation scenarios run with actual package orchestration.

## [0.15.10] - 2026-03-12

### Changed
- Updated the core `ace-test` E2E runner/verifier instructions to capture explicit command and report-file evidence for single-file and group-scoped executions instead of relying on fragile stdout phrasing.

## [0.15.9] - 2026-03-04

### Changed
- Default `ace-test` report storage now uses centralized `.ace-local/test/reports/<short-package>/<runid>/` paths
- Suite report discovery and subprocess report routing now use configured report roots instead of package-local `test-reports/`

### Fixed
- Report cleanup now handles nested centralized layouts (`<root>/<package>/<runid>/`) in addition to legacy flat layouts
- Report path resolution and failed-package hints now prioritize centralized report roots with legacy `test-reports` fallback
- Test configuration writable-directory validation now accepts nested report paths when an ancestor directory is writable

### Technical
- Added centralized report directory resolver atom and focused regression coverage for suite aggregation/duration fallback behavior
- Updated defaults, fixtures, and documentation to `.ace-local/test/reports` conventions

## [0.15.8] - 2026-02-27

### Fixed
- Strip `ACE_ASSIGN_ID` and `ACE_ASSIGN_FORK_ROOT` from subprocess environments in `test_executor`, `process_monitor`, and rake-task invocation paths to prevent assignment context leakage into test runs
- Add regression coverage in `rake_task_test` verifying assignment context variables are unset for spawned test processes

## [0.15.7] - 2026-02-24

### Technical
- Patch release requested for `ace-test-runner` with no functional code changes since `0.15.6`

## [0.15.6] - 2026-02-23

### Fixed
- Enabled ace-support-core integration (was disabled with stale TODO since v0.10)

### Technical
- Updated internal dependency version constraints to current releases

## [0.15.5] - 2026-02-22

### Changed
- Migrate `ace-test` from registry/default-routing to single-command dry-cli entrypoint while preserving no-arg "run all tests" behavior
- Handle `--version` directly in the test command path for single-command mode

### Technical
- Remove legacy routing constants/scaffolding from `CLI` module and update CLI routing tests for single-command invocation

## [0.15.3] - 2026-02-12

### Fixed
- Replace shell-out to `hostname` with `Socket.gethostname` in test report environment capture
  - Backtick `hostname` fails on systems without `inetutils` (e.g., minimal Arch installs)
  - `Socket.gethostname` is Ruby stdlib — works everywhere with no external dependency
  - Fixes `ace-test-suite` reporting 1 error per package despite all tests passing

## [0.15.2] - 2026-01-31

### Fixed
- **Profile verbose mode**: Fix `--profile` to inject `--verbose` into Minitest ARGV instead of Ruby interpreter
  - Ruby's `--verbose` flag only sets `$VERBOSE = true` (Ruby warnings), not Minitest verbose mode
  - Minitest needs `--verbose` in ARGV to enable per-test timing output for profiling
  - Fixes `ace-test package --profile N` not showing slowest tests
  - Affects: multiple files, single files, and line-number test execution
- **Result parser test_time pattern**: Support both Minitest::Reporters and standard Minitest verbose formats
  - Minitest::Reporters format: `  test_name                     PASS (0.00s)`
  - Standard Minitest format: `ClassName#test_name = 0.00 s = .`

## [0.15.1] - 2026-01-31

### Added
- Expanded default test patterns: smoke, commands, cli, prompts, fixtures, support, edge
- Unit group now includes all expanded patterns for comprehensive test discovery

## [0.15.0] - 2026-01-31

### Added
- **Execution Mode CLI Flags**: New `--run-in-sequence`/`--ris` and `--run-in-single-batch`/`--risb` flags
  - `--run-in-sequence` (default): Run test groups sequentially (atoms → molecules → organisms)
  - `--run-in-single-batch`: Run all tests together in a single batch, bypassing grouped execution
  - `ace-test-suite` now passes `--run-in-single-batch` to each package for cleaner output

## [0.14.0] - 2026-01-31

### Fixed
- **Profiling with Grouped Execution**: Bypass grouped mode when `--profile` is used without a specific target
  - Previously, `ace-test package --profile N` showed 0.000s for all tests due to grouped execution
  - Now runs all tests in a single batch when profiling without target, enabling accurate timing
  - Group-specific profiling (`ace-test package group --profile N`) unchanged

## [0.13.0] - 2026-01-31

### Added
- **Slowest-First Package Scheduling**: Packages with longest expected duration now start first
  - New `DurationEstimator` reads historical duration from `test-reports/latest/summary.json`
  - Orchestrator sorts by expected duration (descending), then priority
  - Prevents slow packages from becoming bottlenecks at end of parallel test runs

## [0.12.6] - 2026-01-31

### Fixed
- **Test Suite Timing Accuracy**: Display managers now use `results[:duration]` instead of wall-clock `status[:elapsed]`
  - Previously reported times included subprocess startup overhead (~5s per package)
  - Now shows actual Minitest execution duration from `summary.json`
  - Affected files: `DisplayManager`, `SimpleDisplayManager`

## [0.12.5] - 2026-01-30

### Changed
- **DisplayHelpers Docstring Clarified**: Improved documentation to explain `color()`/`colorize()` relationship
- **Dynamic Package Column Width**: Package names now use dynamically calculated width based on actual package list

### Removed
- **Dead Code Cleanup**: Removed unused `build_summary_text` method and its tests

### Technical
- Added `create_display_manager` factory tests for orchestrator

## [0.12.4] - 2026-01-30

### Fixed
- **Orphaned Tests Discovered**: Suite tests in `test/suite/` were not being run by test runner
  - Moved to `test/integration/suite/` where they are now discovered and executed
  - Fixed require paths for new location
  - Updated test assertions to match current `DisplayHelpers` output format

## [0.12.3] - 2026-01-30

### Changed
- **Progress Mode Aligned with Simple Mode**: Consistent column ordering across display modes
  - Status icon first: `·` (waiting), `⋯` (running), `✓`/`?`/`✗` (completed)
  - Time second (right-aligned 5.2f format)
  - Package name without brackets (25 chars, left-justified)
  - Progress bar and count for running state
  - Columnar stats for completed: `N tests  M asserts  F fail`

## [0.12.2] - 2026-01-30

### Changed
- **Summary Output Reorder**: Status line now appears last for better visibility
  - Skipped packages shown as compact single line at top: `Skipped: pkg1 (2), pkg2 (14)`
  - Stats (duration, packages, tests, assertions) in middle
  - Pass/fail status (`✓ ALL TESTS PASSED`) at bottom, always visible
  - Simplified stat format: removed totals, shows just `passed, failed`

## [0.12.1] - 2026-01-30

### Changed
- **Improved Output Format**: Columnar format for better readability
  - Status icon first (✓/✗/?) for easy visual scanning
  - Time second (right-aligned) to spot slow packages
  - Package name without brackets (cleaner)
  - Abbreviated labels: `tests`, `asserts`, `fail`
  - Example: `✓   1.46s  ace-support-core  221 tests  601 asserts  0 fail`

## [0.12.0] - 2026-01-30

### Added
- **Simple Output Mode**: New default output mode with line-by-line results (task 244)
  - `ace-test-suite` now produces clean, pipe-friendly output by default
  - One line per package as it completes (printed in completion order)
  - No ANSI cursor control or screen clearing
  - Works cleanly when piped: `ace-test-suite 2>&1 | cat`
  - New `SimpleDisplayManager` class for agent-friendly output
  - Columnar format: `✓  1.46s  package-name  65 tests  186 asserts  0 fail`
  - Status first (✓/✗/?), time second for easy scanning

- **Progress Flag**: `--progress` flag enables animated progress bars
  - Enables original animated ANSI display with live progress bars
  - Skips redundant final results table (results shown inline during updates)
  - Preserves same summary format and exit codes

- **DisplayHelpers Module**: Extracted shared display formatting logic
  - Shared `build_summary_text` and `render_summary` methods
  - Reduces code duplication between display managers

- **Exception-based Exit Codes**: Improved CLI error handling
  - Commands now use exception-based exit codes for cleaner control flow

### Changed
- **Default Display Mode**: Switched from animated to simple output mode
  - Better for CI/CD pipelines, log files, and agent consumption
  - Use `--progress` flag for interactive terminal experience

### Fixed
- Fixed timestamp generator for new compact ID format
- Fixed test require paths and fixtures in DisplayHelpersTest

## [0.11.0] - 2026-01-22

### Changed
- Move testing guides to ace-test package (16 files)
- Removed .ace-defaults/nav/protocols/guide-sources/ace-test-runner.yml
- Testing guides now consolidated in ace-test package

## [0.10.6] - 2026-01-22

### Changed
- Update references to new ace-test package for consolidated testing documentation

### Technical
- Lower Ruby version requirement to >= 3.2.0
- Update for ace-bundle integration

## [0.10.5] - 2026-01-16

### Changed
- Updated package references from ace-context to ace-bundle (task 206)

## [0.10.4] - 2026-01-15

### Changed
- Migrate CLI commands to Hanami pattern
  - Move `commands/test.rb` to `cli/commands/test.rb`
  - Update namespace from `Commands::Test` to `CLI::Commands::Test`
  - Update test file references for new namespace

## [0.10.3] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli command
  - Merged business logic directly into `Test` dry-cli command class
  - Deleted `test_command.rb` wrapper file
  - Simplified architecture by removing unnecessary delegation layer

## [0.10.2] - 2026-01-08

### Fixed
- Improved report path resolution robustness and documentation
- Use relative paths in Markdown output and cleanup FailedPackageReporter

### Technical
- Add coverage for FailedPackageReporter relative path fallback

## [0.10.1] - 2026-01-08

### Fixed
- Fixed broken `guide://` protocol links in handbook guides (added `.g` suffix for `.g.md` files)
- Fixed relative links from `handbook/guides/testing/` to `docs/testing-patterns.md`
- Removed placeholder `<rewrite_this>` tags from meta-documentation guide
- Cleaned up citation artifacts (e.g., `citeturn0search3`, unicode citations) from TDD guides

## [0.10.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.12)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command class (test)
  - All tests pass (155 tests, 2 skips for help TTY issues)

## [0.9.0] - 2026-01-07

### Changed
- **BREAKING**: Test report directories changed from 14-character timestamps to 6-character Base36 compact IDs
  - Example: `20251129-143000/` → `i50jj3/`
  - Reports are temporary, so no backward compatibility needed
- Migrate TimestampGenerator to use ace-timestamp for Base36 compact IDs
- Simplified configuration loading using ADR-022 config cascade pattern

### Added
- Dependency on ace-timestamp for compact ID generation

## [0.8.0] - 2026-01-05

### Added
- Thor CLI migration with ConfigSummary display

### Changed
- Adopted Ace::Core::CLI::Base for standardized options


## [0.7.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

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


## [0.15.4] - 2026-02-22

### Fixed
- Stripped duplicate command name prefix from test examples
- Standardized quiet, verbose, debug option descriptions to canonical strings
