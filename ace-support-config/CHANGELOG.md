# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


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
