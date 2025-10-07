# Changelog

All notable changes to ace-nav will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.9.2] - 2025-10-07

### Changed
- **Test maintainability improvement**: Version tests now validate semantic versioning format instead of exact version values
  - Prevents test failures on every version bump
  - Uses regex pattern `/\A\d+\.\d+\.\d+/` to validate version format

## [0.9.1] - 2025-10-05

### Added
- Subdirectory/prefix pattern support for protocols
  - Patterns ending with `/` now list all files with that prefix (e.g., `prompt://create/` lists create-task, create-project, etc.)
  - Actual subdirectories are also listed when they exist (e.g., `prompt://guidelines/` lists all files in guidelines/ directory)
- Auto-list mode for intuitive patterns
  - Patterns ending with `/` automatically enable list mode (no need for `--list` flag)
  - Wildcard patterns (`*` or `?`) automatically enable list mode
  - Protocol-only URIs continue to auto-list (e.g., `prompt://`)

### Fixed
- Duplicate entries in results when using subdirectory patterns
- Pattern matching now correctly handles both prefix matching and subdirectory listing

### Changed
- CLI now intelligently detects patterns that should return multiple results

## [0.9.0] - Previous Release

- Initial release with core navigation functionality
- Protocol-based resource discovery
- Support for workflows, templates, prompts, and guides
- Integration with ace-* gems and local configurations