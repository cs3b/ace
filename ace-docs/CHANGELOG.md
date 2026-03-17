# Changelog

All notable changes to ace-docs will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.25.6] - 2026-03-17

### Fixed
- Updated CLI routing tests to match current `ace-support-cli` help rendering and avoid false regressions.

## [0.25.5] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.25.4] - 2026-03-13

### Technical
- Updated canonical docs skills to align with shared workflow execution standards.

## [0.25.3] - 2026-03-13

### Changed
- Updated canonical docs skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.25.2] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-docs-squash-changelog` skill so provider projections now inherit the canonical skill body unchanged.

## [0.25.1] - 2026-03-12

### Changed
- Updated documentation guides and README examples to use current gem-scoped handbook paths and bundle-first workflow references.

## [0.25.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-docs-squash-changelog` skill so the generated Codex skill runs in fork context on `gpt-5.3-codex-spark`.

## [0.24.1] - 2026-03-12

### Fixed
- Updated shipped prompt-source override guidance to use `.ace-handbook` and `~/.ace-handbook` instead of the old `.ace/handbook` locations.

## [0.24.0] - 2026-03-10

### Added
- Added canonical handbook-owned documentation skills for ADR, API, user-doc, update, and changelog maintenance workflows.


## [0.23.0] - 2026-03-08

### Added
- Added repeatable document scope options across core doc-selection commands:
  - `--package <ace-package>` for package-root scoping
  - `--glob <pattern>` for explicit glob scoping, including bare-path normalization (for example, `--glob ace-assign` -> `ace-assign/**/*.md`)

### Changed
- Scoped selection is now applied during registry discovery, reducing out-of-scope traversal for status/discover/update/validate/analyze-consistency command flows.
- Updated docs/update workflow guidance and user-facing usage examples to include package/glob scoped operations.

### Technical
- Added command/integration/registry regression coverage for scope normalization and scoped selection behavior.
- Suppressed expected loader noise for markdown files without frontmatter (`No frontmatter found`) to keep scoped command output readable.

## [0.22.4] - 2026-03-04

### Changed
- Default docs cache directory now uses `.ace-local/docs`.


## [0.22.3] - 2026-03-04

### Fixed
- `docs/update.wf.md` workflow instruction corrected to short-name path convention (`.ace-local/docs/` not `.ace-local/ace-docs/`)

## [0.22.2] - 2026-03-04

### Fixed
- Usage docs corrected to short-name convention (`.ace-local/docs/` not `.ace-local/ace-docs/`)

## [0.22.1] - 2026-03-04

### Fixed
- README `cache_dir` example corrected to short-name convention (`.ace-local/docs` not `.ace-local/ace-docs`)

## [0.22.0] - 2026-03-04

### Changed
- Default cache directories migrated from `.cache/ace-docs` to `.ace-local/docs`

## [0.21.1] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.21.0] - 2026-02-22

### Added
- Standard help pattern with `HELP_EXAMPLES` constant and formatted help output
- No-args behavior now shows help (consistent with other ace-* CLIs)

### Changed
- Migrate from DWIM DefaultRouting to standard dry-cli help pattern
- Remove `KNOWN_COMMANDS`, `BUILTIN_COMMANDS`, `DEFAULT_COMMAND` constants
- CLI invocation now uses `Dry::CLI.new().call()` pattern

## [0.20.3] - 2026-02-22

### Technical
- Update `ace-bundle project` → `ace-bundle load project` in markdown-style guide

## [0.20.1] - 2026-02-19

### Technical
- Namespace workflow instructions into docs/ subdirectory with updated wfi:// URIs
- Migrate update-usage and update-roadmap workflows from ace-taskflow

## [0.20.0] - 2026-02-13

### Added
- Squash-changelog workflow instruction for consolidating multiple CHANGELOG.md entries on feature branches before merge

## [0.19.2] - 2026-02-12

### Fixed
- Anchor ignore patterns to project root in `DocumentRegistry` to prevent matching system paths (e.g., `/tmp/` no longer matches project ignore rule `**/tmp/**`)
- `glob_to_regex` now anchors converted patterns to `@project_root`, distinguishing `**/` (anywhere under project) from bare patterns (at project root)

## [0.19.1] - 2026-01-31

### Technical
- Stub ace-nav subprocess calls in document_analysis_prompt tests (3.4s → 0.7s, 80% faster)

## [0.19.0] - 2026-01-22

### Changed
- Move embedded-testing-guide to ace-test package
- Guide now available via ace-test package

## [0.18.1] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.18.0] - 2025-01-14

### Added
- Migrate CLI commands to Hanami pattern (task 213)
  - Move all command logic into `CLI::Commands::*` namespace under `cli/commands/` directory
  - Remove separate `Commands::` wrapper classes - business logic now integrated into CLI commands
  - Update command file naming to match class names (remove `_command` suffix)
  - Delete legacy `commands/` directory
- Full implementation for all 6 commands: analyze, analyze_consistency, discover, status, update, validate

### Changed
- Consolidate CLI structure following Hanami/dry-cli authoritative pattern
  - Use `CLI::Commands::*` namespace throughout
  - Clean up require paths for proper module resolution

### Technical
- Remove obsolete unit tests for deleted `Commands::*` classes
- Remove obsolete integration test for `StatusCommand`


## [0.17.2] - 2026-01-10

### Changed
- Use shared `Ace::Core::CLI::DryCli::DefaultRouting` module for CLI routing
  - Removed duplicate routing code in favor of shared implementation
  - Maintains same behavior with less code duplication

## [0.17.1] - 2026-01-10

### Fixed
- Fix CLI default command routing to properly handle flags
  - Added complete default routing infrastructure with REGISTERED_COMMANDS, BUILTIN_COMMANDS, KNOWN_COMMANDS, DEFAULT_COMMAND constants
  - Added `known_command?` helper method for routing logic
  - Flags now correctly route to default `status` command
  - Built-in flags (`--help`, `--version`) continue working via KNOWN_COMMANDS

## [0.17.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.10)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command classes (analyze, analyze_consistency, discover, status, update, validate)

## [0.16.0] - 2026-01-07

### Changed
- **BREAKING**: Session and analysis filenames changed from 14-character timestamps to 6-character Base36 compact IDs
  - Session directories: `analyze-20251129-143000` → `analyze-i50jj3`
  - Analysis reports: `analysis-20251129-143000.md` → `analysis-i50jj3.md`
- Migrate to Base36 compact IDs for session and file naming (via ace-timestamp)

### Added
- Dependency on ace-timestamp for compact ID generation

## [0.15.0] - 2026-01-05

### Added
- Thor CLI migration with standardized command structure
- ConfigSummary display for effective configuration with sensitive key filtering
- Comprehensive CLI help documentation across all commands

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Migrated from OptionParser to Thor framework
- Added method_missing for default subcommand support

## [0.14.1] - 2026-01-03

### Changed

- Migrated 7 workflow instructions from `ace-nav wfi://` to `ace-bundle wfi://` for consistency
- Updated workflows: create-adr, create-api-docs, create-cookbook, create-user-docs, maintain-adrs, update-blueprint, update-context-docs

## [0.14.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.1.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.13.3] - 2026-01-03

### Fixed

- Mock correct git operations in ChangeDetector tests - stub `DiffOrchestrator.generate` instead of `execute_git_command` to avoid real git I/O (89% test performance improvement: 14s → 1.5s)

### Technical

- Extract `with_empty_git_diff` test helper to reduce duplication (6 instances)
- Add benchmark command and Lessons Learned section to task documentation

## [0.13.2] - 2026-01-01

### Fixed

- Restore historical freshness thresholds for monthly documents (30/45 days instead of 14/30)
- Add frequency-specific threshold configuration in `.ace-defaults/docs/config.yml`
- Migrate DocumentRegistry to use ace-config cascade for configuration loading

## [0.13.1] - 2025-12-30

### Changed

- Add ace-config dependency for configuration cascade management
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.13.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory

## [0.12.0] - 2025-12-29

### Changed
- Migrate ProjectRootFinder dependency from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.11.0] - 2025-12-28

### Added
- **ADR-022 Configuration Pattern**: Migrate to gem defaults from `.ace.example/` with user override support
  - Load defaults from `.ace.example/docs/config.yml` at runtime
  - Deep merge with user config via ace-core cascade
  - Follows "gem defaults < user config" priority

### Changed
- **Dependency Migration**: Migrated from `ace-git-diff` to `ace-git` for unified git operations

## [0.10.1] - 2025-12-27

### Fixed

- **CLI Option Mapping Regression**: Fixed `--exclude-renames`/`--exclude-moves` flags being silently ignored
  - AnalyzeCommand.build_diff_options was emitting legacy `include_*` keys instead of new `exclude_*` keys
  - CLI flags now correctly propagate to ace-git DiffOrchestrator

### Changed

- **Deprecation Warning for Legacy Option Keys**: Added warning when using `include_renames`/`include_moves`
  - Callers should migrate to `exclude_renames`/`exclude_moves` keys
  - Warning: `[DEPRECATED] Use exclude_renames/exclude_moves instead of include_renames/include_moves`

- **Centralized Option Construction**: Extracted `build_diff_options` helper method in ChangeDetector
  - Centralizes ace-git option mapping logic
  - Improves maintainability and reduces duplication

### Technical

- Added 5 command-level tests for CLI option propagation (analyze_command_test.rb)
- Added 3 tests for legacy option key deprecation warnings
- Updated test using legacy `include_renames` key to use new `exclude_renames` key

## [0.10.0] - 2025-12-27

### Changed

- **Dependency Migration**: Migrated from ace-git-diff to ace-git
  - Updated dependency from `ace-git-diff (~> 0.1)` to `ace-git (~> 0.3)`
  - Changed `require "ace/git_diff"` to `require "ace/git"`
  - Updated namespace from `Ace::GitDiff::*` to `Ace::Git::*`
  - Part of ace-git consolidation (ace-git-diff merged into ace-git)

### Fixed

- **Option Mapping for ace-git API**: Fixed incorrect option names passed to DiffOrchestrator
  - Changed `detect_moves` (invalid) to `exclude_moves` (ace-git API)
  - Fixed `exclude_renames` default to `false` (was inverting caller intent when nil)
  - Renames and moves are now correctly included by default

- **Test Isolation**: Fixed DocumentRegistry and StatusCommand test failures caused by ProjectRootFinder discovering actual project files
  - Added `project_root` parameter to DocumentRegistry.new and StatusCommand.new for test isolation
  - DocumentRegistry tests now pass `project_root: @temp_dir` to ensure isolation
  - StatusCommand integration tests now pass `project_root: @temp_dir` to ensure isolation
  - All 15 document_registry tests now pass (was 13 failures, 1 error)
  - All 5 status_command_integration tests now pass (was 5 failures)
  - Root cause: Tests were discovering real ace-docs handbook files instead of temp directory files

- **Test Correctness**: Fixed DocumentAnalysisPromptTest assertions to match actual output format
  - Multi-subject scope section uses backtick-wrapped subject names (e.g., "`code`:" not "code:")
  - Fixed tests to properly create Document instances instead of using instance_variable_set
  - All 7 prompt tests now pass (was 3 failures)
  - Root cause: Tests were modifying @frontmatter without updating @ace_docs_config

### Technical

- Integrated standardized prompt caching system from ace-support-core
- Added 5 tests for ace-git option mapping (exclude_renames, exclude_moves, paths)

## [0.9.0] - 2025-11-16

### Changed

- **Standardized Prompt Cache Management**: Migrated to use PromptCacheManager from ace-support-core
  - Cache location now: `.cache/ace-docs/sessions/analyze-consistency-{timestamp}/`
  - System prompt file: `prompt-system.md` → `system.prompt.md`
  - User prompt file: `prompt-user.md` → `user.prompt.md`
  - Uses ProjectRootFinder for git worktree support (via PromptCacheManager)
  - Consistent with ace-review and future ace-* gems
  - **BREAKING**: Old cache file names no longer used (cache files are session-specific, not persistent)

### Dependencies

- Updated ace-support-core to `~> 0.11` (requires PromptCacheManager)

## [0.8.0] - 2025-11-15

### BREAKING CHANGE: ISO 8601 UTC Timestamp Format

- **Migrated timestamp format to ISO 8601 UTC standard**
  - New format: `YYYY-MM-DDTHH:MM:SSZ` (e.g., `2025-11-15T08:30:45Z`)
  - `"now"` special value now generates ISO 8601 UTC format (was local time)
  - All timestamps are stored and displayed in UTC
  - Aligns with industry standards (GitHub API, Git commits, ISO 8601)
  - Eliminates timezone ambiguity and DST issues

### Added

- **ISO 8601 UTC Timestamp Support**: Industry-standard timestamp format
  - Format: `YYYY-MM-DDTHH:MM:SSZ` with explicit UTC timezone
  - Unambiguous - `Z` suffix means UTC
  - Universal - Same timestamp for all users globally
  - Sortable - Lexicographic sorting works correctly
  - Parse-able - Standard format works with all datetime libraries
  - Special value `"now"` generates current UTC time
  - Special value `"today"` continues to generate date-only format

- **TimestampParser Atom**: Enhanced with ISO 8601 support
  - Parses ISO 8601 UTC strings → Time objects (UTC)
  - Parses date-only strings → Date objects
  - Parses legacy datetime strings → Time objects (converted to UTC)
  - Validates all three formats with regex patterns
  - Comprehensive error handling with migration guidance

- **Command-Level Tests**: New test coverage for CLI commands
  - `StatusCommand` tests for Date/Time polymorphic handling
  - Tests prevent regression bugs in CLI layer
  - Validates proper ISO 8601 display in UI

### Enhanced

- **FrontmatterManager**: Generates ISO 8601 UTC timestamps
  - `"now"` generates ISO 8601 UTC format
  - `"today"` generates date-only format
  - Converts legacy format to ISO 8601 automatically

- **Document Model**: UTC timezone handling
  - All Time objects converted to UTC
  - Maintains polymorphic return types (Date/Time)
  - Proper comparison and calculation with UTC times

- **StatusCommand**: Fixed crash and improved display
  - Fixed TypeError crash when handling Time objects
  - Displays full ISO 8601 timestamp for Time objects
  - Displays date-only for Date objects
  - No information loss - time component always visible

### Backward Compatibility

- **Legacy format fully supported**: `YYYY-MM-DD HH:MM` format still parsed
  - Interpreted as local time, converted to UTC internally
  - Will be deprecated in future major version
  - Provides clear migration path

### Documentation

- Updated README.md with ISO 8601 examples and format details
- Added comprehensive timestamp format reference
- Documented benefits of ISO 8601 UTC format
- Provided migration guide from legacy format
- Updated all examples to use ISO 8601

### Testing

- Added 85+ new tests with 200+ assertions for ISO 8601
  - ISO 8601 parsing and formatting tests
  - UTC conversion accuracy tests
  - Backward compatibility tests
  - Command-level integration tests
  - Edge case tests (year boundaries, leap seconds awareness)
- Edge case tests for year boundaries, month boundaries, leap years
- Integration tests for frontmatter preservation
- All tests passing with no regressions

## [0.7.0] - 2025-11-12

### Added

- **Workflow Migration**: Migrated 5 documentation generation workflows from dev-handbook
  - `create-api-docs.wf.md` - Generate API documentation from code structure
  - `create-user-docs.wf.md` - Create user-facing guides and tutorials
  - `update-blueprint.wf.md` - Maintain architectural documentation
  - `update-context-docs.wf.md` - Update project context documentation
  - `create-cookbook.wf.md` - Generate practical how-to guides
  - Consolidates all documentation workflows in ace-docs gem
  - Workflows accessible via `ace-nav wfi://workflow-name` protocol

### Changed

- **Path Modernization**: Updated all workflow references to use protocol-based paths
  - Replaced hardcoded `dev-handbook/workflow-instructions/load-project-context.wf.md` with `ace-nav wfi://load-context`
  - Updated existing workflows (create-adr, maintain-adrs) for consistency
  - All workflows now project-agnostic without hardcoded legacy paths

### Fixed

- **Frontmatter Corruption**: Restored proper YAML frontmatter in create-adr and maintain-adrs workflows
  - Fixed ace-lint formatting issue that collapsed multi-line YAML

## [0.6.2] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems


## [0.6.1] - 2025-10-24

### Technical
- Standardize diff/diffs API documentation to ace-git-diff format
- Update usage documentation to use `paths:` instead of `filters:` for consistency
- Update workflow instructions with standardized diff format

## [0.6.0] - 2025-10-23

### Changed
- Integrated with ace-git-diff for unified diff operations
- ChangeDetector now delegates generate_git_diff() to ace-git-diff
- Added ace-git-diff (~> 0.1.0) as runtime dependency
- Example configs updated with diff filtering notes

### Fixed
- Updated test mocks to work with ace-git-diff DiffResult objects
- All ChangeDetector tests passing (17 tests, 66 assertions)

## [0.5.3] - 2025-10-23

### Fixed

- **Configuration reading**: Now properly respects config file settings
  - Reads `llm.model` from config.yml in addition to `llm_model`
  - Configuration cascade now works correctly with nested config values
  - Model selection respects user configuration instead of ignoring it
- **Performance dramatically improved**: Changed default model from gflash to glite
  - Reduced analysis time from 2m28s to ~4-10s for typical document sets
  - Default model changed to "glite" for better performance
  - Still allows override via --model CLI option
- **Output handling**: Only displays report path, not content
  - Returns report file path instead of content from execute_llm_query
  - Prevents duplicate output to stdout
  - Cleaner command output showing only where report was saved

## [0.5.2] - 2025-10-23

### Fixed

- **Simplified analyze-consistency implementation**: Major refactoring for cleaner design
  - Now uses ace-llm's native `output:` option to save report directly as `report.md`
  - Removed redundant report processing and ConsistencyReport parsing
  - Eliminated duplicate file generation (no more separate `llm-response.json` and `report.json`)
  - Report is displayed directly as returned by LLM without reformatting
- **Fixed cache directory path**: Now uses git root for absolute paths
  - Prevents nested `.cache/ace-docs/.cache/ace-docs/...` directory creation
  - Cache directory is always created from project root regardless of where command is run
  - Consistent path handling across all commands

### Changed

- **Cleaner session directory**: Simplified output structure
  - Only saves `report.md` (the actual LLM response)
  - Removed redundant `save_report` and `save_llm_response` methods
  - Less files, clearer purpose

## [0.5.1] - 2025-10-21

### Fixed

- **Critical bug in analyze-consistency command**: Fixed LLM response handling
  - Changed from checking non-existent `result[:success]` to using `result[:text]` directly
  - Now uses ace-llm's native `output:` option to save responses immediately
  - Prevents loss of LLM compute when errors occur
  - Response saved to `llm-response.json` before any validation
- **Removed unnecessary document copying**: Uses real file paths instead of copying to temp files
  - Session directory now only contains metadata and prompts, not document copies
  - ace-bundle loads documents directly from their actual locations
  - Cleaner session directory structure and better path references in analysis
- **Better error messages**: Shows actual API errors instead of generic "Unknown error"
- **Added progress indicators**: Shows detailed progress during analysis phases

## [0.5.0] - 2025-10-21

### Added

- **Cross-document consistency analysis command** (`analyze-consistency`)
  - Detects terminology conflicts across documents (e.g., "gem" vs "package")
  - Identifies duplicate content with configurable similarity threshold
  - Finds version number inconsistencies
  - Suggests content consolidation opportunities
  - LLM-powered semantic analysis using ace-llm Ruby library
  - Multiple output formats: markdown, json, text
  - Caching support for historical comparison
  - Configurable analysis focus (--terminology, --duplicates, --versions)
  - Strict mode for CI/CD integration (exit code 1 if issues found)

### Fixed

- Use ace-llm Ruby library directly instead of subprocess for better performance
- Test failures and improved test performance

### Technical

- New prompts module for consistency analysis
- New models for consistency report handling
- New organisms for cross-document analysis orchestration
- New command implementation for analyze-consistency
- Updated README with comprehensive examples
- Added architecture documentation with flow diagrams

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
- Diff file paths now use absolute paths for proper ace-bundle loading

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
  - Removed document embedding and ace-bundle integration from analysis workflow
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
  - Shows ace-bundle integration patterns

- **ace-bundle Integration**: Optional structured context embedding
  - Uses `Ace::Context.load_auto()` with markdown-xml format
  - Embeds document and related files using XML tags (`<file path="...">`)
  - Creates `context.yml` configuration in analyze cache directory
  - Graceful fallback when ace-bundle unavailable (optional dependency)

### Changed

- **Cache Structure**: Now includes `context.yml` for full reproducibility
  ```
  .cache/ace-docs/analyze-{timestamp}/
    ├── repo-diff.diff        # Filtered raw diff
    ├── context.yml           # ace-bundle configuration (NEW)
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
- ace-bundle is optional (graceful degradation when unavailable)

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
  - Uses ace-llm subprocess with gflash model (temperature 0.3)
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
  - `validate_semantic()` now calls ace-llm subprocess
  - Builds semantic validation prompt from document metadata
  - Parses LLM response for validation status and issues
  - Graceful error handling for missing ace-llm

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
  - LLM compaction via ace-llm subprocess integration
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


## [0.20.2] - 2026-02-22

### Fixed
- Stripped duplicate command name prefixes from example strings
- Standardized quiet, verbose, debug option descriptions to canonical strings
