# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.9.105] - 2025-11-04

### Added
- **ace-taskflow v0.18.0 - Unified Filter System**: New `--filter key:value` syntax replaces legacy filtering flags across tasks, ideas, and releases commands
  - FilterParser Atom: Parses filter syntax with support for OR values (`key:value1|value2`), negation (`key:!value`), and array matching
  - FilterApplier Molecule: Applies filter specifications with AND logic across filters and OR logic within filters
  - Filter-Clear Flag: `--filter-clear` option to override preset filters while keeping release/scope/sort configuration
  - Universal Field Filtering: Filter by any frontmatter field including custom fields (e.g., `--filter team:backend`, `--filter sprint:12`)
  - 52 new tests (23 for FilterParser, 29 for FilterApplier) with 100% pass rate

### Changed
- **ace-taskflow v0.18.0 - Breaking Changes**: Clean break approach with helpful error messages
  - Removed `--status` and `--priority` flags from tasks/ideas commands - use `--filter status:value` or `--filter priority:value` instead
  - Removed `--active`, `--done`, and `--backlog` flags from releases command - use `--filter status:active|done|backlog` instead
  - Updated all command help text with new filter syntax, operators, and comprehensive examples
  - Enhanced TaskFilter molecule to integrate with FilterApplier for universal filtering

### Technical
- Comprehensive usage guide with 30+ examples in `ux/usage.md`
- Error messages show exact migration syntax when legacy flags are used
- Fixed test suite to use new filter syntax throughout

## [0.9.104] - 2025-11-02

### Added
- **ace-taskflow v0.17.0 - Flexible Task Transitions**: Tasks can now transition from any status directly to "done" without requiring intermediate steps (default behavior)
- **Custom Status Support**: Support for custom statuses like "ready-for-review" that aren't in the predefined status list
- **Idempotent Operations**: Running `task done` or status updates multiple times succeeds gracefully with informative messages instead of errors
- **Configuration Support**: New `strict_transitions` config option to enable rigid status validation (opt-in for legacy behavior)

### Fixed
- **Critical Bug - Frontmatter Corruption**: Replaced dangerous regex-based frontmatter editing with safe `DocumentEditor` from ace-support-markdown, preventing task files from being corrupted to 3 lines

### Changed
- **ace-taskflow Default Behavior**: Flexible transitions are now the default (can transition from any status to any other status)

## [0.9.103] - 2025-11-02

### Added

- **ace-taskflow v0.16.0**: Implemented `task update` command for programmatic metadata updates
  - Update any frontmatter field via `--field key=value` syntax
  - Dot notation support for nested YAML structures (e.g., `worktree.branch=feature-name`)
  - Batch updates with multiple `--field` flags in single command
  - Smart type inference for integers, floats, booleans, arrays, and strings
  - Atomic file writes with automatic timestamped backups
  - Comprehensive error handling with specific exit codes
  - 34 test cases covering all functionality
  - Primary use case: Enable ace-git-worktree to add worktree metadata to tasks

## [0.9.102] - 2025-11-02

### Changed
- **Infrastructure Gem Naming Alignment**: Renamed foundational gems to establish clear naming conventions
  - Renamed `ace-core` to `ace-support-core` (v0.10.0) - configuration cascade and shared functionality
  - Renamed `ace-test-support` to `ace-support-test-helpers` (v0.9.2) - test utilities and helpers
  - Updated all 12 dependent gems to use new package names with patch version bumps
  - Established naming pattern: `ace-*` for CLI tools, `ace-support-*` for library-only infrastructure
  - No breaking changes - module names and require paths remain unchanged

### Added
- **Migration Guide**: Comprehensive documentation for gem renaming transition
- **Naming Convention Documentation**: Formalized ace-* vs ace-support-* patterns in docs/ace-gems.g.md

### Technical
- Updated dependencies in 12 gems: ace-context, ace-docs, ace-git-commit, ace-git-diff, ace-lint, ace-llm, ace-nav, ace-review, ace-search, ace-support-markdown, ace-taskflow, ace-test-runner
- All affected gems received patch version bumps for dependency updates
- Updated root Gemfile to reference new gem names
- Created new gem directories alongside old ones for safer migration

## [0.9.101] - 2025-11-01

### Fixed
- **ace-taskflow v0.14.2**: File extension and GTD scope terminology
  - Fixed FileNamer to generate .s.md extension consistently
  - Fixed IdeaLoader default glob patterns to only match ideas directory (not tasks)
  - Updated all FileNamer tests to expect .s.md extension

### Changed
- **ace-taskflow v0.14.2**: Enhanced GTD scope documentation
  - Added comprehensive help text explaining GTD-based scopes (next/maybe/anyday/done)
  - Clarified that scope (folder location) is separate from status (metadata)
  - Updated comments throughout to distinguish scope from status

## [0.9.100] - 2025-11-01

### Fixed
- **ace-taskflow v0.14.1**: Universal preset glob patterns and statistics counting
  - Fixed glob patterns in all presets (next, maybe, anyday, all) to properly include both ideas/ and tasks/ directories
  - Fixed IdeaLoader to use context_root instead of idea_dir for correct glob pattern resolution
  - Fixed statistics counting to use specific globs: `ideas/**/*.s.md` for ideas, `tasks/**/task.*.s.md` for tasks
  - Added command-level filtering to separate idea patterns from task patterns
  - Corrected total count calculations in ideas command to use proper globs
  - Resolved issues where presets returned 0 results and statistics showed incorrect counts

### Technical
- **ace-taskflow**: Created comprehensive retrospective documenting critical testing gaps
  - Identified lack of integration tests for preset system
  - Documented that major functionality was broken despite passing unit tests
  - Proposed improvements: integration test suite, preset validation, and debug command
  - Emphasized importance of end-to-end testing for user-facing features

## [0.9.99] - 2025-10-26

### Added
- **ace-core v0.10.0**: Unified path resolution system with instance-based PathExpander API
  - Factory methods for automatic context inference (`for_file`, `for_cli`)
  - Instance-based `resolve()` method supporting all path types
  - Protocol URI support (wfi://, guide://, tmpl://, task://, prompt://) via plugin system
  - 76 comprehensive tests ensuring backward compatibility and new functionality
  - Updated documentation with usage examples and path resolution rules

## [0.9.98] - 2025-10-25

### Added
- **ace-taskflow v0.14.0**: Maybe and Anyday idea scopes for better idea organization
  - New subdirectories: `ideas/maybe/` for uncertain ideas, `ideas/anyday/` for low-priority ideas
  - Preset support: `ace-taskflow ideas maybe` and `ace-taskflow ideas anyday` commands
  - Creation flags: `--maybe` and `--anyday` for `ace-taskflow idea create`
  - Statistics display with emoji indicators: 💡 (pending), 🤔 (maybe), 📅 (anyday), ✅ (done)
  - Example configurations in `.ace.example/taskflow/presets/maybe.yml` and `anyday.yml`

### Changed
- **ace-taskflow v0.14.0**: Code quality improvements from dual code reviews
  - Extract SCOPE_SUBDIRECTORIES constant to centralize scope definitions
  - Add PRESET_TO_SCOPE mapping for cleaner preset-to-scope resolution
  - Improve status determination using dirname inspection instead of string matching
  - Reduce code duplication in IdeaLoader with loop-based scope loading
  - Add validate_subdirectory_exclusivity helper for mutual exclusivity checks

### Technical
- **ace-taskflow v0.14.0**: Enhanced test coverage and POSIX compliance
  - Add comprehensive test coverage for --maybe/--anyday flag mutual exclusivity (6 new tests)
  - Fix missing final newlines in IdeaWriter templates for POSIX compliance
  - Clean up test artifacts and finalize task 088

## [0.9.97] - 2025-10-25

### Fixed
- **ace-taskflow v0.13.2**: Task sorting issue in preset configurations
  - Tasks were displayed in reverse order when using `ace-taskflow tasks next` command
  - Fixed apply_preset_sorting to handle both string and symbol keys from YAML configs
  - Added comprehensive tests for ascending and descending sort orders

## [0.9.97] - 2025-10-25

### Added
- **ace-search v0.11.1**: Enhanced debugging and validation capabilities
  - Centralized DebugLogger module for unified debug output formatting
  - Path validation warnings for non-existent explicit search paths
  - Comprehensive troubleshooting guide in README
  - DEBUG environment variable documentation with example output

### Changed
- **ace-search v0.11.2**: Implement code review suggestions for clarity and documentation
  - Add design rationale comment to SearchPathResolver explaining ENV var validation
  - Add upgrade note in README linking to Troubleshooting section
  - Document DebugLogger threading context and caching behavior
  - Condense CLI warning message for non-existent paths

### Technical
- **ace-search v0.11.1**: Edge case test coverage for SearchPathResolver (symlinks, non-existent paths, relative paths)
  - Improved debug output consistency across executors
  - 21 additional test cases (17 DebugLogger, 4 edge cases)

## [0.9.96] - 2025-10-25

### Added
- **ace-search v0.11.0**: Project-wide search by default with optional search path argument
  - SearchPathResolver atom with 4-step priority resolution (explicit → env → project root → fallback)
  - Optional SEARCH_PATH positional argument in CLI
  - Display search path in output context for transparency
  - Support for PROJECT_ROOT_PATH environment variable

### Fixed
- **ace-search v0.11.0**: Fixed inconsistent search results from different directories
  - Execute ripgrep/fd from search directory using chdir for correct .gitignore processing
  - Fixed search_path propagation through UnifiedSearcher option builders

### Changed
- **ace-search v0.11.0**: BEHAVIOR CHANGE - Default search scope now project-wide instead of current directory
  - Use `ace-search "pattern" ./` to maintain old behavior (current directory only)

## [0.9.95] - 2025-10-24

### Added
- **ace-context v0.16.0**: File path and protocol arguments support for ace:load-context command
  - New workflow file `handbook/workflow-instructions/load-context.wf.md` with flexible input support
  - wfi:// protocol source registrations for workflow discovery
  - Support for preset names, file paths, and protocol URLs in context loading

### Changed
- **ace-context v0.16.0**: Compacted load-context workflow from 127 to 98 lines (23% reduction)
  - Converted error handling to scannable table format
  - Merged redundant sections for improved readability

### Technical
- **ace-context v0.16.0**: Updated README and documentation examples for flexible input
  - Updated slash command to thin interface pattern (delegates to wfi://load-context)

## [0.9.94] - 2025-10-24

### Technical
- Patch release: Documentation standardization for diff/diffs API
  - **ace-git-diff v0.1.1**: Standardized diff/diffs API documentation
  - **ace-context v0.15.1**: Updated README with unified diff format and deprecated legacy array format
  - **ace-docs v0.6.1**: Changed `filters:` to `paths:` for consistency with ace-git-diff
  - **ace-review v0.11.1**: Updated README and workflow instructions with standardized diff format

## [0.9.93] - 2025-10-23

### Changed

- **ace-context v0.15.0**: Full integration with ace-git-diff
  - GitExtractor delegates all diff operations to ace-git-diff
  - `git_diff()`, `staged_diff()`, `working_diff()` use ace-git-diff for consistent filtering
  - Example presets updated to show diff: key usage
  - All 80 tests passing

- **ace-docs v0.6.0**: ChangeDetector integration with ace-git-diff
  - `generate_git_diff()` now delegates to ace-git-diff
  - Updated test mocks to work with DiffResult objects
  - All ChangeDetector tests passing (17 tests, 66 assertions)
  - Example configs updated with diff filtering notes

- **ace-review v0.11.0**: SubjectExtractor supports new diff: format
  - Handles new `diff: { ranges: [...], paths: [...] }` configuration
  - All 8 example presets updated to use diff: key instead of commands:
  - Maintains backward compatibility with old diff: string format
  - Delegates to ace-context which now uses ace-git-diff

### Technical

- All three gems now use ace-git-diff for unified diff operations
- Global `.ace/diff/config.yml` configuration applies across all gems
- Consistent filtering behavior with user-configurable patterns
- Complete task 075 integration work

## [0.9.92] - 2025-10-23

### Added

- **ace-git-diff v0.1.0**: NEW - Unified git diff functionality for ACE ecosystem
  - Extracted and consolidated git diff logic from ace-context and ace-docs
  - User-configurable exclude patterns via `.ace/diff/config.yml` (no hardcoded constants)
  - ATOM architecture: 4 atoms, 3 molecules, 2 organisms, 2 models
  - CLI with smart defaults, `--output` flag for saving to file, and improved help
  - Configuration cascade: Global → Project → Instance (complete override)
  - Support for date/time resolution ("7d", "1 week ago", "2025-01-01")
  - Comprehensive test coverage (65 tests, 100% passing)
  - Integration helpers for ace-docs, ace-review, ace-context, ace-git-commit

### Changed

- **ace-git-commit v0.11.0**: Integrated with ace-git-diff for unified git command execution
  - GitExecutor now delegates to ace-git-diff's CommandExecutor for all git operations
  - Added ace-git-diff (~> 0.1.0) as runtime dependency
  - Maintains full backward compatibility for all public APIs
  - Analysis logic (detect_scope, analyze_diff) remains in ace-git-commit

## [0.9.91] - 2025-10-23

### Added

- **ace-nav v0.10.1**: Enhanced task:// protocol with improved robustness
  - Implemented task:// protocol for command delegation with unified navigation interface
  - Added comprehensive test coverage for task protocol integration

### Changed

- **ace-nav v0.10.1**: Code quality improvements
  - Improved command parsing robustness using Shellwords.split for proper quote handling
  - Fixed encapsulation by exposing config_loader via public accessor in ProtocolScanner

## [0.9.90] - 2025-10-23

### Added

- **ace-nav v0.10.0**: task:// protocol support with command delegation
  - New `CommandDelegator` organism for cmd-type protocol handling
  - Delegates `task://` URIs to `ace-taskflow task` commands
  - Supports all ace-taskflow reference formats (018, task.018, v.0.9.0+task.018, backlog+025)
  - Pass-through support for --path, --content, and --tree options
  - Added `protocol_type` method to `ConfigLoader` for distinguishing cmd vs file protocols
  - Added `cmd_protocol?` method to `NavigationEngine`
  - Added `--path` option to CLI for consistency with ace-taskflow

- **ace-taskflow v0.13.0**: task:// protocol configuration for ace-nav integration
  - Added `.ace.example/nav/protocols/task.yml` protocol configuration
  - Enables unified navigation interface across all ACE resources
  - Configuration supports all task reference formats and options

### Changed

- **ace-nav**: CLI refactored to return exit codes instead of calling exit() directly
  - Improves testability and composability of CLI methods
  - Entry point now handles exit with returned codes
  - Integration tests updated to check return values

- **ace-nav**: ConfigLoader optimization for performance
  - Reuses ConfigLoader instance from ProtocolScanner
  - Eliminates unnecessary object instantiation on every protocol check

## [0.9.89] - 2025-10-23

### Changed

- **ace-taskflow v0.12.1**: Standardized idea file organization in draft workflows
  - Updated draft-task and draft-tasks workflows to use `ace-taskflow idea done` command
  - Replaced manual git operations with standardized command interface
  - Fixed idea file paths from `docs/ideas/` to `ideas/done/` throughout documentation
  - Simplified workflow complexity (removed 21 lines of manual operations)

## [0.9.88] - 2025-10-23

### Documentation

- **ace-support-markdown v0.1.2**: Improved README examples with educational comments and automated validation
  - Added "why" explanations to all 6 real-world examples clarifying patterns and best practices
  - Refactored Example 5 to use cleaner begin/rescue/ensure pattern with success flag
  - Added automated README example validation (`test/integration/readme_examples_test.rb`)
  - Created comprehensive CONTRIBUTING.md (221 lines) with API sync guidelines
  - Added "Maintaining Documentation" section documenting sync strategy
  - Fixed API parameter documentation (`validate: true` → `validate_before: true`)
  - 8 new test cases ensure documentation stays in sync with code evolution

## [0.9.87] - 2025-10-23

### Documentation

- **ace-support-markdown v0.1.1**: Enhanced README with real-world examples
  - Added 6 comprehensive examples (390+ lines) based on production usage
  - Covers task management, documentation updates, error handling, batch operations
  - All examples extracted from actual ace-taskflow and ace-docs implementations

## [0.9.86] - 2025-10-23

### Changed

- **ace-docs v0.6.0**: Migrated frontmatter handling to ace-support-markdown
  - Replaced custom FrontmatterParser with unified MarkdownDocument.parse API
  - FrontmatterManager now delegates to DocumentEditor for atomic writes with automatic backup
  - Eliminated 605 lines of duplicate code (implementation + tests)
  - Zero breaking changes - maintains full backward compatibility
  - Completes task.082 migration

## [0.9.85] - 2025-10-23

### Changed

- **ace-taskflow v0.12.0**: Migrated to ace-support-markdown for safe file operations
  - DoctorFixer, TaskManager, and IdeaWriter now use SafeFileWriter and DocumentEditor
  - Eliminates file corruption risk through atomic writes and automatic backups
  - All 725 tests passing with no regressions
  - Completes task.081 migration

## [0.9.84] - 2025-10-23

### Changed

- **Documentation terminology standardization**: Consistent tool naming across all docs
  - Standardized to `ace-review` (not `code-review`)
  - Standardized to `ace-test` (not `ace-test-runner`)
  - Standardized to `ace-git-commit` (not `git-commit`)
  - Standardized to `ace-llm-query` (not `llm-query`)

### Technical

- **Removed duplicate workflow**: Deleted `ace-taskflow/handbook/workflow-instructions/review-code.wf.md`
  - Duplicate of `ace-review/handbook/workflow-instructions/review.wf.md`
  - Updated `ace-taskflow/handbook/README.md` to reference ace-review gem
- **Simplified ADR maintenance workflow**: Removed redundant deprecation notice instructions
  - Now references embedded template instead of duplicating content

## [0.9.83] - 2025-10-23

### Fixed

- **ace-docs configuration and performance fixes**: Critical improvements to analyze-consistency
  - Fixed configuration reading to properly respect `llm.model` from config.yml
  - Changed default model from gflash to glite (4-10s vs 2m28s performance improvement)
  - Fixed output handling to only display report path, not content
  - Now respects user configuration instead of ignoring it

### Changed

- **ace-docs version bumped to 0.5.3**: Configuration and performance fixes

## [0.9.82] - 2025-10-23

### Fixed

- **ace-docs analyze-consistency simplified**: Major refactoring for cleaner implementation
  - Now uses ace-llm's native `output:` option to save reports directly
  - Removed redundant report processing and duplicate file generation
  - Fixed cache directory to use git root path (prevents nested directories)
  - Eliminated unnecessary ConsistencyReport parsing - displays LLM response directly
  - Cleaner session directory with only essential files

### Changed

- **ace-docs version bumped to 0.5.2**: Simplified analyze-consistency implementation

## [0.9.81] - 2025-10-21

### Added

- **ace-docs cross-document consistency analysis**: Completed implementation (task.074)
  - LLM-powered analysis to detect terminology conflicts, duplicate content, version inconsistencies
  - Native ace-llm integration using Ruby library interface (not subprocess)
  - Session directory with full inspection capability (prompts, response, report)
  - ace-context integration for better document separation with XML embedding
  - Multiple output formats (markdown, json, text) with configurable thresholds

### Fixed

- **ace-docs analyze-consistency critical bugs**:
  - Fixed LLM response handling (changed from non-existent `result[:success]` to `result[:text]`)
  - Implemented ace-llm's native `output:` option to prevent loss of compute
  - Removed unnecessary document copying (now uses real file paths directly)
  - Added better error messages showing actual API errors
  - Added progress indicators throughout analysis phases

### Changed

- **ace-docs version bumped to 0.5.1**: Bug fixes for analyze-consistency command

## [0.9.80] - 2025-10-20

### Added

- **ace-docs multi-subject configuration**: Comprehensive test coverage and documentation
  - Added 16 tests for multi-subject functionality (Document model, ChangeDetector, DocumentAnalysisPrompt)
  - Created example documents demonstrating multi-subject and single-subject configurations
  - Implemented complete multi-subject configuration feature for categorizing changes

### Changed

- **Task management improvements**
  - Completed task.078 for ace-docs multi-subject configuration
  - Focused task.074 on high-value cross-document consistency analysis

### Technical

- ace-docs version bumped to 0.4.7 with comprehensive changelog
- Enhanced documentation for ace-docs analyze command and multi-subject support
- Updated README documentation with new analyze command features

## [0.9.79] - 2025-10-18

### Fixed

- **ace-docs v0.4.6**: LLM timeout issue in analyze command
  - Added configurable `llm_timeout` setting with default of 300 seconds (5 minutes)
  - Prevents `Net::ReadTimeout` errors during complex document analyses
  - Timeout can be customized via `.ace/docs/config.yml`
  - Resolves issue where analyses taking >60 seconds would fail

## [0.9.78] - 2025-10-18

### Changed

- **ace-docs v0.4.5**: Optimized update-docs workflow for specific file updates
  - Workflow now skips status check when specific files are provided, going directly to analysis
  - Clear decision logic: specific files → direct analysis, bulk operations → status-first
  - Restructured Quick Start section with two distinct paths (Direct Path vs Status-First)
  - Conditional workflow steps - Step 1 (Status Check) marked as "Bulk Operations Only"
  - Enhanced usage examples with dedicated "Update specific document" example
  - Improved efficiency for common use case: `/ace:update-docs ace-docs/README.md`

## [0.9.77] - 2025-10-18

### Added

- **ace-context v0.14.0**: File configuration loading support
  - New `-f/--file` CLI option to load configuration from YAML or markdown files
  - Support for multiple file loading with `-f file1.yml -f file2.md`
  - Mix presets and files: `ace-context -p base -f custom.yml`
  - Files can reference and compose with existing presets via `presets:` key
  - Positional argument now auto-detects input type (preset, file, protocol, inline YAML)
  - New API methods: `load_file_as_preset` and `load_multiple_inputs`
  - Comprehensive test coverage for file loading functionality

### Changed

- **ace-context**: Improved CLI help message and documentation
  - Updated banner from `[PRESET]` to `[INPUT]` to reflect all supported types
  - Added clear description of supported input types in help message
  - Enhanced documentation with input auto-detection section
  - Added examples showing file paths as positional arguments

## [0.9.76] - 2025-10-17

### Added

- **ace-context v0.13.0**: Preset composition support
  - Presets can reference other presets via `presets:` array in YAML configuration
  - CLI accepts multiple presets via `-p` flags or `--presets` comma-separated list
  - New `--inspect-config` flag to view merged configuration without execution
  - Intelligent merging with array deduplication and scalar "last wins" override
  - Circular dependency detection for preset references
  - Example composed presets: base, development, team

### Fixed

- **ace-context v0.13.0**: Preset composition parameter handling
  - Extract all params to root level in preset composition
  - Store preset output mode in metadata for multi-preset loading
  - Cache filename generation for multi-preset mode

## [0.9.75] - 2025-10-16

### Changed

- **ace-docs v0.4.2**: Refactored analyze command to general-purpose change analyzer
  - Removed document embedding and ace-context integration from analysis workflow
  - Simplified prompts to focus on diff summarization without doc-update assumptions
  - Updated system prompt for general change analysis instead of doc recommendations
  - Cleaned up internal architecture (removed create_context_markdown, load_context_md)
  - Net reduction: 126 lines of code for better performance and clarity

## [0.9.74] - 2025-10-14

### Added

- **ace-docs v0.3.0**: Batch analysis command with LLM-powered diff compaction
  - New `ace-docs analyze` command for intelligent documentation analysis
  - LLM compaction via ace-llm-query subprocess integration
  - Automatic time range detection from document staleness
  - Markdown reports organized by impact level (HIGH/MEDIUM/LOW)
  - Cache management with timestamped analysis reports
  - Command architecture refactoring with extracted command classes (DiffCommand, UpdateCommand, ValidateCommand, AnalyzeCommand)
  - ace-lint integration for validation delegation
  - Configuration system integrated with ace-core config cascade

### Fixed

- Task 071 file corruption - restored full task content (1134 lines) from git history after edit tool corruption reduced it to 5 lines

### Technical

- Created retrospective documenting broken task file edits pattern and proposing YAML-aware frontmatter update solutions
- Restored and updated task 071 with proper completion status and achievement summary

## [0.9.73] - 2025-10-14

### Added

- Task reference parsing improvements with ID-based search in ace-taskflow
- Support for v.0.9.0+task.070 reference format in ace-taskflow

### Fixed

- Task lookup for done tasks - simple references (072, task.072) now work correctly
- ace-taskflow now finds tasks in done directory by searching on ID field instead of path extraction

### Changed

- Upgraded ace-taskflow to v0.11.5

## [0.9.72] - 2025-10-14

### Added

- **ADR Lifecycle Management in ace-docs**: Comprehensive workflow infrastructure for Architecture Decision Records
  - Created `ace-docs/handbook/workflow-instructions/create-adr.wf.md` (325 lines)
  - Created `ace-docs/handbook/workflow-instructions/maintain-adrs.wf.md` (599 lines)
  - Embedded templates for ADR creation, deprecation notices, evolution sections, and archive README
  - Cross-references between workflows for complete lifecycle management
  - Real examples and decision criteria from October 2025 archival session

- **Claude Commands for ADR Management**: Organized thin command wrappers
  - Created `.claude/commands/ace/create-adr.md`
  - Created `.claude/commands/ace/maintain-adrs.md`
  - Organized ADR commands under `ace/` namespace for clarity

### Changed

- **ace-docs v0.2.0**: Bumped minor version for ADR workflow features
  - Updated `update-docs.wf.md` with ADR section referencing new workflows
  - Updated `.claude/commands/create-adr.md` to reference new ace-docs location

### Technical

- Removed old standalone `.claude/commands/create-adr.md` (consolidated into ace/ directory)
- ace-docs CHANGELOG updated with 0.2.0 release notes

## [0.9.71] - 2025-10-14

### Added

- **ADR Archive System**: Created `docs/decisions/archive/` directory structure for preserving historical ADRs
  - Archive README documenting deprecation rationale and migration context
  - Clear separation between active and obsolete architectural decisions

- **Six New ADRs**: Documented current gem patterns discovered during mono-repo analysis
  - ADR-016: Handbook Directory Architecture (gem/handbook/ pattern)
  - ADR-017: Flat Test Structure (test/{atoms,molecules,organisms,models}/)
  - ADR-018: Thor CLI Commands Pattern (lib/ace/gem/commands/)
  - ADR-019: Configuration Architecture (ace-core config cascade)
  - ADR-020: Semantic Versioning and CHANGELOG (Keep a Changelog format)
  - ADR-021: Standardized Rakefile (Rake::TestTask with CI compatibility)

### Changed

- **ADR-003 & ADR-004**: Added evolution sections documenting transition from centralized `dev-handbook/templates/` to distributed `gem/handbook/` pattern
- **ADR-013**: Updated scope to clarify naming convention principles still apply while Zeitwerk-specific inflections are legacy-only
- **docs/decisions.md**: Updated summary to reflect current active ADRs and archived decisions

### Technical

- **Archived Legacy ADRs**: Moved 4 obsolete ADRs to archive with deprecation notices
  - ADR-006: CI-Aware VCR Configuration (VCR not used in current gems)
  - ADR-007: Zeitwerk Autoloading (current gems use explicit requires)
  - ADR-008: Observability with dry-monitor (not used in current gems)
  - ADR-009: Centralized CLI Error Reporting (superseded by Thor patterns)
- **ADR-011**: Updated ATOM architecture examples to reflect current gem structure
- **ADR-015**: Documented completion of mono-repo migration with 15+ production gems

## [0.9.70] - 2025-10-14

### Added

#### Meta-Project Workflows

* **ACE Update Changelog Workflow**: Created workflow for main project CHANGELOG updates
  * File: `.ace/handbook/workflow-instructions/ace-update-changelog.wf.md`
  * Automatic versioning from current release with patch increment
  * Claude command: `/ace-update-changelog [description]`

* **ACE Bump Version Workflow**: Created comprehensive workflow instruction for semantic version bumping
  * File: `.ace/handbook/workflow-instructions/ace-bump-version.wf.md`
  * Automates version bumping for individual ACE gem packages
  * Analyzes commits using conventional commit format
  * Supports automatic bump detection (MAJOR/MINOR/PATCH based on commits)
  * Supports explicit bump level override (patch|minor|major parameter)
  * Updates `version.rb` and `CHANGELOG.md` atomically
  * Integrates with ace-git-commit for clean commits
  * Comprehensive troubleshooting with one-liner solutions
  * Claude command: `/ace-bump-version [package-name] [bump-level]`

#### ACE Ecosystem - Complete Foundation (October 2025)

This release represents the complete mono-repo migration from legacy dev-tools to modular ace-* gems, establishing the foundation for AI-assisted development.

**Core Infrastructure**

* **ace-core** (v0.9.0-v0.9.3): Shared utilities and configuration for ACE ecosystem
  * ConfigFinder with cascade resolution (project → user → defaults)
  * OutputFormatter supporting markdown, XML, and markdown-XML formats
  * PathResolver for cross-platform path handling
  * Environment variable cascade loading
  * Foundation library used by all ACE packages

* **ace-context** (v0.9.0-v0.11.4): Project context loading with protocol support
  * Protocol handlers: `wfi://` (workflows), `guide://`, `tmpl://` (templates), `adr://` (ADRs)
  * Preset system with YAML configuration
  * Document source embedding for LLM context
  * Smart caching for performance optimization
  * Git diff integration for change analysis
  * XML embedding format standardization

* **ace-nav** (v0.9.0-v0.9.3): Protocol-based navigation and discovery system
  * Unified access to workflows, guides, templates, ADRs
  * Subdirectory pattern matching
  * Auto-list mode for protocol discovery
  * Standard configuration patterns

**Workflow and Task Management**

* **ace-taskflow** (v0.9.0-v0.11.3): Comprehensive task and release management
  * Task and idea management with timestamped organization
  * Descriptive task paths with semantic directory names
  * Retrospective and release management
  * Configuration cascade system
  * Release command with directory structure support
  * Preset system for flexible task listing
  * Enhanced stats and summary displays
  * Dependency-aware sorting
  * Move-to-done and reschedule functionality
  * Batch operations support
  * Idea, feature, roadmap, and testing workflow migrations
  * Retrospective and review package creation
  * Doctor command for configuration validation
  * Rich clipboard support for ideas (macOS) with ace-support-mac-clipboard
  * Flexible metadata flags for task creation (--title, --status, --estimate, --dependencies)
  * Pending release direct support
  * Test isolation improvements preventing directory pollution
  * 700+ comprehensive tests covering all ATOM layers

**Development Tools**

* **ace-git-commit** (v0.9.0-v0.9.2): LLM-powered conventional commits
  * Automatic commit message generation via Gemini 2.0 Flash Lite
  * Monorepo-friendly (stages all changes by default)
  * Direct message support with `-m` flag
  * Intention-based generation with `-i` flag
  * Informative output for commit operations
  * Proper API key loading with environment cascade

* **ace-review** (v0.9.0-v0.9.9): Code review with LLM assistance
  * Dynamic storage paths for organized review sessions
  * ace-context integration for comprehensive context loading
  * Simplified single-command CLI
  * ace-core ConfigFinder integration
  * Multiple incremental improvements for stability

* **ace-search** (v0.9.0): Unified project-aware search tool
  * Complete migration from legacy dev-tools/exe/search to standalone gem
  * DWIM (Do What I Mean) query analysis with intelligent mode detection
  * Preset-based search configurations
  * Git scope filtering (--staged, --unstaged, --current-branch)
  * Time-based filtering (--since, --until, --recent)
  * fzf integration for interactive result selection
  * Full ATOM architecture: atoms, molecules, organisms, models
  * Default exclusions for archived tasks with override options
  * Sequential group execution support

* **ace-llm** (v0.9.0-v0.9.4): Multi-provider LLM client abstraction
  * Support for Anthropic, OpenAI, Gemini, and local models
  * Streaming response support
  * Model aliases (glite, gflash, sonnet, etc.)
  * Provider plugin architecture
  * Configuration-based provider selection
  * Environment cascade loading support
  * Proper binstubs for ace-llm-query
  * --model and --prompt flags for CLI usage

* **ace-llm-providers-cli** (v0.9.0): CLI-specific LLM providers
  * Local model support via CLI interfaces
  * Provider plugin architecture
  * Integration with ace-llm core

**Code Quality and Documentation**

* **ace-lint** (v0.1.0-v0.3.0): Multi-tool linting orchestration
  * Kramdown markdown linting with style checks
  * Autofix support for common issues
  * ace-core configuration integration
  * Support for multiple tool configurations
  * Configuration cascade: `.ace/lint/config.yml`, `.ace/lint/kramdown.yml`

* **ace-docs** (v0.9.0): Documentation management system
  * Frontmatter-based document discovery
  * Change analysis and validation against rules
  * Update workflow orchestration
  * Batch processing capabilities for multiple documents
  * Iterative agent/human collaboration support
  * Migration documentation for repository restructuring

**Testing Infrastructure**

* **ace-test-runner** (v0.9.0-v0.9.10+): Test execution and reporting
  * Minitest integration with intelligent test discovery
  * Configurable reporters (progress, documentation, minimal)
  * Smoke test pattern support for root-level files
  * Failure limits and fast-fail modes
  * Output control and debugging options
  * Rich developer experience with enhanced reporting
  * Comprehensive gem test coverage
  * Critical edge case testing
  * Performance optimization and profiling support

* **ace-test-support** (v0.9.0): Shared test utilities and helpers
  * Common test helpers and assertion extensions
  * Project scaffolding utilities for tests
  * Fixture management
  * Test isolation patterns

**Support Libraries**

* **ace-support-mac-clipboard** (v0.9.0): macOS clipboard integration
  * NSPasteboard FFI bridge to AppKit
  * Rich content support (images: PNG, JPEG, TIFF)
  * HTML and RTF formatted content preservation
  * File copy detection from Finder with original filenames
  * Platform detection with graceful fallback to text-only on non-macOS
  * Used by ace-taskflow for rich idea creation

### Changed

#### Architecture Standardization (September-October 2025)

**ATOM Pattern Adoption Across All Packages**

* Migrated all packages to standardized ATOM architecture:
  * **Atoms**: Single-responsibility units (executors, parsers, validators)
  * **Molecules**: Coordinated atom groups (managers, filters, integrators)
  * **Organisms**: High-level business logic (searchers, formatters, aggregators)
  * **Models**: Data structures (options, results, presets)
* Standardized flat test structure: `test/atoms/`, `test/molecules/`, `test/models/`, `test/organisms/`
* Consistent naming conventions and organization patterns
* Applied to: ace-core, ace-context, ace-nav, ace-taskflow, ace-git-commit, ace-review, ace-search, ace-llm, ace-lint, ace-docs, ace-test-runner, ace-test-support

**Configuration System Unification**

* Unified configuration via ace-core ConfigFinder across all packages
* Cascade resolution: project config → user config → package defaults
* YAML-based configuration files with package-specific namespaces
* Standardized config structure: `.ace/[package]/config.yml`
* Cross-package config consistency
* Configuration namespace restructuring for clarity

**Testing Standards**

* Comprehensive test coverage requirements across all packages
* Test isolation patterns preventing directory pollution
* Exit code handling standardization for CLI tools
* Version test improvements (regex validation vs exact matching)

**Mono-Repo Workspace**

* Root Gemfile workspace setup for coordinated development
* Shared dependencies across all ace-* gems
* Simplified development workflow with unified tooling

#### Legacy System Migration

**From Monolithic dev-tools to Modular ACE Ecosystem**

* Complete migration of dev-tools functionality to standalone ace-* gems
* Search functionality: `dev-tools/exe/search` → `ace-search` gem
* Taskflow functionality: `dev-taskflow` → `ace-taskflow` gem
* Git commit functionality: `dev-tools/exe/git-commit` → `ace-git-commit` gem
* Review functionality: `dev-tools/exe/review` → `ace-review` gem
* Context loading: `dev-tools/exe/context` → `ace-context` gem
* Navigation: `dev-tools/exe/nav` → `ace-nav` gem
* LLM integration: scattered code → `ace-llm` + `ace-llm-providers-cli` gems
* Testing: scattered scripts → `ace-test-runner` + `ace-test-support` gems
* Linting: scattered scripts → `ace-lint` gem
* Documentation: manual processes → `ace-docs` gem

### Fixed

#### Ecosystem Stabilization (October 2025)

**Cross-Package Integration**

* ace-review + ace-context integration for comprehensive context loading
* ace-lint + ace-core configuration cascade integration
* ace-taskflow test execution fixes preventing mid-execution halts
* ace-context XML embedding format consistency across all loading methods
* ace-review + ace-llm API compatibility updates
* ace-git-commit API key loading with proper environment cascade

**Test Infrastructure Fixes**

* Test isolation preventing directory pollution in main project (ace-taskflow)
* Minitest result parsing and summary display accuracy (ace-test-runner)
* Exit code handling across all CLI tools (proper Integer returns vs SystemExit)
* Clipboard tests compatibility across platforms with proper stubbing
* Version test improvements preventing failures on every version bump

**Configuration and Path Handling**

* Path resolution fixes for cross-platform compatibility
* Config discovery improvements with proper cascade handling
* Glob pattern support in configuration files
* Regex anchor fixes in YAML config detection
* Directory reference consistency across all tools

**ace-taskflow Specific**

* Fixed `ace-taskflow task create --help` creating a task named "--help"
* Current release detection improvements
* Retrospective directory naming corrections
* Pending release direct support fixes

## [0.8.1] - 2025-09-19

### Added

#### Testing Framework Migration

* **Minitest Framework**: Complete migration from RSpec to Minitest
  * Modern testing best practices with behavior-focused approach
  * Comprehensive testing guide documenting patterns and strategies
  * Fast CLI integration tests without VCR overhead
  * Balanced mocking strategy testing real behavior
  * Minitest + Aruba + VCR combination for comprehensive coverage

#### Test Infrastructure

* **Test Suite Organization**
  * Established test directory structure (test/unit, test/integration, test/cassettes)
  * Configured Minitest with proper test_helper.rb
  * Setup Aruba for CLI testing with in-process launcher
  * Configured VCR for HTTP boundary testing
  * Created test helper utilities for common patterns

* **Comprehensive Test Migration**
  * Migrated atoms unit tests with focus on critical behaviors
  * Migrated models unit tests with data validation patterns
  * Migrated molecules unit tests emphasizing composition
  * Migrated organisms unit tests for business logic
  * Migrated ecosystems unit tests for workflow coordination
  * Fast CLI integration tests for basic command validation
  * Complex integration tests for major command scenarios

#### Architecture Improvements

* **ATOM Layer Refinement**
  * Refactored constants, middlewares, and integrations to proper ATOM layers
  * Comprehensive atom structure refactoring for ace_tools
  * Consolidate duplicate PathResolver implementations
  * Convert stateless classes to modules for Ruby idiom
  * Standardize return patterns and clarify architecture documentation

#### Developer Experience

* **Enhanced Test Reporting**
  * Agent-friendly test reporter with clear output
  * Enhanced report generation with file:line paths
  * Profiling support for performance optimization
  * Editor integration removal with simple file:line format
  * Optimized test performance with fast execution

#### Security and Quality

* **Security Hardening**
  * Fixed shell injection vulnerabilities in security validator
  * Replace broad exception handling with specific exception types
  * Improved error handling and validation

* **CLI Provider Support**
  * Enabled Claude Code and Codex CLI providers for llm-query
  * Configuration-based provider architecture
  * Enhanced LLM integration capabilities

### Changed

* **Testing Philosophy**: Shifted from 1:1 RSpec conversion to behavior-focused testing
  * Testing important behaviors rather than implementation details
  * Creating maintainable test suite with confidence over brittleness
  * Establishing patterns that make tests easy to write and understand
  * Balancing test isolation with realistic behavior testing
  * Optimizing for both developer experience and CI performance

* **Architecture Documentation**: Updated architecture guide to reflect ATOM patterns and testing framework changes

### Fixed

* **Test Reliability**: Systematic resolution of failing unit tests
* **Path Resolution**: Fixed multiple path handling and resolution issues
* **Performance**: Optimized slow atom tests with profiling fixes

## [0.7.1] - 2025-09-16

### Added

#### ACE Migration

* **Complete Project Renaming**: Comprehensive migration from old naming conventions to ACE-based structure
  * Renamed all submodule paths from `dev-*` to `.ace/*` structure
  * Renamed Ruby gem from `CodingAgentTools` to `AceTools`
  * Updated module namespace from `CodingAgentTools` to `AceTools`
  * Systematic codemod-based migration ensuring completeness

#### Path Structure Changes

* **New Directory Organization**:
  * `.ace/tools/` - Development tools and utilities
  * `.ace/handbook/` - Workflow instructions and guides
  * `.ace/taskflow/` - Task and release management
  * `.ace/local/` - Local project customizations

#### Module and Gem Renaming

* **Systematic Renaming**:
  * `CodingAgentTools` → `AceTools` (Ruby module)
  * `coding_agent_tools` → `ace_tools` (Ruby files)
  * `coding-agent-tools` → `ace-tools` (gem name)
  * Updated gem executable: `coding-agent-tools` → `ace-tools`

### Changed

* **Codebase Migration**: 5,796 path occurrences updated across 967 files
* **Module References**: 2,991 module/gem occurrences updated across 645 files
* **Total Scope**: Over 1,000+ files systematically updated with codemods

#### Migration Tools

* Created path update codemods for all file types
* Created Ruby module renaming codemods
* Created file/directory renaming scripts
* Created verification scripts for completeness

### Fixed

* **Migration Verification**: Comprehensive search-based verification ensuring no references missed
* **Test Suite**: All tests updated and passing after migration
* **Documentation**: Complete documentation update reflecting new structure

## [0.6.0] - 2025-08-05

### Added

#### Unified Claude Code Integration

* **Claude Command Structure**: Created organized directory structure for commands under `.claude/commands/`
  * Implemented hybrid system supporting both custom hand-crafted commands and auto-generated ones
  * Created clear separation between static command management and dynamic generation
  * Established versioning control for all Claude commands within dev-handbook

* **Handbook CLI Integration**: Added comprehensive Claude subcommands to handbook CLI
  * `handbook claude generate-commands` - Smart command generation from workflow instructions
  * `handbook claude validate` - Coverage checking and validation framework
  * `handbook claude integrate` - Simplified installation via copy/link operation
  * `handbook claude list` - Status overview with table format display
  * Deprecated legacy standalone Claude integration script

* **Command Generation System**: Implemented intelligent command generation from workflows
  * Auto-detection of workflow instructions requiring Claude commands
  * Template-based command generation with YAML frontmatter
  * Validation system ensuring complete coverage of workflow instructions
  * Support for custom command metadata and tool specifications

* **ATOM Architecture Implementation**: Complete refactoring to ATOM architectural patterns
  * Refactored `claude_commands_installer` to ATOM architecture
  * Refactored `handbook-claude-tools` to ATOM architecture
  * Improved code organization and maintainability
  * Enhanced test coverage and code quality

### Changed

* **Command Organization**: Unified all Claude-related commands under handbook CLI
  * Moved from auto-generated commands only to hybrid approach
  * Simplified command discovery through single interface
  * Improved documentation and user experience
  * Enhanced meta workflow for command validation

* **Installation Process**: Streamlined Claude integration installation
  * Simplified to copy/link operation from complex script execution
  * Added proper YAML frontmatter preservation
  * Improved command count display in integration output
  * Enhanced error handling and validation

### Fixed

* **Command Integration Issues**: Resolved various integration and display problems
  * Fixed invalid Claude tool specifications in command metadata
  * Fixed command count display in handbook claude integrate
  * Fixed YAML frontmatter preservation during integration
  * Addressed code style violations with RuboCop compliance

* **Test Coverage**: Systematic improvements to test suite
  * Fixed handbook Claude CLI command tests
  * Improved test coverage to 70%+
  * Systematic test suite maintenance and cleanup
  * Enhanced test reliability and consistency

### Documentation

* **Claude Integration Documentation**: Comprehensive documentation updates
  * Updated install-prompts.md with new unified process
  * Created comprehensive command reference documentation
  * Enhanced template organization and standardization
  * Updated meta workflow documentation

* **Architecture Documentation**: Enhanced technical documentation
  * Added ATOM architecture implementation guides
  * Created migration guides and reports
  * Updated development setup and usage instructions
  * Improved troubleshooting and error handling guides

## [0.4.0] - 2025-08-04

### Added

#### Comprehensive Specification Cycle Architecture

* **Idea Management System**: Created ideas-manager tool for systematic idea capture
  * Implemented `capture-it` command for quick idea capture with automatic file management
  * Added automatic commit flag support for immediate git commits
  * Enabled raw input capture at end of idea files for better context preservation
  * Created structured idea templates with metadata tracking

* **Enhanced Task Workflows**: Refactored workflow system for clear phase separation
  * Created capture-idea workflow for initial idea recording
  * Enhanced draft-task workflow for behavioral specification focus
  * Split review-task workflow into plan-task and review-task components
  * Created cascade-review workflow for managing dependent task updates
  * Updated task template structure with distinct what/how sections

* **Task Management Enhancements**: Major improvements to task-manager tool
  * Added `list` command as primary alias for improved discoverability
  * Implemented `create` subcommand for direct task creation
  * Enhanced status summary capabilities with improved formatting
  * Added draft status support for better workflow integration
  * Improved CLI consistency across all subcommands

* **Multi-Repository Management**: New tools for cross-repository operations
  * Created git-tag tool for synchronized multi-repository tagging
  * Enhanced release management with multi-repo support
  * Improved git operations across submodules

* **Claude Code Integration**: Deep integration with Claude AI assistant
  * Integrated custom Claude commands into Claude Code workflow
  * Created .claude/commands/ directory structure for custom commands
  * Developed feature-research subagent for systematic feature analysis
  * Added installation prompts and configuration management

* **Advanced Features**: Additional capability enhancements
  * Dynamic flag handling in create-path tool
  * Automated idea file management for task creation
  * Configuration-based repository filtering for git commands
  * Enhanced template organization for draft/plan workflow separation

### Changed

* **Workflow Reorganization**: Fundamental restructuring of specification process
  * Renamed draft-task workflow to better reflect behavioral specification focus
  * Reorganized task templates for clearer draft/plan separation
  * Updated all workflow references to use new terminology
  * Enhanced documentation to explain phase boundaries

* **Tool Improvements**: CLI and usability enhancements
  * Updated task-manager CLI for consistency and clarity
  * Improved ideas-manager capture command naming (capture → capture-it)
  * Enhanced create-path with dynamic flag support
  * Refined git command filtering for better control

### Fixed

* **Workflow Issues**: Resolution of process-related problems
  * Fixed task status tracking inconsistencies
  * Resolved workflow dependency conflicts
  * Corrected template path references
  * Fixed cascade review update propagation

* **Tool Bugs**: Various tool-related fixes
  * Fixed ideas-manager file naming issues
  * Resolved task-manager ID generation conflicts
  * Corrected git-tag submodule handling
  * Fixed create-path flag parsing errors

### Documentation

* **Workflow Documentation**: Comprehensive updates to workflow instructions
  * Updated all 21 workflow instructions for new phase structure
  * Created detailed cascade-review workflow documentation
  * Enhanced draft-task and plan-task workflow guides
  * Added clear phase transition documentation

* **Tool Documentation**: Enhanced tool reference materials
  * Updated task-manager documentation with new commands
  * Created ideas-manager usage guide
  * Added git-tag tool documentation
  * Enhanced Claude integration documentation

## [0.3.233] - 2025-01-30

### Added

#### Workflow Independence & AI Agent Integration System

* **Complete Workflow Self-Containment**: Refactored all 21 workflow instructions to be fully independent and self-contained for AI agent integration (Claude Code, Windsurf, Zed)
  * Implemented ADR-001: Workflow Self-Containment Principle establishing architectural guidelines
  * Created universal document embedding system supporting `<documents>` and `<templates>` XML format
  * Developed template synchronization system with automated git integration and dry-run support
  * Added XML prompt structure for code reviews with YAML frontmatter integration
  * Established standardized execution templates and project context loading patterns

#### Comprehensive Test Coverage Initiative (80%+ Coverage Achievement)

* **Massive Testing Overhaul**: Implemented comprehensive unit tests for 145+ components achieving 80%+ test coverage
  * **Atoms**: Complete test coverage for core foundation components (FileContentReader, YamlFrontmatterParser, TemplateEmbeddingValidator, SubmoduleDetector, StatusColorFormatter, DotGraphWriter)
  * **Molecules**: Comprehensive testing for business logic helpers (PathResolver, UnifiedTaskFormatter, CircularDependencyDetector, SynthesisOrchestrator, MarkdownLintingPipeline, FilePatternExtractor, TaskSortEngine, DiffReviewAnalyzer, SessionPathInferrer, StatisticsCalculator, GitDiffExtractor, ReportCollector, TaskFilterParser, TaskSortParser, ReflectionReportCollector, CommitMessageGenerator, ReportFormatter, ExecutableWrapper, TaskDependencyChecker, FileAnalyzer)
  * **Organisms**: Full test coverage for complex orchestration components (GitOrchestrator, MultiPhaseQualityManager, AgentCoordinationFoundation, SessionManager, TaskManager, ReviewManager, PromptBuilder, GoogleClient)
  * **CLI Commands**: Complete test coverage for all command interfaces (NavTree, NavLS, ReleaseCurrent, TaskReschedule, ReleaseNext, CodeReviewNew, TaskAll, ReleaseAll, LLMModels, LLMUsageReport, CoverageAnalyze, ReflectionSynthesize, GitCommit, GitRm)
  * **Models & Ecosystems**: Full coverage for data structures and workflows (LintingConfig, UsageMetadataWithCost, FormatHandlers, CoverageAnalysisWorkflow)

#### Advanced Development Tools & Features

* **Coverage Analysis Tooling**: Comprehensive coverage analysis system with adaptive thresholds
  * Standalone `coverage-analyze` executable with ATOM architecture
  * Compact range format for efficient coverage reporting
  * Adaptive threshold calculator for intelligent coverage assessment
  * Integration with SimpleCov for Ruby projects
* **Enhanced Task Management**: Multi-release support and unified formatting
  * `create-path` command for intelligent file/directory creation with metadata
  * Multi-release support for task-manager commands
  * Unified compact formatter with modification time tracking
  * Task reschedule command with advanced sorting options
* **Parallel Testing Infrastructure**: High-performance testing with SimpleCov merging
  * Parallel RSpec execution with proper coverage aggregation
  * Optimized test performance with reduced output pollution
  * Integration test suite for comprehensive path resolution testing

#### Security Framework Enhancements

* **Comprehensive Security Hardening**: Multiple vulnerability fixes and security improvements
  * Fixed YAML security vulnerability using `YAML.safe_load_file`
  * Resolved command injection vulnerabilities in git command executor
  * Implemented standardized shell command escaping with `Shellwords.escape`
  * Enhanced input sanitization across all CLI tools
  * Added comprehensive error handling tests for security-critical components

#### Release Management & Path Resolution System

* **Advanced Release Management**: Enhanced release workflow coordination
  * PathResolver integration for release-relative paths
  * Release Manager CLI with --path option for flexible release handling
  * Reflection synthesis improvements with intelligent output path logic
  * Integration test suite for path resolution consistency

### Changed

#### Architecture & Code Quality Improvements

* **ATOM Architecture Hardening**: Complete refactoring of architectural patterns
  * Consolidated task_management namespace into taskflow_management
  * Refactored CommitMessageGenerator to use direct Ruby calls
  * Improved StandardRbValidator portability by removing global state
  * Implemented separate language-specific runners for code linting
  * Standardized executable patterns using ExecutableWrapper

#### Multi-Repository Workflow Enhancements

* **Enhanced Git Operations**: Improved multi-repository coordination
  * Unified command context creation for git operations
  * Fixed main repository command context issues
  * Improved error message readability and debugging
  * Enhanced multi-repo commit workflow with proper error handling

#### Development Process Improvements

* **Testing & Quality Assurance**: Comprehensive testing infrastructure improvements
  * Consolidated test structure and eliminated duplications
  * Optimized coverage report format for size reduction
  * Enhanced VCR configuration with environment-specific header handling
  * Improved integration testing with ProcessHelpers standardization

#### Tool Migration & Modernization

* **Command Migration**: Systematic tool migration and enhancement
  * Replaced nav-path with create-path for creation operations
  * Enhanced delegation format for create-path and nav-path commands
  * Migrated deprecated tool dependencies to modern alternatives
  * Updated documentation references from bin/markdown-sync to handbook sync-templates

### Fixed

#### Critical Bug Fixes & Stability Improvements

* **Test Reliability**: Systematic resolution of failing unit tests
  * Fixed CI test failures by unifying duplicate execute_gem_executable helper methods
  * Resolved failing tests in coverage, nav-ls, and directory navigation
  * Fixed path resolution and formatter test failures
  * Addressed git command execution order issues

#### Security Vulnerability Resolutions

* **Command Injection Prevention**: Multiple security vulnerability fixes
  * Fixed command injection vulnerability in create-path command
  * Resolved encapsulation violation in create-path PathResolver access
  * Implemented comprehensive error handling for security-critical paths
  * Enhanced input validation and sanitization

#### Code Quality & Linting Issues

* **StandardRB Compliance**: Complete code quality standardization
  * Fixed all unsafe linting issues with StandardRB auto-fix
  * Resolved GFM and error handling test failures
  * Implemented proper StandardRB configuration usage
  * Enhanced language-specific file filtering for linting

#### Integration & Performance Issues

* **System Integration**: Various integration and performance improvements
  * Fixed reflection synthesize LoadError and restored functionality
  * Resolved RSpec output pollution in test suite
  * Fixed YAML date parsing in task metadata
  * Improved task ID generation and validation logic

### Security

#### Vulnerability Fixes & Hardening

* **Critical Security Improvements**: Comprehensive security vulnerability resolution
  * **CVE Fixes**: Resolved YAML.load_file security vulnerability (Task 86)
  * **Command Injection Prevention**: Fixed multiple command injection vulnerabilities (Tasks 89, 113)
  * **Input Sanitization**: Standardized shell command escaping across all tools (Task 91)
  * **Secure Coding Practices**: Enhanced input validation and sanitization framework
  * **Dependency Security**: Updated insecure dependencies and implemented secure loading patterns

#### Security Framework Implementation

* **Defense in Depth**: Multi-layer security implementation
  * Comprehensive input validation at all CLI entry points
  * Secure file path handling with traversal attack prevention
  * Enhanced error handling to prevent information disclosure
  * Standardized security logging and monitoring integration

### Performance

#### Test Performance Optimization

* **Parallel Testing**: High-performance testing infrastructure
  * Implemented parallel RSpec testing with SimpleCov merging for 40% faster test execution
  * Optimized test database handling and fixture management
  * Reduced test output pollution and improved CI performance
  * Enhanced test reliability with proper timeout and retry mechanisms

#### Coverage Analysis Optimization

* **Efficient Coverage Reporting**: Optimized coverage analysis performance
  * Implemented compact range format reducing report size by 60%
  * Added adaptive threshold system for intelligent coverage assessment
  * Optimized SimpleCov integration for large codebases
  * Enhanced coverage calculation efficiency with unified algorithms

### Documentation

#### Comprehensive Documentation Overhaul

* **Workflow Documentation**: Complete workflow instruction system overhaul
  * Updated all 21 workflow instructions for AI agent compatibility
  * Created comprehensive AI agent integration guides
  * Developed standardized template embedding format documentation
  * Added error recovery procedures and troubleshooting guides

#### Technical Documentation Enhancements

* **Development Guides**: Enhanced developer experience documentation
  * Updated testing conventions to match ATOM architecture
  * Created comprehensive tool reference documentation
  * Added version control and git workflow guides
  * Developed release codenames and project management guides

## Impact Summary

This release represents **6 months of intensive development** with:
* **225 discrete tasks** completed across all project areas
* **187 git commits** implementing comprehensive improvements
* **80%+ test coverage** achieved across entire codebase
* **Complete workflow system overhaul** for AI agent integration
* **Comprehensive security hardening** with multiple vulnerability fixes
* **Advanced tooling ecosystem** with 25+ CLI tools fully tested and documented

This is the largest and most comprehensive release in the project's history, establishing a solid foundation for future AI-assisted development workflows while maintaining the highest standards of code quality, security, and reliability.

## \[v0.3.0\] - 2025-07-24

### Added

#### Ruby Gem - Coding Agent Tools (CAT)

* **Complete 25+ CLI Tool Suite**: Comprehensive development automation toolkit
  * **Git Operations**: `git-add`, `git-commit`, `git-fetch`, `git-log`, `git-pull`, `git-push`, `git-status`, `git-checkout`, `git-switch`,
    `git-mv`, `git-rm`, `git-restore` with multi-repository support
  * **Task Management**: `task-manager next`, `task-manager recent`, `task-manager list`, `task-manager generate-id` with dependency resolution and filtering
  * **Release Management**: `release-manager current`, `release-manager next`, `release-manager all` with validation and reporting
  * **Navigation Tools**: `nav-ls`, `nav-path`, `nav-tree` with intelligent path autocorrection
  * **LLM Integration**: `llm-query` unified interface supporting Google Gemini, OpenAI, Anthropic, Mistral, Together AI, LM Studio
  * **Code Review**: `code-review`, `code-review-prepare`, `code-review-synthesize` with ATOM architecture
  * **Documentation**: `handbook sync-templates` with XML template synchronization
  * **Reflection Tools**: `reflection-synthesize` for session analysis and archival

#### ATOM Architecture Implementation

* **Atoms**: Core utilities (`XDGDirectoryResolver`, `SecurityLogger`, `EnvReader`, `FileSystemScanner`, `YamlFrontmatterParser`, `TaskIdParser`,
  `DirectoryNavigator`, `ShellCommandExecutor`)
* **Molecules**: Behavior-oriented helpers (`CacheManager`, `MetadataNormalizer`, `APICredentials`, `HTTPRequestBuilder`, `TaskSortEngine`, `TaskFilterEngine`,
  `PathResolver`)
* **Organisms**: Business logic orchestration (`GoogleClient`, `LMStudioClient`, `OpenaiClient`, `AnthropicClient`, `MistralClient`, `TogetherAiClient`,
  `TaskManager`, `ReleaseManager`, `PromptProcessor`)
* **Ecosystems**: Complete workflow coordination with system-level integration
* **Models**: Pure data carriers (`LlmModelInfo`, `ParseResult`, `ReviewSession`, `ReviewTarget`, `ReviewPrompt`)

#### Multi-Provider LLM Integration

* **Google Gemini**: Full API integration with model discovery and cost tracking
* **OpenAI**: Complete GPT model support with token usage parsing
* **Anthropic Claude**: Claude model integration with comprehensive metadata
* **Mistral**: Mistral AI model support with unified interface
* **Together AI**: Together AI integration with model listing
* **LM Studio**: Local LLM support for offline development
* **Unified Interface**: Single `llm-query` command with provider:model syntax
* **Cost Tracking**: Comprehensive usage tracking with LiteLLM pricing database
* **Dynamic Aliases**: Provider shortcuts (e.g., gflash, csonet) for rapid access

#### Security Framework

* **Multi-Layer Security**: Path validation, sanitization, and secure logging
* **SecurePathValidator**: Directory traversal attack prevention
* **FileOperationConfirmer**: Interactive overwrite confirmation system
* **Secrets Scanning**: Gitleaks integration for local development security
* **XDG Compliance**: Standard-compliant caching with automatic migration

#### Development Infrastructure

* **ExecutableWrapper**: Standardized CLI executable framework
* **VCR Integration**: HTTP interaction recording for testing
* **Aruba Testing**: CLI integration testing framework
* **ProjectRootDetector**: Intelligent project root detection
* **BinstubInstaller**: Automated shell integration system
* **CI-Aware Configuration**: Robust testing in CI/CD environments

#### Task Management System

* **Dependency Resolution**: Topological sorting for task dependencies
* **Filtering & Sorting**: Advanced task filtering by status, priority, implementation order
* **Multi-Format Output**: JSON and text output formats for integration
* **Path Resolution**: Intelligent task file location detection
* **ID Generation**: Automated unique task ID generation with validation

#### Template Synchronization

* **XML Template Support**: `<documents>` and `<templates>` format support
* **Embedded Document Sync**: Automatic synchronization of embedded templates
* **Git Integration**: Automated commit functionality for template changes
* **Dry-Run Support**: Preview mode for template synchronization

### Changed

* **Migration from Shell Scripts**: Converted 20+ shell scripts to robust Ruby CLI tools
* **Unified Command Interface**: Consolidated multiple LLM provider commands into single `llm-query` interface
* **Enhanced Git Workflow**: Multi-repository operations with intelligent commit message generation
* **Improved Path Resolution**: Context-aware path handling for nested repository structures
* **Standardized CLI Patterns**: Consistent command structure across all tools
* **Enhanced Documentation**: Comprehensive tool reference with persona-based organization

### Fixed

* **Thread Synchronization**: Resolved concurrent git operation issues
* **Path Detection**: Fixed git command path detection for nested directories
* **URL Construction**: Corrected Gemini API URL construction for model info
* **Template Synchronization**: Resolved template sync errors and improved logging
* **Memory Management**: Fixed memory leaks in background processing
* **Test Reliability**: Optimized test performance and eliminated CI fragility

### Security

* **Path Traversal Protection**: Comprehensive validation against directory traversal attacks
* **Secure Credential Handling**: Environment-based API key management with validation
* **Input Sanitization**: Multi-layer input validation and sanitization
* **Secrets Detection**: Integrated Gitleaks for local secrets scanning

## \[v0.4.0\] - 2025-06-25

### Added

* Enhanced initialize-project-structure workflow with v.0.0.0 template release tracking
  * Created template v.0.0.0 release structure in dev-handbook/guides/initialize-project-templates/
  * Added template copying and customization logic for new projects
  * Integrated roadmap creation into project initialization process
  * Included clear user guidance for post-initialization steps

### Changed

* Renamed manage-roadmap workflow to update-roadmap for improved clarity
  * Updated all references across the codebase
  * Enhanced workflow with cleanup functionality for completed releases
* Improved roadmap management with post-release cleanup integration
  * Added cleanup step to remove completed releases from roadmap
  * Updated step numbering and error handling procedures

## \[v.0.2.0\] - 2025-01-15

### Added

* **Initial LLM Integration**: Foundation for multi-provider LLM communication
* **ATOM Architecture**: Established Atoms, Molecules, Organisms, Ecosystems pattern
* **Ruby Gem Structure**: Core gem foundation with dry-cli framework
* **Basic Git Tools**: Initial git command enhancements
* **Testing Infrastructure**: RSpec, VCR, and Aruba testing setup
* **CI/CD Pipeline**: GitHub Actions workflow with multi-Ruby testing

### Changed

* **Project Structure**: Migrated from shell scripts to Ruby gem architecture
* **Development Workflow**: Established standardized development processes

## \[v.0.1.0\] - 2024-12-01

### Added

* **Project Foundation**: Initial Ruby gem structure with ATOM architecture
* **Build System**: Comprehensive build, test, and lint infrastructure
* **Development Guides**: Git workflow and contribution guidelines
* **Documentation Framework**: Architecture and blueprint documentation

## \[v.0.0.0\] - 2024-11-01

### Added

* **Project Initialization**: Basic project structure and documentation
* **Git Submodules**: Multi-repository coordination setup
* **Initial Documentation**: PRD, roadmap, and architectural decisions

## \[v.0.3.0-workflows\] - 2025-06-04

### v.0.3.0+tasks.24 - 2025-06-02 - Implement Roadmap Release Lifecycle Management

* **Enhanced manage-roadmap workflow with release lifecycle integration** to automatically maintain roadmap accuracy:
  * | Added step 3 (Update Release Status) to check release folder locations (backlog | current | done) and update roadmap accordingly |
  
  * Added step 7 (Validate Synchronization) to ensure roadmap matches project folder structure and validate cross-references
  * Enhanced with comprehensive error handling for format validation, file system inconsistencies, and commit failures
  * Added cross-workflow dependency documentation specifying integration with draft-release and publish-release workflows
* **Updated draft-release workflow** to include roadmap management:
  * Added step 7 to update roadmap with new release information after release scaffolding completion
  * Integrated separate roadmap commit with standardized message format
  * Added roadmap update validation to success criteria
* **Updated publish-release workflow** to include roadmap cleanup:
  * Added step 15 to remove completed releases from roadmap during documentation archival phase
  * Implemented roadmap cleanup with cross-reference dependency updates
  * Enhanced critical success criteria to include roadmap accuracy validation
* **Enhanced roadmap definition guide** with comprehensive release lifecycle specifications:
  * Added release status tracking format specifying how releases should be represented based on folder location
  * Created systematic release removal process with validation checklist
  * Documented integration triggers specifying when roadmap updates occur during release workflows
  * Added comprehensive error handling and recovery procedures for failed roadmap updates
  * Established cross-workflow dependencies and validation requirements for release lifecycle management

### v.0.3.0+tasks.22 - 2025-06-02 - Create Roadmap Definition Guide

* **Created comprehensive roadmap definition guide** at `dev-handbook/guides/roadmap-definition.g.md`:
  * Established deterministic format requirements for all roadmap sections (Front Matter, Project Vision, Strategic Objectives, Key Themes & Epics, Planned
    Major Releases, Cross-Release Dependencies, Update History)
  * Defined precise table format specifications with column definitions and validation criteria
  * Created content guidelines and best practices for writing style, strategic alignment, and maintenance
  * Added validation criteria for structure, content, and quality compliance
  * Provided concrete examples demonstrating correct and incorrect roadmap formatting
  * Documented integration guidelines for workflow instructions to reference format requirements
* **Separated format specification from workflow process** following separation of concerns principle:
  * Removed embedded format rules from manage-roadmap workflow instruction
  * Established pattern for workflows to reference dedicated format guide rather than embedding specifications
  * Created foundation for consistent roadmap format validation across all related workflows

### v.0.3.0+tasks.16 - 2025-06-02 - Implement Agreed Naming Conventions for Guides and Workflow Instructions

* **Implemented file extension conventions** to establish clear distinction between guides and workflow instructions:
  * Applied `.wf.md` suffix to all 21 workflow instruction files (breakdown-notes-into-tasks, commit, create-adr, create-api-docs, create-reflection-note,
    create-release-overview, create-retrospective-document, create-review-checklist, create-test-cases, create-user-docs, draft-release, fix-tests,
    initialize-project-structure, load-env, save-session-context, manage-roadmap, publish-release, review-task, review-tasks-board-status, update-blueprint,
    work-on-task)
  * Applied `.g.md` suffix to all guide files with noun-based naming (changelog, coding-standards, documentation, error-handling, performance,
    project-management, quality-assurance, security, strategic-planning, temporary-file-management, testing, release-codenames, release-publish,
    testing-tdd-cycle, debug-troubleshooting, version-control-system, task-definition)
  * Moved and renamed workflow-specific guides: embedding-tests-in-workflows → .meta/workflow-embedding-tests.g.md, tools-guide → .meta/tools.g.md
* **Updated meta-documentation** to reflect new naming conventions:
  * Enhanced `dev-handbook/guides/.meta/writing-guides-guide.md` with `.g.md` convention documentation and noun-based naming examples
  * Enhanced `dev-handbook/guides/.meta/writing-workflow-instructions-guide.md` with `.wf.md` convention documentation and verb-first naming pattern
* **Fixed internal documentation links** throughout the codebase:
  * Updated all cross-references in workflow instructions and guides to use new `.wf.md` and `.g.md` filenames
  * Corrected relative paths in test-driven-development-cycle documentation
  * Verified link integrity with zero critical broken links remaining
* **Created Zed editor rule mapping documentation** for manual updates to development environment integration

### v.0.3.0+tasks.15 - 2025-06-01 - Rename "Prepare Release" to "Draft Release" and Ensure Independence from "Publish Release"

* **Renamed prepare-release to draft-release throughout codebase** for clearer separation from publish-release process:
  * Renamed `dev-handbook/workflow-instructions/prepare-release.md` to `dev-handbook/workflow-instructions/draft-release.md`
  * Renamed `dev-handbook/guides/prepare-release/` directory to `dev-handbook/guides/draft-release/`
  * Updated 147+ references across workflow instructions, guides, session files, and current tasks
* **Established complete independence between draft-release and publish-release processes**:
  * Removed inappropriate references to draft-release from publish-release documentation
  * Removed draft-release prerequisites from publish-release workflow instructions
  * Added clarifying note in draft-release.md explaining scope distinction from publish-release
* **Reorganized documentation structure** for better logical organization:
  * Split guides README.md into separate "Draft Release Management" and "Publish Release Management" sections
  * Restructured workflow instructions README.md with improved section hierarchy (Core Workflow, Project Initialization, Draft Releases, Testing, Project
    Management, Publish Release)
  * Added all missing guides to guides README.md including language-specific sub-guides and project initialization templates
* **Clarified process separation**: Draft Release focuses on creating and planning new releases in backlog, while Publish Release handles finalizing and
  deploying completed releases

### v.0.3.0+tasks.14 - 2025-06-01 - Define and Document "Publish Release" Process and Guide

* **Created comprehensive publish release process** replacing ship-release terminology:
  * `dev-handbook/guides/publish-release.md` - Detailed guide explaining release publishing philosophy, semantic versioning scheme (v<major>.<minor>.<patch>
    extracted from release folder names), and archival process from `dev-taskflow/current/` to `dev-taskflow/done/`</patch></minor></major>
  * `dev-handbook/workflow-instructions/publish-release.md` - Step-by-step workflow instruction for executing the complete publish release process including
    version finalization, package publication, documentation archival, and stakeholder communication
  * `dev-handbook/guides/changelog-guide.md` - Comprehensive changelog writing guide following Keep a Changelog format with project-specific adaptations and
    integration guidelines
* **Replaced ship-release terminology throughout codebase**:
  * Deleted `dev-handbook/workflow-instructions/ship-release.md` and `dev-handbook/guides/ship-release.md` files
  * Moved `dev-handbook/guides/ship-release/` directory to `dev-handbook/guides/publish-release/` with updated language-specific examples (ruby.md, rust.md,
    typescript.md)
  * Updated all references from "ship-release" to "publish-release" across documentation files, workflow instructions, and guides
* **Enhanced versioning documentation**:
  * Updated `dev-handbook/guides/version-control.md` with semantic versioning scheme documentation and examples showing version extraction from release folder
    names
  * Updated `dev-handbook/guides/project-management.md` with archival process description and consistent publish release terminology
* **Integrated technology-agnostic approach** supporting diverse project types through `bin/build` execution and flexible package publication processes
* **Established clear process separation** between preparation (handled by existing prepare-release workflow) and final deployment/archival (handled by new
  publish-release process)

### v.0.3.0+tasks.12 - 2025-06-01 - Remove Checkboxes from Guides and Workflow Instructions; Clarify Use of Acceptance Criteria

* **Converted inappropriate interactive checklists to bullet points** in guides:
  * `dev-handbook/guides/version-control.md` - Changed PR template example from checkboxes to bullet points
  * `dev-handbook/guides/security.md` - Converted security review checklist from interactive checkboxes to informational bullet points with bold headers
* **Enhanced meta documentation** with comprehensive checkbox usage guidelines:
  * `dev-handbook/guides/.meta/writing-guides-guide.md` - Added detailed section on appropriate vs inappropriate checkbox usage, with examples of when
    checkboxes are legitimate (templates, examples) vs inappropriate (interactive checklists)
  * `dev-handbook/guides/.meta/writing-workflow-instructions-guide.md` - Added "List Formatting in Workflows" section clarifying that Success Criteria should
    use simple bullet points, Process Steps should use numbered lists, and checkboxes are only appropriate in templates/examples
* **Standardized all workflow instruction Success Criteria** to use simple bullet points instead of checkboxes across 11 workflow files: `create-user-docs.md`,
  `create-test-cases.md`, `create-retrospective-document.md`, `create-release-overview.md`, `create-api-docs.md`, `create-adr.md`, `commit.md`,
  `create-review-checklist.md`, `review-tasks-board-status.md`, `create-reflection-note.md`, `prepare-release.md`
* **Converted Process Steps in ship-release.md** from checkboxes to numbered steps (1-24) for better sequential execution guidance
* **Established clear distinction** between reference documentation (guides) and actionable content (tasks), preventing AI agents from treating guides as
  interactive checklists while preserving legitimate checkbox usage in templates and examples

### v.0.3.0+tasks.11 - 2025-06-01 - Clarify Policy on Updating "Done" Tasks if Referenced Files Change

* Added comprehensive policy section to `dev-handbook/guides/project-management.md` under Agent Operational Boundaries
* Defined clear distinction between prohibited modifications (content changes, historical revisions, status changes) and allowed reference updates (broken link
  fixes, security annotations, accessibility improvements)
* Established process requirements for human updates including justification, additive approach, history preservation, clear attribution, and minimal scope
* Provided concrete examples of acceptable vs unacceptable modifications to done tasks
* Maintains balance between preserving historical accuracy and ensuring practical usability of project documentation

### v.0.3.0 - 2025-06-01 - Enhance Review Task Workflow for New Task Structure

* Updated the `review-task.md` workflow instruction to incorporate the new Planning Steps and Execution Steps structure for tasks.
* Added steps to the review process to evaluate task structure, recommend using Planning Steps for complex tasks, and suggest adding embedded tests.
* Ensured the workflow guides reviewers to maintain consistency with the updated task template and standards.

### v.0.3.0+tasks.10 - 2025-06-01 - Refine Task Template to Include Distinct "Plan" and "Execution" Sections

* Updated the task template (`dev-handbook/guides/prepare-release/v.x.x.x/tasks/_template.md`) to include separate "Planning Steps" (`* [ ]`) and "Execution
  Steps" (`- [ ]`) subsections within the "Implementation Plan".
* Updated the `write-actionable-task.md` guide to document the new structure, explaining the rationale, visual distinction, when to use planning steps, and how
  it relates to workflow phases (review vs. work).
* Added examples to the guide demonstrating tasks with only execution steps and tasks with both planning and execution steps, including embedded tests in both
  sections.

### v.0.3.x+task.8 - 2025-06-01 - Refine Initialize Project Test Task and Create Review Roadmap Task

* Updated `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/008-test-initialize-project.md` to align its scope with the "Initialize Project
  Structure" workflow, specifically excluding the creation of `roadmap.md` and initial release scaffolding.
* Created new task `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/v.0.3.0+task.21.md` to review the `manage-roadmap.md` workflow instruction,
  following the guide for writing actionable tasks.

### v.0.3.x - 2025-05-30 - Standardize Binstub Location and Rename gat to tal

* Renamed the `bin/gat` wrapper script to `bin/tal`.
* Updated documentation and task references for the `bin/gat` -> `bin/tal` rename.
* Added binstub scripts for `tnid`, `rc`, and `tal` to `dev-tools/exe-old/_binstubs/`.

### v.0.3.x - 2025-05-30 - Incorporate Codename Picking Guide into Prepare Release Workflow

### v.0.3.x+task.20 - 2025-05-30 - Improve Initialize Project Structure Workflow

* **Refactored `initialize-project-structure.md` Workflow:**
  * Added explicit idempotency statement to clarify rerun behavior.
  * Streamlined the workflow by removing the redundant "Initialize Version Control" (formerly Step 3) and the "Tailor Development Guides" (formerly Step 4)
    steps.
  * Renumbered the steps to reflect the removal of the two steps.
  * Enhanced the "Core Documentation Generation" step to reference new templates and include improved example questions for interactive prompts.
  * Updated the "Setup Project `bin/` Scripts" step (now Step 3) to refer to the `dev-taskflow/architecture.md` for binstub explanations.
* **Created New Project Initialization Templates:**
  * Added `dev-handbook/guides/initialize-project-templates/PRD.md` with a basic PRD structure.
  * Added `dev-handbook/guides/initialize-project-templates/README.md` with a basic README structure.
  * Added `dev-handbook/guides/initialize-project-templates/blueprint.md` based on the current project's blueprint structure.
  * Added `dev-handbook/guides/initialize-project-templates/architecture.md` based on the current project's architecture structure, including binstub
    explanations.
  * Added `dev-handbook/guides/initialize-project-templates/what-do-we-build.md` based on the current project's what-do-we-build structure.
* **Created New Guide for Codenames:**
  * Added `dev-handbook/guides/picking-codenames.md` with guidance on choosing themes, length, and uniqueness for project codenames.

### v.0.3.x - 2025-05-30 - Standardize Task ID Generation and Consolidate Task Templates

* **Task ID Generation Standardization:**
  * Updated `dev-handbook/guides/write-actionable-task.md`, `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md`, and
    `dev-handbook/guides/project-management.md` to mandate the use of the `bin/tnid` script for generating task IDs. This ensures unique, correctly formatted,
    and sequentially numbered task IDs.
* **Task Template and Example Consolidation:**
  * Moved the canonical task template to `dev-handbook/guides/prepare-release/v.x.x.x/tasks/_template.md`.
  * Relocated the full worked task example to `dev-handbook/guides/prepare-release/v.x.x.x/tasks/_example.md`.
  * Updated `dev-handbook/guides/write-actionable-task.md` to remove the embedded template and example, now linking to these new centralized locations. This
    streamlines task creation and ensures a single source of truth for the task structure.

### v.0.3.0+task.19 - 2025-05-28 - Fix Markdown Lint Errors

* **Documentation Quality Improvements:**
  * Fixed final markdown lint errors in `dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2/tasks/018-add-tool-for-getting-release-path.md`
  * Resolved MD013 line length violations by appropriately breaking long lines to comply with 120-character limit
  * Completed processing of all 81 markdown files in the project
* **Task Management:**
  * Updated task file checklist to mark final file as completed
  * Marked all scope of work items, deliverables, and acceptance criteria as completed
  * Changed task status from "in-progress" to "done"
* **Quality Assurance:**
  * All markdown files now pass `bin/lint` markdownlint checks
  * Project documentation now maintains consistent formatting standards
  * Improved documentation readability and compliance with style guidelines

### v.0.3.0+task.18 - 2025-05-27 - Add Tool for Getting Current Release Path and Version

* **Created New Development Tools:**
* Added `dev-tools/exe-old/get-current-release-path.sh` - Main tool script that determines the appropriate directory for storing newly created tasks and returns
  version information.
* Added `bin/rc` - Thin wrapper script for easy access to the get-current-release-path utility.
* Added `dev-tools/exe-old/test-get-current-release-path.sh` - Comprehensive test suite with 13 test assertions covering 5 test scenarios.

* **Tool Functionality:**
* Returns path to current release directory (e.g., `dev-taskflow/current/v.X.Y.Z-codename`) and version string (e.g., `v.X.Y.Z`) when a current release exists.
* Returns backlog tasks path (`dev-handbook/backlog/tasks`) and empty version when no current release is detected.
* Handles edge cases like multiple release directories gracefully.
* Includes help option and proper error handling for invalid arguments.

* **Workflow Integration:**
* Updated `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md` to utilize the new `bin/rc` tool in Step 6 for determining task storage location.
* Added instructions for creating necessary directories before saving task files.
* Integrated version information access for potential use in task metadata or naming.

* **Quality Assurance:**
* All automated tests pass, covering current release detection, backlog fallback, multiple directories, help functionality, and error handling.
* Tool correctly identifies and works with the actual project structure (`dev-taskflow/current/v.0.3.0-feedback-after-meta.v.0.2`).

### v.0.3.x-fix - 2025-05-27 - Update Breakdown Notes to Tasks Workflow

* Updated the `breakdown-notes-into-tasks.md` workflow instructions.
* Added clarification on where formal task files should be stored (current release `tasks/` directory or `dev-handbook/backlog/tasks/`).
* Introduced a new Step 6 to formalize the task structure according to the `write-actionable-task.md` guide after user verification.
* Reviewed and updated the workflow's goal, inputs, process steps, output, and success criteria for consistency.

### v.0.3.0+task.7 - 2025-05-27 - Add .meta/ Subdirectories for Self-Referential Workflows and Guides

* Created the `.meta/` subdirectories within `dev-handbook/guides/` and `dev-handbook/workflow-instructions/`.
* Moved the `writing-guides-guide.md`, `writing-workflow-instructions.md` (and renamed it to `writing-workflow-instructions-guide.md`), and `tools-guide.md`
  files into `dev-handbook/guides/.meta/`.
* Updated all internal links within the project that pointed to these moved guide files.
* Added documentation explaining the purpose and usage of the `.meta/` directories in `dev-handbook/README.md`.
* Verified internal links using the lint tool.

### v.0.3.0+task.5 - 2025-05-27 - Ensure Uniqueness and Consistency of Task IDs and Release Versioning (and Tooling Fixes)

* **Task ID and Release Versioning Standardization**:
  * Implemented new task ID convention: `v.X.Y.Z+task.<sequential_number>`.
  * Standardized release directory naming to `v.X.Y.Z-codename`.
* **Tooling Enhancements & Fixes**:
  * Added `bin/tnid` (`dev-tools/exe-old/get-next-task-id`) to generate the next unique task ID.
  * Added `bin/gat` (`dev-tools/exe-old/get-all-tasks`) to list all tasks in a release, sorted by dependencies and highlighting the next actionable one.
  * Added `dev-tools/exe-old/lint-task-metadata` script (integrated into `bin/lint`) to validate task metadata against new conventions.
  * Modified `bin/tn` (`dev-tools/exe-old/get-next-task`) to correctly sort task IDs numerically and prioritize `in-progress` tasks.
  * Updated `dev-handbook/guides/tools-guide.md` with refined principles for path conventions, testing, and binstub simplicity.
  * Corrected path usage, regdev-tools/exes for version parsing, and fixed bugs in the newly created/modified tools (`get-next-task-id`, `get-all-tasks`,
    `lint-task-metadata`) and their binstubs (`bin/tnid`, `bin/gat`).
  * Fixed minor errors in `bin/lint` script.
* **Documentation Updates**:
  * Updated `dev-handbook/guides/project-management.md` with new task ID convention, release folder naming, and tool information.
  * Updated `dev-handbook/guides/write-actionable-task.md` with new task ID format in templates/examples.
  * Updated `dev-handbook/workflow-instructions/prepare-release.md` to reflect new ID generation and versioning. versioning.

### **Minor Fix:**

* Bring back the directory `dev-handbook/workflow-instructions/breakdown-notes-into-tasks`, deleted in 33af0d94cb0598baa4b5d36b8ffd273d3b8ebcc8

### v.0.3.x-4 - 2025-05-27 - Implement Immutability Rules for Specified Paths via Agent Blueprint

* **Agent Operational Boundaries:**
  * Added "Read-Only Paths" and "Ignored Paths" sections to `dev-taskflow/blueprint.md` to define file access rules for the agent.
    * Populated "Ignored Paths" with default common patterns (e.g., `dev-taskflow/done/**/*`, `**/node_modules/**`).
    * Added project-specific "Read-Only Paths" (e.g., `dev-taskflow/releases/**/*`, `docs/decisions/**/*`).
  * Updated `dev-handbook/workflow-instructions/initialize-project-structure.md` to include these new sections and their default content when generating a new
    `blueprint.md`.
  * Added a new "Agent Operational Boundaries" section to `dev-handbook/guides/project-management.md` to explain the purpose of these blueprint configurations
    and refer to `dev-taskflow/blueprint.md` for details.

### v.0.3.x-3 - 2025-05-27 - Establish Guidelines for Temporary File Usage by AI Agent

* **Temporary File Usage Guidelines:**
  * Defined criteria for appropriate use of temporary files by the agent.
  * Specified recommended locations, naming conventions, and cleanup responsibilities for temporary files.
  * Documented these guidelines in `dev-handbook/guides/temporary-file-management.md` and updated relevant links.
* **Development Cycle Documentation Refinement:**
  * Renamed `dev-handbook/guides/task-cycle.md` to `dev-handbook/guides/test-driven-development-cycle.md`.
  * Renamed directory `dev-handbook/guides/task-cycle/` to `dev-handbook/guides/test-driven-development-cycle/`.
  * Updated all internal references to these renamed paths.
  * Deleted redundant `dev-handbook/guides/testing/test-cycle.md`.

### v.0.3.x-2 - 2025-05-27 - Design a Standard for Incorporating Tests into AI Agent Workflows

* **Workflow Testing Standard:**
  * Defined a standard for embedding tests (`> TEST:`, `> VERIFY:`) in workflow instruction files.
  * Created `dev-handbook/guides/embedding-tests-in-workflows.md` detailing the standard.
  * Updated `dev-handbook/guides/writing-workflow-instructions.md` to reference the new testing guide.
  * Added a proposed `bin/test` script to `dev-taskflow/architecture.md`.
  * Integrated the testing standard into `dev-handbook/guides/write-actionable-task.md`, `dev-handbook/workflow-instructions/work-on-task.md`, and
    `dev-handbook/workflow-instructions/breakdown-notes-into-tasks.md`.

### v.0.3.x-13 - 2025-05-26 - Create `bin/` Aliases for Common Development Commands

* **Standardized `bin/` Commands:**
  * Introduced top-level `bin/test`, `bin/lint`, `bin/build`, and `bin/run` alias scripts.
  * These scripts wrap underlying project-specific commands for consistent developer experience.
  * Created placeholder binstub templates in `dev-tools/exe-old/_binstubs/` for new projects.
  * Documented the new `bin/` aliases.

### v.0.3.x-6 - 2025-05-26 - Merge tools and utils Directories

* **Tooling Structure Refinement:**
  * Merged `dev-handbook/utils` directory into `dev-tools/exe-old`.
  * Renamed scripts in `dev-tools/exe-old` to follow a verb-prefix naming convention (e.g., `recent-tasks` to `get-recent-tasks`).
  * Updated all internal and external references to the old script paths and names.
* **Minor Cleanup:**
  * Deleted duplicate directory `dev-handbook/workflow-instructions/breakdown-notes-into-tasks`.

* * *

## 2025-05-26

* Updated submodules for documentation.
* Rewrote `prepare-release` workflow.
* Scaffolded `v.x.y.z-ideas-after-toolkit-meta` release.
* Marked preflight task as "someday".
* Prepared release `v0.2.22`.

## 2025-05-09

* **Added:**
  * FAQ section to `README.md`.
  * `package-lock.json` to track dependencies.
  * `package.json` to define devDependencies.
* **Changed:**
  * Updated submodule commits.

## 2025-05-08

* **Added:**
  * `create-reflection-note` workflow.
* **Changed:**
  * Reviewed and restructured project management workflows.
  * Split Task `v.0.2.3-18` (Review and Restructure Project Management Workflows) into Plan & Execute phases.
  * Improved usage examples in `README.md` including initializing project structure, breaking down ideas into tasks, reviewing tasks, and working on tasks.
  * Drafted initial `README.md` content for the Coding Agent Workflow Toolkit, explaining key components, purpose, and setup.
  * Updated documentation subprojects.

## 2025-05-07

* **Changed:**
  * Updated `dev-taskflow` to `v0.2.3-17` which refactored documentation generation workflows. This includes:
    * Flattening the `dev-handbook/workflow-instructions/docs/` subdirectory.
    * Renaming documentation generation workflows to `create-<context>.md` (e.g., `create-adr.md`, `create-api-docs.md`).
    * Updating H1 titles and internal links.
  * Corrected introductory sentences in documentation to reference `breakdown-notes-into-tasks.md`.
  * Updated references to old workflow names.

* * *

## Prior to 2025-05-07 (Based on Release Summaries)

Changes in this period are summarized by their release version.

### Release v.0.2.3 (Feedback After Zed Extension)

(Corresponds to tasks completed around and before 2025-05-07, many of which are reflected in the 2025-05-07 and 2025-05-08 git logs)

* **Documentation Standardization:**
  * Refactored developer guides and workflow instructions by technology stack (Ruby, Rust, TypeScript). (Task `01-tailor-guides-tech-stack`,
    `07-tailor-workflow-instructions-tech-stack`)
  * Implemented consistent naming conventions for release documents (`02-release-doc-naming-consistency`), workflow instructions
    (`09-define-apply-workflow-naming-convention`), and task IDs (`08-define-task-id-convention`).
* **Workflow Streamlining:**
  * Consolidated task specification workflows (`lets-spec-*`) into `prepare-tasks` (now `breakdown-notes-into-tasks`). (Task `03-consolidate-spec-workflows`,
    `16-review-simplify-prepare-tasks-workflow`)
  * Reviewed, refined, and renamed core workflows:
    * `lets-start` to `work-on-task`. (Task `10-review-rename-lets-start-workflow`)
    * `lets-tests` (merged into `work-on-task`). (Task `11-review-lets-tests-workflow`)
    * `lets-fix-tests` to `fix-tests`. (Task `12-review-lets-fix-tests-workflow`)
    * `lets-release` reviewed (Task `13-review-lets-release-workflow`), leading to new `ship-release` workflow.
    * `init-project` to `initialize-project-structure`. (Task `14-review-rename-init-project-workflow`)
    * `generate-blueprint` reviewed and renamed. (Task `15-review-rename-generate-blueprint-workflow`)
    * Clarified and restructured project management (`review-tasks-board-status`) and reflection (`save-session-context`, `create-retrospective-document`)
      workflows. (Task `18-review-restructure-project-management-workflows`)
  * Reviewed and restructured documentation generation workflows (Task `17-review-documentation-generation-workflows` - details in 2025-05-07 log).
* **Project Planning & Execution Enhancements:**
  * Defined and implemented a project roadmap (`dev-taskflow/roadmap.md`) and strategic planning process (`dev-handbook/guides/strategic-planning-guide.md`,
    `dev-handbook/workflow-instructions/manage-roadmap.md`). (Task `20-define-roadmap-and-strategic-planning`)
  * Mandated and defined a structured "Implementation Plan" section within task files (`dev-handbook/guides/write-actionable-task.md`). (Task
    `21-define-embedded-plan-structure`)
  * Created a new `ship-release` workflow. (Task `22-create-ship-release-workflow`)
* **Documentation Quality & Structure Improvements:**
  * Created guides for troubleshooting (`dev-handbook/guides/troubleshooting-workflow.md`). (Task `04-high-level-dev-debug-workflow`)
  * Created guide for task implementation cycle (`dev-handbook/guides/test-driven-development-cycle.md`). (Task `05-support-writing-workflow-guide`)
  * Split testing guides by technology. (Task `06-split-testing-guides-by-tech`)
  * Reviewed and improved `prepare-release` templates. (Task `19-review-prepare-release-templates`)

### Release v-0.2.2 (Feedback to Process)

* Clarified "Command" terminology in documentation, replacing it with "Workflow Instruction".
* Updated development guides with research insights on AI-assisted development, prompting, and general best practices.
* Created a new guide on "Writing Workflow Instructions".

### Release v.0.2.1 (Spec from Diff)

* Introduced the `lets-spec-from-git-diff` workflow instruction to analyze git diffs and generate structured feedback and task specifications.

### Release v.0.2.0 (Dev Docs Review - Streamline Workflow)

* **Unified Task Management:** Solidified a single task management system using structured Markdown files in `dev-taskflow/{backlog,current,done}`. Removed the
  experimental `project/task-manager`.
* **Simplified Release Documentation:** Provided clearer guidelines for documentation required for different release types (Patch, Feature, Major).
* **Workflow Consistency:** Ensured consistent terminology and aligned Kanban board references. Commands were updated to link to guides rather than duplicating
  content.
* **Integrated Best Practices:** Incorporated research on "planning before coding" and structured task details into guides.
* Updated and created various workflow instructions (`load-env`, `work-on-task`, `lets-spec-from-pr-comments`, `review-kanban-board`, `self-reflect`,
  `lets-release`, `log-session`, `generate-blueprint`, `lets-spec-from-release-backlog`) to align with the unified system.
* Updated core guides (`project-management.md`, `ship-release.md`, `unified-workflow-guide.md`) and introduced a project blueprint.
* Separated context loading (`load-env`) from task execution (`work-on-task`).

### Release v.0.0.1 (Initial Release)

* Established initial project infrastructure.
* Set up the project structure and documentation framework.
* Documented the initial release process.

