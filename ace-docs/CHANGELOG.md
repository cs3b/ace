# Changelog

All notable changes to ace-docs will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.2] - 2025-10-15

### Fixed

- **Date to Commit Resolution**: Fixed critical bug where `diff` command couldn't resolve dates to git commit SHAs
  - `git diff 2025-10-14..HEAD` (bad revision) → now resolves to proper commit SHA
  - Added `resolve_since_to_commit()` to convert dates to commit references
  - Uses parent of first commit since date for inclusive diffs

- **Git Root Path Resolution**: All git commands now execute from repository root
  - Fixes path resolution issues when running from subdirectories
  - Added `git_root` helper with proper `chdir` handling

- **Folder Structure for Diff Sessions**: Each diff now gets organized session folder
  - Structure: `.cache/ace-docs/diff-{timestamp}/`
  - Contains: `repo-diff.patch` (raw diff), `analysis.md` (report), `metadata.yml` (session info)
  - Better artifact organization for large diffs

## [0.3.1] - 2025-10-15

### Added

- **Frontmatter Initialization**: `ace-docs update` now creates frontmatter on files without it
  - Auto-infers `doc-type` from file path (README.md → reference, *.wf.md → workflow, etc.)
  - Requires `purpose` field for new frontmatter
  - Seamless workflow: initialize and update in single command

### Fixed

- **YAML Formatting**: Removed duplicate `---` markers in frontmatter output
- **Update Command**: Now handles files without existing frontmatter

### Changed

- **Documentation**: Comprehensive updates to usage.md
  - Added `version` command documentation
  - Detailed `analyze` command section with all options
  - Enhanced `validate` command with `--semantic` flag documentation
  - Fixed `update` command syntax examples (--set key:value)
  - Updated configuration section with LLM and ace-lint settings
  - Enhanced troubleshooting with analyze-specific issues
  - Added complete workflow examples

## [0.3.0] - 2025-10-14

### Added

- **Batch Analysis Command**: New `ace-docs analyze` command for LLM-powered documentation analysis
  - Accepts file lists and filter options (--needs-update, --type, --freshness)
  - Automatic time range detection from document staleness
  - LLM compaction via ace-llm-query subprocess integration
  - Markdown reports organized by impact level (HIGH/MEDIUM/LOW)
  - Cache management with timestamped analysis reports
  - Support for exclude-renames and exclude-moves options

- **Command Architecture Refactoring**: Extracted all CLI commands to testable classes
  - DiffCommand, UpdateCommand, ValidateCommand, AnalyzeCommand
  - Improved separation of concerns and testability
  - Return proper exit codes for all commands

- **ace-lint Integration**: Validation now delegates to ace-lint when available
  - Subprocess integration with graceful fallback
  - Parse and display ace-lint output properly

- **Configuration System**: Integrated with ace-core config cascade
  - Added Ace::Docs.config method with defaults
  - Flat configuration structure following ACE standards
  - Example config with all available settings

### Changed

- **CLI Structure**: Refactored to delegate all commands to separate command classes
- **Documentation**: Updated README with batch analysis examples and new features

### Technical

- Added comprehensive ATOM architecture components (atoms, molecules, models)
- TimeRangeCalculator and DiffFilterer atoms for date and diff handling
- TimeRangeFinder, DiffAnalyzer, ReportFormatter molecules
- AnalysisReport model for structured report data
- CompactDiffPrompt for LLM prompt generation

## [0.2.0] - 2025-10-14

### Added

- **ADR Lifecycle Workflows**: Comprehensive workflow instructions for complete ADR lifecycle management
  - `create-adr.wf.md`: Guide for creating new Architecture Decision Records
  - `maintain-adrs.wf.md`: Workflow for evolution, archival, and synchronization of existing ADRs
  - Embedded templates for ADR creation, deprecation notices, evolution sections, and archive README
  - Cross-references between workflows for seamless lifecycle management
  - Real examples from October 2025 ADR archival session
  - Decision criteria for archive vs evolve vs scope update actions
  - Research process guidance using grep to verify pattern usage
  - Integration with ace-docs validation tools

### Changed

- **update-docs.wf.md**: Added "Architecture Decision Records" section with references to both ADR workflows

## [0.1.1] - 2025-10-14

### Added
- Implement proper document type inference hierarchy
- Standardize Rakefile test commands and add CI fallback

### Fixed
- Resolve symlink paths correctly on macOS
- Fix document discovery and ignore patterns

### Technical
- Add document-specific guidelines to update-docs workflow
- Add missing usage.md and document remaining work as future enhancements
- Add proper frontmatter with git dates to all managed documents

## [0.1.0] - 2025-10-13

### Added
- Initial release of ace-docs gem
- Document status tracking with YAML frontmatter
- Document type classification (guide, architecture, reference, etc.)
- Batch analysis and reporting capabilities
- Integration with ace-core for configuration management
- CLI commands for status checking and document updates
- Support for automatic document updates based on frontmatter metadata
