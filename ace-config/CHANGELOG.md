# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
