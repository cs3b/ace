# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-03-23

### Technical
- Removed phantom `handbook/**/*` glob from gemspec (no handbook directory exists).

## [0.2.2] - 2026-03-22

### Changed
- Refreshed README structure with an explicit Purpose section and consistent support-library framing.
- Updated README testing commands to use `ace-test` instead of `bundle exec` invocations.
- Added a "Part of ACE" footer link to the package README.

## [0.2.1] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.2.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.1.3] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems


## [0.1.2] - 2025-10-23

### Improved

- **README examples now include educational comments**
  - Added "why" explanations to all 6 real-world examples
  - Comments explain reasoning behind patterns (validation, error handling, etc.)
  - Clarifies ATOM architecture usage and best practices
  - Explains StandardError rescue patterns and ensure block usage

- **Example 5 refactored to use begin/rescue/ensure pattern**
  - Replaced multiple rescue blocks with ensure block for rollback
  - Uses success flag to track operation status
  - Cleaner, more maintainable error handling pattern
  - Guarantees cleanup even with non-linear control flow

- **Documentation sync strategy documented**
  - Added "Maintaining Documentation" section to README
  - Created comprehensive CONTRIBUTING.md with API sync guidelines
  - Documents the automated README validation approach
  - Provides checklist for API changes and documentation updates

### Added

- **Automated README example validation** (`test/integration/readme_examples_test.rb`)
  - 8 test cases validating all README code examples
  - Tests run as part of standard test suite
  - Catches documentation/code mismatches automatically
  - Ensures examples stay in sync with API evolution
  - Validates Quick Start, API Documentation, and Real-World Examples

### Fixed

- **Corrected API parameter names in README**
  - Fixed `validate: true` → `validate_before: true` for DocumentEditor.save!()
  - Ensures documentation accurately reflects actual API
  - Caught by new automated README validation tests

## [0.1.1] - 2025-10-23

### Documentation

- **Enhanced README with comprehensive real-world examples** (390+ lines)
  - Example 1: Task management system (auto-fixing with backup/validation)
  - Example 2: Documentation updates (bulk operations, nested frontmatter)
  - Example 3: Complex multi-section operations (complete task workflow)
  - Example 4: Safe file writing with custom validation
  - Example 5: Error handling and recovery (rollback, retry logic)
  - Example 6: Batch operations with progress tracking
  - All examples based on actual ace-taskflow and ace-docs implementations
  - Demonstrates error handling patterns, validation rules, and safety features

## [0.1.0] - 2025-10-18

### Added
- Initial release
- Frontmatter extraction and serialization atoms
- Section extraction using Kramdown AST
- Document validation with hardcoded rules
- Frontmatter and section editing molecules
- Safe file writing with backup/rollback
- Document editor with fluent API
- Immutable document models
- Test suite with 100% atom coverage

### Features
- ATOM architecture (Atoms, Molecules, Organisms, Models)
- Exact string matching for section identification
- Atomic file operations with temp file + move pattern
- Performance: <10ms frontmatter updates, <50ms section edits
- Zero-corruption design with validation and rollback

[Unreleased]: https://github.com/cs3b/ace/compare/v0.2.2...HEAD
[0.2.2]: https://github.com/cs3b/ace/compare/v0.2.1...v0.2.2
[0.2.1]: https://github.com/cs3b/ace/compare/v0.2.0...v0.2.1
[0.2.0]: https://github.com/cs3b/ace/compare/v0.1.2...v0.2.0
[0.1.2]: https://github.com/cs3b/ace/compare/v0.1.1...v0.1.2
[0.1.1]: https://github.com/cs3b/ace/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/cs3b/ace/releases/tag/v0.1.0
