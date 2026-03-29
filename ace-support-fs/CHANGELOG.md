# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.1] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.3.0] - 2026-03-23

### Technical
- Removed phantom `handbook/**/*` glob from gemspec (no handbook directory exists).

## [0.2.3] - 2026-03-22

### Technical
- Updated README dependency example to use the current `~> 0.2` version constraint.

## [0.2.2] - 2026-03-22

### Technical
- Refreshed README structure with consistent tagline, overview, basic usage, and ACE project footer

## [0.2.1] - 2026-03-08

### Fixed
- Ignore `PROJECT_ROOT_PATH` overrides when the configured root does not contain the active `start_path`, preventing unrelated workspace roots from leaking into traversal boundaries.

### Technical
- Added regression coverage for environment-root fallback behavior in `ProjectRootFinder`.
- Stabilized directory traversal molecule tests by isolating no-project-root fixtures from ambient system-level config directories.

## [0.2.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.1.0] - 2025-12-28

### Added

- Initial release extracting filesystem utilities from ace-support-core and ace-config
- **PathExpander** atom with:
  - Instance-based API (`for_file`, `for_cli`) for context-aware path resolution
  - Protocol URI support (wfi://, guide://, tmpl://, etc.) with pluggable resolver
  - Environment variable expansion ($VAR and ${VAR} formats)
  - Source-relative (./) and project-relative path resolution
  - Thread-safe protocol resolver registration with Mutex
  - Backward-compatible class methods (expand, join, dirname, basename, etc.)
  - Testability helper (`class_get_env` for ENV stubbing in tests)
- **ProjectRootFinder** molecule with:
  - Project root detection by marker files (.git, Gemfile, package.json, etc.)
  - Thread-safe caching with Mutex
  - PROJECT_ROOT_PATH environment variable support
  - Instance and class method APIs
  - Testability helper (`env_project_root` for ENV stubbing)
- **DirectoryTraverser** molecule with:
  - Config directory discovery from current to project root
  - Cascade priority building for nearest-wins resolution
  - Home directory inclusion with lower priority
  - Configurable config directory name (default: `.ace`)
- **PathError** exception class for protocol resolution failures

### Design Decisions

- Exception-based error handling (raise PathError) following ace-config pattern
- Thread-safety with instance variables + Mutex (not class variables)
- DEFAULT_MARKERS constant for project root markers
- `config_dir` parameter name (not `config_dir_name`)
- `class_get_env` for testability without subprocess overhead
- No Windows support (not tested or supported)
