# Changelog

All notable changes to ace-docs will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.2] - 2025-10-16

### Changed

- Refactored `ace-docs analyze` from document-centric to general-purpose change analyzer
  - Removed document embedding and ace-context integration from analysis workflow
  - Simplified analysis prompts to focus on diff summarization without doc-update assumptions
  - Updated system prompt to output general change analysis instead of doc recommendations

### Technical

- Removed `create_context_markdown` and `load_context_md` methods from DocumentAnalysisPrompt
- Cleaned up metadata to remove context_saved references
- Simplified prompt structure for better performance and clarity

## [0.4.1] - 2025-10-16

### Added

- **Enhanced System Prompt**: Improved prompt engineering following best practices
  - Added ACE Documentation Diff Analyzer role definition
  - Self-check requirement for unmapped diff hunks
  - Uncertainty handling and guardrails against hallucination
  - Table format for Recommended Updates section
  - Output length constraints (≤ 2 lines per change)
  - Prompt versioning (v1.1 — 2025-10-16)
  - Concrete example showing expected output format

- **User Prompt Template**: New documentation file `handbook/prompts/document-analysis.md`
  - Documents prompt structure with examples
  - Explains XML embedding format for context
  - Shows ace-context integration patterns

- **ace-context Integration**: Optional structured context embedding
  - Uses `Ace::Context.load_auto()` with markdown-xml format
  - Embeds document and related files using XML tags (`<file path="...">`)
  - Creates `context.yml` configuration in analyze cache directory
  - Graceful fallback when ace-context unavailable (optional dependency)

### Changed

- **Cache Structure**: Now includes `context.yml` for full reproducibility
  ```
  .cache/ace-docs/analyze-{timestamp}/
    ├── repo-diff.diff        # Filtered raw diff
    ├── context.yml           # ace-context configuration (NEW)
    ├── prompt-system.md      # System prompt used
    ├── prompt-user.md        # User prompt with embedded context
    ├── analysis.md           # LLM analysis
    └── metadata.yml          # Session info + context config reference
  ```

- **Prompt Builder**: Modified `DocumentAnalysisPrompt.build()` to accept `cache_dir` parameter
- **Analyze Command**: Creates session directory before LLM analysis for context.yml generation

### Technical

- Added `Ace::Docs.debug?` method for debug mode detection
- Enhanced metadata.yml to track context configuration
- ace-context is optional (graceful degradation when unavailable)

## [0.4.0] - 2025-10-16

### Added

- **Unified Analyze Command**: Replaced separate diff/analyze commands with single focused analyze command
  - Real LLM-powered analysis (not just formatted diff)
  - Uses `Ace::LLM::QueryInterface` directly (no subprocess overhead)
  - Extracts subject.diff.filters from frontmatter automatically
  - Uses document context (keywords, preset, type, purpose) for intelligent analysis
  - Generates structured recommendations: Summary, Changes by Priority, Recommended Updates

- **ace-nav Protocol Integration**: Externalized prompts using ace-nav protocol
  - System prompt: `handbook/prompts/document-analysis.system.md`
  - Loadable via `ace-nav prompt://document-analysis.system --content`
  - Users can override at project (`.ace/`) or user (`~/.ace/`) level
  - Protocol configuration in `.ace.example/nav/protocols/prompt-sources/ace-docs.yml`

- **Prompt Transparency**: Both prompts saved to analyze cache
  - `prompt-system.md` - System prompt sent to LLM
  - `prompt-user.md` - User prompt with document context
  - Full reproducibility and debugging support
  - Metadata tracks which prompts were used

### Changed

- **File Extensions**: Renamed `.patch` → `.diff` for git diff files
- **Prompt Architecture**: Split into system + user prompts
  - System prompt: Role, instructions, output format
  - User prompt: Document metadata, context, diff content
  - Better LLM behavior (system prompts weighted differently)

- **Cache Structure**: New analyze session format
  ```
  .cache/ace-docs/analyze-{timestamp}/
    ├── repo-diff.diff        # Filtered raw diff
    ├── prompt-system.md      # System prompt used
    ├── prompt-user.md        # User prompt used
    ├── analysis.md           # LLM analysis
    └── metadata.yml          # Session info + prompt references
  ```

### Removed

- **Old diff Command**: Removed misleading diff command (created "analysis.md" with just formatted diff)
- **Old analyze Command**: Removed incomplete batch analyze command
- **Obsolete Molecules**: Removed `diff_analyzer.rb`, `report_formatter.rb`, `time_range_finder.rb`

### Technical

- Added `ace-llm` as runtime dependency
- Simplified codebase: 307 insertions, 561 deletions (net reduction)
- Consistent with ace-review and ace-git-commit prompt patterns

## [0.3.3] - 2025-10-16

### Added

- **Subject Diff Filtering**: Filter git diffs by relevant document paths via `ace-docs.subject.diff.filters` frontmatter
  - Configure which files/directories each document cares about
  - Uses git native path filtering for efficiency (git diff -- path1 path2)
  - Dramatically reduces diff noise for documentation review
  - Example: README.md only shows changes in ace-docs/ and CHANGELOG.md

- **Semantic Validation**: LLM-powered documentation accuracy validation
  - New `validate --semantic` flag for content validation
  - Checks if content matches stated purpose, identifies contradictions
  - Uses ace-llm-query subprocess with gflash model (temperature 0.3)
  - Returns specific issues and inconsistencies found
  - Example: `ace-docs validate docs/architecture.md --semantic`

- **ace-docs Namespace Structure**: Unified configuration organization
  - New `ace-docs:` namespace for all ace-docs configuration (subject, context, rules)
  - Aligns with ace-review's subject/context architecture pattern
  - Fields: `ace-docs.subject.diff.filters`, `ace-docs.context.keywords`, `ace-docs.context.preset`, `ace-docs.rules`
  - Backward compatible: old `update.focus.paths` format still supported via fallback

### Changed

- **Document Model**: Added ace-docs namespace accessors
  - `subject_diff_filters()` - Extract filters with legacy format fallback
  - `context_keywords()` - Extract LLM relevance hints
  - `ace_docs_config()` - Access full ace-docs namespace

- **ChangeDetector**: Integrated subject diff filtering
  - `get_diff_for_document()` now uses `subject_diff_filters` for path filtering
  - `get_diff_for_documents()` applies filters per-document
  - Removed obsolete `filter_relevant_changes()` method

- **Validator**: Implemented semantic validation
  - `validate_semantic()` now calls ace-llm-query subprocess
  - Builds semantic validation prompt from document metadata
  - Parses LLM response for validation status and issues
  - Graceful error handling for missing ace-llm-query

### Fixed

- Removed stale TODO comment from `update_command.rb` (preset selection already implemented)

### Documentation

- Updated README.md with ace-docs namespace schema and examples
- Created comprehensive usage guide in task 073
- Created validation scenario VS-073-001 for subject diff filtering

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
