# Changelog

All notable changes to ace-docs will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.7] - 2025-10-20

### Added

- **Comprehensive test coverage for multi-subject configuration**
  - Added 4 unit tests for Document model multi-subject parsing
  - Added 5 integration tests for ChangeDetector multi-diff generation
  - Added 7 tests for DocumentAnalysisPrompt multi-subject handling
  - All tests ensure backward compatibility with single-subject format

### Documentation

- **Example documents for multi-subject configuration**
  - Created detailed multi-subject example showing code/config/docs separation
  - Created single-subject example with migration guide
  - Both examples include comprehensive usage instructions and best practices

### Technical

- Enhanced analyze command and multi-subject support documentation in usage.md
- Updated README with new analyze command and features documentation

## [0.4.6] - 2025-10-18

### Fixed

- **LLM timeout issue in analyze command** - Requests no longer timeout after 60 seconds
  - Added configurable `llm_timeout` setting with default of 300 seconds (5 minutes)
  - Timeout can be customized in `.ace/docs/config.yml`
  - Prevents `Net::ReadTimeout` errors for complex document analyses
  - Example config updated with timeout documentation

### Added

- New configuration option `llm_timeout` in seconds (default: 300)

## [0.4.5] - 2025-10-18

### Changed

- **Optimized workflow for specific file updates** in update-docs.wf.md
  - Workflow now skips status check when specific files are provided, going directly to analysis
  - Added clear decision logic: specific files → direct analysis, bulk operations → status-first
  - Restructured Quick Start section with two distinct paths (Direct Path vs Status-First)
  - Updated Workflow Steps with conditional flow - Step 1 (Status Check) marked as "Bulk Operations Only"
  - Enhanced Usage Examples with dedicated "Update specific document (Direct Path)" example
  - Improved efficiency for common use case: `/ace:update-docs ace-docs/README.md`

## [0.4.4] - 2025-10-18

### Fixed

- Critical shell expansion bug in ChangeDetector causing incorrect glob pattern matching
- Date resolution to check ace-docs namespace before legacy update namespace
- Multi-subject handling in build_analysis_scope_section to prevent TypeError
- Diff file paths now use absolute paths for proper ace-context loading

### Changed

- Updated workflow instructions (update-docs.wf.md) to use `analyze` instead of deprecated `diff` command
- Workflow now emphasizes analysis.md as primary output for LLM recommendations
- Added documentation for multi-subject configuration in workflows

### Added

- **Multi-subject configuration support** for categorizing different types of changes
  - Define multiple subjects in document frontmatter (e.g., code, config, docs)
  - Each subject generates its own diff file (code.diff, config.diff, docs.diff)
  - Maintains backward compatibility with single-subject configuration
  - Improved dual-mode analysis prompts for separating code from docs/config changes

- New analysis prompts in `handbook/prompts/`:
  - `ace-change-analyzer.system.md` - Dual analysis system prompt (v3.0)
  - `ace-change-analyzer.user.md` - User instructions for dual analysis

### Changed

- Document model now supports both single and multi-subject configurations
  - Added `multi_subject?` method to check for multi-subject configuration
  - Added `subject_configurations` method returning structured subject data
  - Single subject returns `{ name: "default", filters: [...] }`

- ChangeDetector enhanced for multiple diff generation
  - New `get_diffs_for_subjects` method generates separate diffs per subject
  - Returns hash of `{subject_name => diff_content}` for multi-subject
  - Single subject behavior unchanged for backward compatibility

- DocumentAnalysisPrompt updated to handle multiple diff files
  - Accepts either single diff string or hash of diffs
  - Saves each diff with subject name (e.g., "code.diff", "docs.diff")
  - Adds all diff files to context.md files array

- AnalyzeCommand improved display for multi-subject
  - Shows configured subjects with their filters
  - Displays diff statistics per subject
  - Clear progress messages for multi-subject processing

### Documentation

- Updated README.md with multi-subject configuration examples
- Added multi-subject example to `.ace.example/docs/config.yml`
- Example usage in ace-docs README.md frontmatter

## [0.4.3] - 2025-10-18

### Fixed

- Save prompts (prompt-system.md, prompt-user.md) before calling LLM instead of after
  - Ensures prompts available for debugging even if LLM call fails
  - Can reproduce exact inputs sent to LLM
  - Matches pattern for context.md and repo-diff.diff (already saved early)

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
