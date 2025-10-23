# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2025-01-23

### Added
- Initial release of ace-git-diff gem
- ATOM architecture implementation (Atoms, Molecules, Organisms, Models)
- Unified git diff functionality extracted from ace-context and ace-docs
- Global configuration support via `.ace/diff/config.yml`
- User-configurable exclude patterns (no hardcoded constants)
- Smart default behavior based on git state
- CLI with Thor for command-line usage
- Integration helpers for ace-docs, ace-review, ace-context, ace-git-commit
- Support for `diff:` configuration key across ACE gems
- Pattern-based filtering with glob pattern support
- Date and relative time resolution (e.g., "7d", "1 week ago")
- Configuration cascade with complete override (no array merging)
- Comprehensive test coverage
- Documentation and usage examples

### Features
- CommandExecutor atom for safe git command execution
- PatternFilter atom for configurable pattern matching
- DiffParser atom for parsing diff output
- DateResolver atom for date-to-commit resolution
- DiffGenerator molecule for diff generation with options
- ConfigLoader molecule for configuration cascade
- DiffFilter molecule for applying exclude patterns
- DiffOrchestrator organism for complete diff workflow
- IntegrationHelper organism for ACE gem integration
- DiffResult and DiffConfig models for data structures
- Thor CLI with smart defaults and flexible options

### Changed
- Extracted git diff logic from ace-context GitExtractor
- Extracted diff filtering from ace-docs DiffFilterer (removed hardcoded patterns)
- Extracted date resolution from ace-docs ChangeDetector

### Documentation
- README with installation and usage guide
- Example configuration file in `.ace.example/diff/config.yml`
- Comprehensive usage documentation in task folder

[Unreleased]: https://github.com/your-org/ace-git-diff/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/ace-git-diff/releases/tag/v0.1.0
