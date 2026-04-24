# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- Corrected `ace-config-bootstrap-root-files` to sync `ace-support-core` and record from the sandbox root layout where the bootstrap files are actually created.

## [0.16.2] - 2026-04-24

### Technical
- Expanded bootstrap feature coverage so generated `AGENTS.md` and `CLAUDE.md` files must retain ACE provenance, customization, and refresh guidance.

## [0.16.1] - 2026-04-24

### Changed
- Clarified setup-readiness documentation so `ace-llm --list-providers` remains the provider discovery command while `ace-config doctor` is documented as the quick-start readiness check, including blocker versus warning guidance and `--no-probe` usage.

## [0.16.0] - 2026-04-23

### Changed
- Renamed `ace-config init` to `ace-config sync` and removed the old `init` command path.
- Updated quick-start setup guidance to sync only `ace-llm-providers-cli` config by default because other package config should come from packaged `.ace-defaults` unless project overrides are needed.

## [0.15.0] - 2026-04-23

### Changed
- Extended `ace-config doctor` with informational project `.ace` vs package `.ace-defaults` counts, provider skill projection sync warnings, and streamed fast-check progress before the final report.
- Updated doctor provider pings to order API targets before CLI targets, use 15-second API timeouts and 30-second CLI timeouts, and distinguish timeout failures from other provider errors.

### Technical
- Added doctor coverage for config-default counts, skill sync drift, provider timeout selection, timeout row formatting, and progress ordering.

## [0.14.1] - 2026-04-23

### Changed
- Updated `ace-config doctor` live provider checks to probe deduped `_utility` plus `commit` role candidates, preserving alias labels alongside resolved provider/model names.
- Changed doctor provider-ping progress and summaries to show pass/fail/running glyphs, live TTY line updates, and explicit passed/total counts for full and partial success.

### Technical
- Added doctor regression coverage for utility-plus-commit target selection, alias-preserving ping commands, append-only non-TTY progress, and partial-success summary output.

## [0.14.0] - 2026-04-23

### Changed
- Split `ace-config doctor` output into health checks that control exit status and a concise hygiene summary, with `--hygiene` for full alias/role drift details.
- Made provider health live by default again through concurrent `ace-llm TARGET "ping" --no-fallback` checks against deduped `_utility` and `commit` role candidates; `--no-probe` disables live pings.
- Streamed human `ace-config doctor` output so utility provider ping lines show alias labels, resolved model names, and pass counts as checks complete.

### Technical
- Added doctor coverage for health-only exit status, hidden-by-default hygiene findings, expanded hygiene output, JSON health/hygiene counts, first-role base-provider distillation, and concurrent ping delegation.

## [0.13.0] - 2026-04-22

### Fixed
- Made `ace-config doctor` fast by default by replacing automatic live probes with structural role-default readiness checks; live probes now require `--probe` and target only resolved role-default providers.

### Technical
- Added doctor regression coverage for non-live defaults, opt-in provider probes, blocker-gated probes, and role-default target validation.

## [0.12.1] - 2026-04-22

### Fixed
- Extended `SetupDoctor` stale-alias detection to validate `aliases.global` provider targets (`provider:model`) in addition to provider-local model aliases.
- Made `.ace-local` artifact-hygiene detection accept equivalent `.gitignore` forms (for example `/.ace-local/`, `.ace-local`, `.ace-local/**`) instead of requiring an exact literal line.

### Technical
- Added fast-test coverage for stale global alias detection and semantic `.ace-local` ignore pattern acceptance.

## [0.12.0] - 2026-04-22

### Added
- Added `ace-config doctor` with text/JSON readiness output and `--no-probe` support for non-mutating setup diagnostics.

### Changed
- Extended `ace-config` command routing and help output to include the new `doctor` workflow.

### Technical
- Added `SetupDoctor` organism coverage for blocker/warn/skip classification and CLI contract behavior.

## [0.11.2] - 2026-04-13

### Fixed
- Made bootstrap `.gitignore` detection line-aware so commented or negated `.ace-local/` mentions no longer suppress appending the real ignore rule.

### Technical
- Added regression coverage for commented and negated `.gitignore` mentions during bootstrap merges.

## [0.11.1] - 2026-04-13

### Fixed
- Preserve existing `.gitignore` rules even when `ace-config init --force` refreshes bootstrap files.
- Anchor project-root bootstrap files (`.gitignore`, `AGENTS.md`, `CLAUDE.md`) to the detected repository root so subdirectory runs do not seed them into the wrong location.

## [0.11.0] - 2026-04-13

### Changed
- **ace-support-config v0.11.0**: Taught `ace-config init` to bootstrap project-root guidance files, include dotfile defaults, and append `.ace-local/` to existing `.gitignore` files without overwriting user-owned `AGENTS.md` or `CLAUDE.md`.

## [0.10.4] - 2026-04-13

### Changed
- **ace-support-config v0.10.4**: Standardized shared package tests to the fast-only layout and updated testing flow defaults.


## [0.10.3] - 2026-04-11

### Technical
- Migrated package tests to the `fast`/`feat` layout by moving deterministic ATOM coverage to `test/fast/` and former `test/integration/` suites to `test/feat/`.
- Updated package docs to publish the `ace-test ace-support-config` (`fast`), `feat`, and `all` contract and keep package scope deterministic-only.

## [0.10.2] - 2026-03-31

### Technical
- Added integration test coverage that stubs config template discovery in CLI flows to keep package tests deterministic across environments.

## [0.10.1] - 2026-03-31

### Fixed
- Initialize project-root handling in RubyGems verify-install workflow usage paths to avoid brittle Gemfile resolution.
- Remove Bundler runtime dependency from `ace-config` executable startup.
- Wire `ConfigDiff` local/verbose behavior through CLI execution paths.

### Technical
- Added reset support for `ConfigTemplates` cache state and regression coverage for CLI/config diff behavior.

## [0.10.0] - 2026-03-31

### Added
- Introduced `ace-config` CLI as the canonical config command with parity for `init`, `diff`, `list`, `version`, and `help`.
- Added package executable `exe/ace-config` and repo wrapper `bin/ace-config`.

### Changed
- Migrated config CLI runtime to `Ace::Support::Config` with in-package modules for CLI dispatch, template discovery, initialization, and diff operations.
- Updated package docs to present `ace-config` as the primary interface.

### Technical
- Added integration tests for `ace-config` CLI behavior and bootstrap/config initialization flows.

## [0.9.2] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.


## [0.9.1] - 2026-03-29

### Fixed
- **ace-support-config v0.9.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.9.0] - 2026-03-23

### Technical
- Removed phantom `handbook/**/*` glob from gemspec (no handbook directory exists).

## [0.8.5] - 2026-03-22

### Technical
- Updated README examples to use `resolve_file` instead of deprecated `resolve_for`.

## [0.8.4] - 2026-03-22

### Technical
- Refreshed README structure with consistent tagline, corrected package naming, installation, basic usage, API overview, and ACE project footer

## [0.8.3] - 2026-03-05

### Technical
- Document `ProjectConfigScanner` in README with molecule list and comparison table vs `ConfigFinder`

## [0.8.2] - 2026-03-05

### Fixed
- Narrow `Errno::EACCES` rescue in `ProjectConfigScanner#find_ace_dirs` to per-path scope so a permission error on one directory does not abort the entire scan

### Technical
- Add test for graceful degradation when a subdirectory is permission-restricted

## [0.8.1] - 2026-03-05

### Fixed
- Expand `SKIP_DIRS` in `ProjectConfigScanner` to include `.bundle`, `_legacy`, `.ace-local`, `.ace-tasks`, `.ace-taskflow` preventing false-positive config discovery in monorepo-ignored paths
- Memoize `scan` results to avoid repeated full filesystem traversals on multiple calls
- Deduplicate symlinked `.ace` directories using `File.realpath` tracking
- Use portable positional flags form for `Dir.glob` (`File::FNM_DOTMATCH` as positional arg)

## [0.8.0] - 2026-03-05

### Added
- `ProjectConfigScanner` molecule for downward project tree traversal to discover all `.ace` config folders across a monorepo

## [0.7.2] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.7.1] - 2026-02-12

### Fixed
- Stabilize performance test threshold for `resolve_namespace` overhead (2.0x → 3.0x) to reduce CI flakiness

## [0.7.0] - 2026-01-27

### Added
- Path rules support for configuration resolution with glob pattern matching
- Project scanning capability to discover nested package configurations
- `PathRuleMatcher` atom for matching file paths against glob patterns
- Support for glob arrays in path rules configuration

### Changed
- Enhanced `ConfigResolver` to support path-based configuration splitting
- Refactored config resolution to enable scoped configuration per file path

## [0.6.0] - 2026-01-11

### Breaking Changes
- **Gem renamed** from `ace-config` to `ace-support-config`
- **Namespace changed** from `Ace::Config` to `Ace::Support::Config`
- Update gemspec dependency from `ace-config ~> 0.5` to `ace-support-config ~> 0.6`
- Update require statements from `require "ace/config"` to `require "ace/support/config"`
- Update class references from `Ace::Config` to `Ace::Support::Config`

### Migration Guide
```ruby
# Before
require 'ace/config'
config = Ace::Config.create
Ace::Config.test_mode = true

# After
require 'ace/support/config'
config = Ace::Support::Config.create
Ace::Support::Config.test_mode = true
```

For gem maintainers:
```ruby
# In your gemspec, change:
spec.add_dependency 'ace-config', '~> 0.5'
# To:
spec.add_dependency 'ace-support-config', '~> 0.6'

# In your code, change:
require 'ace/config'
# To:
require 'ace/support/config'

# And update class references:
Ace::Config.create → Ace::Support::Config.create
Ace::Config.test_mode = → Ace::Support::Config.test_mode =
```

## [0.5.1] - 2026-01-05

### Fixed
- Stabilize performance tests and adjust thresholds for CI consistency
- Improve command default behavior and fix flaky test

## [0.5.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.2.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.4.3] - 2026-01-03

### Changed
- Optimized performance test execution time from 11.77s to 1.64s (85% improvement)
- Reduced loop iterations in performance tests (100-1000 → 10-50)
- Reduced cascade depth from 5 to 2 levels for faster tests
- Reduced file count from 50 to 10 in file-based tests
- Extracted iteration count constants (CASCADE_ITERATIONS, GLOB_ITERATIONS, FINDER_ITERATIONS, TEST_MODE_ITERATIONS)
- Implemented median-based timing metrics instead of average for robustness with small sample sizes
- Added deep cascade correctness test to maintain coverage at depth 5

### Technical
- Added performance measurement helpers (`measure_iterations`, `median_time`, `format_time`)
- Separated constants for I/O-bound vs CPU-bound operations tuning

## [0.4.2] - 2026-01-02

### Added
- Test mode for faster test execution (`Ace::Config.test_mode = true`)
- `ACE_CONFIG_TEST_MODE` environment variable for CI/test runner integration (case-insensitive)
- `mock_config` parameter to `Ace::Config.create` for providing mock data in tests
- `test_mode` parameter to `Ace::Config.create` for explicit test mode control
- Thread-safe test mode state using `Thread.current` for parallel test environments
- Test mode short-circuit in `resolve_type` and `find_configs` methods

## [0.4.1] - 2025-12-31

### Technical
- Add comprehensive edge case and custom path tests (Task 157.10)

## [0.4.0] - 2025-12-30

### Added
- `merge()` method on Config model as the primary method for merging configuration data
- `with()` remains as an alias for backward compatibility

## [0.3.0] - 2025-12-30

### Added
- `resolve_namespace(*segments, filename: "config")` method to ConfigResolver for simplified namespace-based config resolution
  - Uses `File.join` for cross-platform path construction
  - Sanitizes segments (flatten, compact, stringify, strip whitespace, reject empty)
  - Documented in README and usage.md
- Runtime dependency on `ace-support-fs` for filesystem utilities (PathExpander, ProjectRootFinder, DirectoryTraverser)
- `class_get_env` class method on PathExpander for consistent ENV access pattern across class and instance methods
- Documentation section on directory naming conventions (`.ace-defaults/` vs `.ace/` vs `.ace.example/`)
- `glob_to_regex` now supports bracket character classes (`[a-z]`, `[abc]`)
- Documentation for `resolve_for` clarifying it's intentionally not memoized
- `Date` class to permitted YAML classes for parsing date values in config files

### Changed
- Reorganized ConfigResolver methods: all public methods grouped together before private section

### Breaking Changes
- None

### Fixed
- Gemfile.lock version mismatch (was 0.1.0, now correctly shows 0.2.0)

## [0.2.0] - 2025-12-28

### Added
- Initial release of ace-config gem
- Generic configuration cascade with customizable folder names
- `Ace::Config.create` factory method for creating resolvers
- `Ace::Config.virtual_resolver` factory method for virtual filesystem view
- Configurable `config_dir` and `defaults_dir` parameters
- Support for gem defaults via `gem_path` parameter
- Deep merging with configurable array strategies (:replace, :concat, :union)
- Project root detection with customizable markers
- Path expansion with environment variable and protocol support
- YAML parsing with error handling
- Virtual config resolver for cascade filesystem view
- Memoization for `resolve()` and `get()` methods in ConfigResolver
- Windows compatibility via `File::ALT_SEPARATOR` support

### Fixed
- ConfigFinder uses stable `start_path` instead of mutable `Dir.pwd`
- `find_file`/`find_all_files` now respect `use_traversal` parameter
- YamlLoader `merge_strategy` parameter properly applied
- PathExpander raises exception instead of returning error hash

### Changed
- Gemspec excludes `test/` directory from built gem
- ENV access extracted to protected `get_env` method for testability

### Components Extracted from ace-support-core
- **Atoms**: DeepMerger, YamlParser, PathExpander
- **Molecules**: ConfigFinder, DirectoryTraverser, ProjectRootFinder, YamlLoader
- **Organisms**: ConfigResolver, VirtualConfigResolver
- **Models**: Config, CascadePath
- **Errors**: ConfigNotFoundError, YamlParseError, PathError, MergeStrategyError

## [0.1.0] - 2025-12-28

### Added
- Initial gem structure
- Public API design with `Ace::Config.create` factory
- Full configuration cascade implementation
- Zero runtime dependencies (stdlib only)
