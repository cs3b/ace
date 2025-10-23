# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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

[Unreleased]: https://github.com/your-org/ace-support-markdown/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/ace-support-markdown/releases/tag/v0.1.0
