# Changelog

All notable changes to ace-context will be documented in this file.

The format is based on [Keep a Changelog][1], and this project adheres to [Semantic Versioning][2].

## [Unreleased]

## [0.22.2] - 2026-01-01

### Changed

* Add thread-safe configuration initialization with Mutex pattern
* Add configurable timeouts from gem config file

## [0.22.1] - 2025-12-30

### Changed

* Add ace-config dependency for configuration cascade management
* Migrate from Ace::Core to Ace::Config API for preset loading

## [0.22.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory

## [0.21.0] - 2025-12-29

### Changed

* Migrate ProjectRootFinder dependency from `Ace::Core::Molecules` to `Ace::Support::Fs::Molecules` for direct ace-support-fs usage

## [0.20.0] - 2025-12-26

### Changed

* **Migrated to ace-git Package**: Replaced internal Git/GitHub components with ace-git dependency
  * Replaced `ace-git-diff` (~> 0.1.0) dependency with `ace-git` (~> 0.3)
  * Removed internal `Atoms::GitExtractor` - now uses `Ace::Git::Organisms::DiffOrchestrator`
  * Removed internal `Atoms::PrIdentifierParser` - now uses `Ace::Git::Atoms::PrIdentifierParser`
  * Removed internal `Molecules::GhPrExecutor` - now uses `Ace::Git::Molecules::PrMetadataFetcher`
  * Uses centralized ace-git error types (`Ace::Git::GhNotInstalledError`, etc.)
  * Timeout configuration now comes from ace-git config (`Ace::Git.network_timeout`)

### Removed

* **Internal Git Modules**: Deleted in favor of ace-git package equivalents
  * `lib/ace/context/atoms/git_extractor.rb` - Use `Ace::Git::Organisms::DiffOrchestrator` instead
  * `lib/ace/context/atoms/pr_identifier_parser.rb` - Use `Ace::Git::Atoms::PrIdentifierParser` instead
  * `lib/ace/context/molecules/gh_pr_executor.rb` - Use `Ace::Git::Molecules::PrMetadataFetcher` instead

### Technical

* Reduced code duplication by centralizing Git operations in ace-git
* Simplified ace-context responsibility to focus on context loading
* All existing functionality preserved with API compatibility
* Improved error handling: use specific `Ace::Git::GitError` instead of `StandardError` in diff processing
* Added adapter tests for ace-git error type handling (`GhNotInstalledError`, `GhAuthenticationError`, `PrNotFoundError`, `TimeoutError`)

## [0.19.2] - 2025-12-16

### Fixed

* **PR Array Handling**: Fixed `pr:` array handling where multiple PRs only showed the first one
  * Arrays like `pr: [123, 456]` now correctly fetch and display all PR diffs
  * Improved context diff detection and PR subject parsing

### Changed

* **Diff Merging Refinement**: Extract ContentChecker atom and improve diff merging logic
  * Added PR reference validation for better error handling
  * Refactored internal diff processing for cleaner architecture

### Technical

* Added comprehensive test coverage for PR and section processing features

## [0.19.1] - 2025-12-16

### Fixed

* **Nested Context Config Support**: Fixed `load_inline_yaml` to unwrap nested `context:` key for template processing
  * Typed subjects from ace-review use nested structure like `context: { diffs: [...] }`
  * `process_template_config` now receives the unwrapped config, matching flat config behavior
  * Both `diffs: [HEAD~1]` and `context: { diffs: [HEAD~1] }` now produce identical output
  * Fixes empty content issue when using ace-review typed subjects (`diff:`, `files:`, `task:`)

* **PR Processing Format Guard**: Improved `load_inline_yaml` to format context after PR processing
  * `process_pr_config` now returns boolean indicating whether PR config was present
  * `format_context` is called when either sections exist OR PR processing was attempted
  * Ensures consistent output formatting even when PR fetches fail or return empty

* **Inline YAML PR Handling**: Fixed `load_inline_yaml` to properly format PR diffs into output content
  * PR diffs added via `process_pr_config` were not being formatted into `context.content`
  * Added `format_context` call after PR processing when sections are present
  * Also added `pr:` keyword detection in `load_auto` for proper inline YAML routing
  * Enables direct API usage like `Ace::Context.load_auto("pr: 123")` to return formatted PR diff content

## [0.19.0] - 2025-12-16

### Added

* **PR Diff Support**: New `pr:` configuration key enables loading GitHub Pull Request diffs via `gh` CLI
  * Supports three PR identifier formats: simple number (`123`), qualified reference (`owner/repo#456`), and GitHub URL (`https://github.com/owner/repo/pull/789`)
  * Single PR: `pr: 123` or multiple PRs: `pr: [123, "owner/repo#456"]`
  * PR diffs wrapped in `<diff source="pr:{id}">` tags in output
  * Graceful error handling for gh not installed, authentication failures, and PR not found errors
  * Continues processing other sources if individual PR fetches fail
  * Added `PrIdentifierParser` atom for parsing PR identifiers (22 tests, 100% coverage)
  * Added `GhPrExecutor` molecule for safe gh CLI execution with comprehensive error handling (12 tests)
  * Integrated into `ContextLoader.process_template_config` alongside existing diff processing
* **CLI Flag for Source Embedding**: New `--embed-source` (`-e`) flag enables embedding source documents in output
  * Overrides `embed_document_source` frontmatter setting when present
  * Enables ace-prompt to delegate all context aggregation to ace-context
  * Works with all output formats (markdown, markdown-xml, yaml, json)
  * Maintains backward compatibility (default: false)
  * Added comprehensive test coverage for flag precedence and behavior
  * Updated documentation in README.md and docs/usage.md
* **Inline Base Content Support**: New capability to use inline strings for `context.base` configuration
  * Automatically detects whether `base` value is a file path or inline content
  * File paths (with slashes, protocols, or extensions) are resolved as files
  * Simple strings without path indicators are treated as inline content
  * Prioritizes file resolution for extension-less files (README, CONTEXT, etc.)
  * Adds metadata fields: `base_type` ('file' or 'inline'), `base_ref`, `base_path`
  * Enables flexible base context definition without requiring separate files

### Changed

* **Test Infrastructure Alignment**: Renamed test base class from `AceContextTest` to `AceTestCase`
  * Aligns with standardized Minitest infrastructure established in ace-test-support
  * Improves consistency across all ace-context test files
  * Maintains all existing test functionality

### Fixed

* **Nil Guard in CLI Overrides**: Added nil guard in `apply_cli_overrides` method to prevent `NoMethodError` when config
  is nil
* **Extension-less File Resolution**: Improved `process_base_content` to correctly handle files without extensions
  (README, CONTEXT)
  * File resolution now prioritizes existence checks before treating values as inline content
  * Prevents extension-less filenames from being incorrectly treated as inline strings
* **File Loading Method Reference**: Corrected `load_file` reference in multi-file processing (was incorrectly calling
  `load_file_as_preset`)

## [0.18.2] - 2025-12-02

### Fixed

* **Top-Level Preset Support**: Enable `context.presets` at configuration root level
  * Process preset references in top-level context configuration (not just within sections)
  * Merge files, commands, and params from referenced presets
  * Apply "current config wins" precedence for overrides
* **Fail-Fast Error Handling**: Improve error handling for preset loading
  * Raise clear error when any referenced preset fails to load
  * Remove silent debug-only warnings for preset failures
  * Consistent error propagation through load chain
* **Code Quality**: Remove `.send()` usage for merge_preset_data
  * Make merge_preset_data public method instead of using reflection
  * Cleaner API surface for preset composition

## [0.18.1] - 2025-11-16

### Changed

* **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  * Provides access to latest PromptCacheManager features and infrastructure improvements
  * Maintains compatibility with standardized ACE ecosystem patterns

## [0.18.0] - 2025-11-10

### Added

* Add context.base support for generic base content handling
  * New `context.base` field enables loading base content from files or protocol references
  * Base content appears before sections in formatted output
  * Supports protocol resolution via ace-nav (e.g., `prompt://base/system`)
  * Graceful error handling for missing files or invalid protocols
  * Comprehensive test coverage with 7 new test cases

### Fixed

* Treat file-based configs same as presets for sections and formatting
  * Files loaded via `load_template` now process sections correctly
  * File-based configs now format output before returning (matching preset behavior)
  * Fixes inconsistency where sections worked in presets but not in direct file loading
  * ace-review integration now generates full section content (1613 lines vs 29 before)

## [0.17.6] - 2025-11-10

### Added

* **Diff Configuration Enhancements**: Support for both simple and complex diff formats
  * Added `diff` key with complex structure support: `{ ranges: [...], since: "...", paths: [...] }`
  * Maintained backward compatibility with legacy `diffs` array format
  * Support for `since` parameter that expands to `since...HEAD` range format
  * Normalization of all diff formats to internal `ranges` structure in SectionProcessor
  * Comprehensive test coverage with 16 unit tests for format normalization
  * Updated documentation with clear examples and format comparison guide

## [0.17.5] - 2025-11-09

### Fixed

* **PR Review Preset Configuration**: Removed hardcoded PR number from `.ace/review/presets/pr.yml`
  * Changed from `gh pr diff 18` to generic `git diff origin/main...HEAD`
  * Added `git log origin/main..HEAD --oneline` for commit history
  * Now works for any PR branch, not just PR #18

### Changed

* **Documentation Enhancement**: Added comprehensive preset nesting depth guidelines
  * Documented recommended maximum depth of 3-4 levels for optimal performance
  * Included examples of good (2-3 levels), acceptable (4 levels), and poor (5+ levels) nesting
  * Added refactoring guidance for deep nesting scenarios
  * Performance impact table showing load time vs maintainability trade-offs

## [0.17.4] - 2025-11-07

### Fixed

* **Critical Format Regression**: Fixed markdown-xml format not being applied to section-based presets
  * Issue was in PresetManager where preset format defaulted to 'markdown' instead of respecting CLI options
  * Removed hardcoded format default in `load_preset_from_file` method
  * Preset composition no longer overrides explicitly requested formats
  * CLI `--format markdown-xml` option now works correctly with sections
* **Format Parameter Propagation**: Ensured format parameters flow correctly from CLI through ContextLoader
  * CLI format options properly propagate through the entire processing chain
  * `embed_document_source: true` now correctly defaults to `markdown-xml` format
  * Explicit format specifications take precedence over preset defaults

### Technical

* Modified `PresetManager#load_preset_from_file` to not set hardcoded format defaults
* Updated `PresetManager#merge_preset_data` to preserve format resolution in ContextLoader
* All 27 integration tests passing with no regressions
* Verified XML output format with proper section tags and file order preservation

## [0.17.3] - 2025-11-07

### Added

* **Integration Tests**: Added comprehensive integration tests based on Gemini Pro review feedback
  * Complex section workflow integration test (`section_workflow_integration_test.rb`)
  * Security review section test with preset-in-section functionality (`security_review_section_test.rb`)
  * Tests validate end-to-end workflow, XML output format, and error handling
* **Documentation Enhancements**: Improved user experience with better guidance
  * Added composition best practice note to `configuration.md` to prevent over-composition
  * Added preset discovery section to `usage.md` with filesystem navigation tips
  * References enhanced error messages that list available presets

### Technical

* All 98 tests passing (17 atoms + 43 molecules + 11 organisms + 27 integration tests)
* No regressions introduced with new functionality
* Enhanced test coverage for section-based workflows and preset composition

## [0.17.2] - 2025-11-06

### Added

* **Documentation Restructuring**: Enhanced user documentation with clear separation
  * Renamed `section_guide.md` → `configuration.md` covering all YAML configuration options
  * Added new `usage.md` with comprehensive command-line interface documentation
  * Removed outdated documentation files

### Fixed

* **Critical Section Merging Bug**: Fixed issue where sections without `content_type` were losing content during merging
  * Implemented content detection based on actual keys present (`files?`, `commands?`, etc.)
  * Added comprehensive helper methods for content type detection
  * Resolved data loss when merging sections with mixed content types
* **Enhanced Error Messages**: Improved error reporting with better context and troubleshooting guidance
  * Section validation errors now include specific fix suggestions
  * Preset loading errors show available preset options
  * Dependency resolution errors provide clear action items for users

### Changed

* **Code Refactoring**: Improved performance and maintainability
  * Refactored `detect_language` method to use Hash lookup instead of case statement
  * Centralized content detection helper methods in `SectionProcessor`
  * Simplified test suite by removing deprecated `content_type` references
* **Test Enhancements**: Added comprehensive integration tests
  * Added integration tests for section merging without `content_type`
  * Updated all tests to work with simplified validation approach
  * All 91 tests now passing (0 failures, 0 errors)

## [0.17.1] - 2025-11-06

### Fixed

* **Section Processing**: Fixed critical issues with section-based content organization
  * Resolved embed\_document\_source access bug in ContextLoader
  * Fixed file order preservation within sections to maintain preset configuration order
  * Fixed exclude pattern handling in legacy-to-section migration
  * Fixed command processing to maintain backward compatibility
  * Fixed format detection to respect explicit format requests
  * Fixed infinite recursion bug in format\_sections\_for\_yaml method
* **Test Suite**: All ace-context tests now passing (91 tests, 0 failures, 0 errors)

## [0.17.0] - 2025-11-06

### Added

* **Preset-in-Section Functionality**: Allow sections to reference and combine multiple presets
  * Sections can now contain `presets` field with array of preset names
  * Full preset composition support within sections with circular dependency detection
  * Intelligent content merging with automatic deduplication of files and commands
  * Mixed content support - combine preset content with local files, commands, and content
  * Comprehensive error handling for missing or invalid preset references
* **Enhanced Section System**: Improved section-based content organization
  * Removed content\_type and priority requirements for simpler usage
  * YAML order preservation for natural section sequencing
  * Better mixed content support within single sections
* **Comprehensive Testing**: Full test coverage for preset-in-section functionality
  * SectionValidator updates for preset validation
  * SectionProcessor enhancements for nested preset composition
  * ContextLoader integration for preset processing
  * Error handling and edge case coverage
* **Documentation and Examples**: Complete usage guide and examples
  * Updated section guide with preset-in-section documentation
  * New example presets demonstrating functionality
  * Migration guide and best practices

### Technical

* Updated ace-support-core dependency references
* Enhanced validation and error handling systems
* Improved content merging algorithms for mixed data types

## [0.16.1] - 2025-11-01

### Changed

* **Dependency Migration**: Updated to use renamed infrastructure gems
  * Changed dependency from `ace-core` to `ace-support-core`
  * Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.16.0] - 2025-10-24

### Added

* Enable file path and protocol arguments for ace:load-context command
* New workflow file `handbook/workflow-instructions/load-context.wf.md` with flexible input support
* Source registrations for wfi:// protocol discovery (ace-context.yml)
* Support for preset names, file paths, and protocol URLs in context loading

### Changed

* Compact load-context workflow from 127 to 98 lines (23% reduction)
* Convert error handling to scannable table format
* Merge redundant sections for improved readability

### Technical

* Update README and documentation examples for flexible input
* Update slash command to thin interface pattern (delegates to wfi://load-context)

## [0.15.1] - 2025-10-24

### Fixed

* Address PR #3 review issues for ace-git-diff integration

### Technical

* Standardize diff/diffs API documentation to ace-git-diff format
* Update changelog and version documentation

## [0.15.0] - 2025-10-23

### Changed

* Integrated with ace-git-diff for unified diff operations
* GitExtractor now delegates all diff methods to ace-git-diff
* `git_diff()`, `staged_diff()`, `working_diff()` now use ace-git-diff for consistent filtering
* Added ace-git-diff (~> 0.1.0) as runtime dependency
* Example preset configs updated to show diff: key usage

### Technical

* Maintains full backward compatibility for all public APIs
* extract\_diff() still uses direct git command for detailed error reporting

## [0.14.2] - 2025-10-18

### Fixed

* `load_file_as_preset` now extracts markdown body content after frontmatter for proper formatting
* File paths always resolve from project root (forced `base_dir` to `project_root` in merged options)
* Body content included in preset\_data structure for content formatting
* Files embedded as XML when `embed_document_source` is true (calls `format_context`)

## [0.14.1] - 2025-10-18

### Fixed

* Preset composition merge order in file loading - presets now properly override each other in sequence before file
  config applies
* `inspect_config` now handles preset composition when files reference presets via `presets:` key
* `compose_file_with_presets` now merges all presets together first, then applies file config last (file config
  correctly wins over all presets)
* Correct argument format for `merge_preset_data` calls - wrapped contexts in preset structures

## [0.14.0] - 2025-10-18

### Added

* File configuration loading via `-f/--file` CLI option
* Support for YAML files and markdown with frontmatter as configuration sources
* Multiple file loading with `-f file1.yml -f file2.md`
* Mix presets and files: `ace-context -p base -f custom.yml`
* Files can reference and compose with existing presets via `presets:` key
* New public API methods: `load_file_as_preset` and `load_multiple_inputs`
* Comprehensive file loading tests

### Changed

* Enhanced `inspect_config` to handle both presets and files
* Updated CLI help with file loading examples
* Expanded documentation with file configuration section
* Improved CLI help message to clarify positional argument accepts multiple input types (preset, file, protocol, inline
  YAML)
* Added input auto-detection documentation to README

## [0.13.0] - 2025-10-17

### Added

* Preset composition support via `presets:` array in YAML configuration
* CLI accepts multiple presets via `-p` flags or `--presets` comma-separated list
* Configuration inspection mode with `--inspect-config` flag
* Intelligent merging: arrays deduplicated, scalars follow "last wins" pattern
* Circular dependency detection for preset references
* Example composed presets (base, development, team)

### Fixed

* Extract all params to root level in preset composition
* Store preset output mode in metadata for multi-preset loading
* Cache filename generation for multi-preset mode

## [0.12.0] - 2025-10-14

### Added

* Standardize Rakefile test commands and add CI fallback

## [0.11.4] - 2025-10-07

### Changed

* **Unified XML embedding format across all loading methods** (Breaking change)
  * Preset loading now uses XML format when `embed_document_source: true`
  * Files embedded as `<file path="...">content</file>` instead of markdown headers
  * Commands embedded as `<command name="..." success="true">output</command>` instead of markdown sections
  * Consistent format between protocol loading (`wfi://`) and preset loading (`--preset`)
  * **Impact**: Better nesting support for markdown files, clearer boundaries for LLM agents
  * **Migration**: If parsing preset output with `embed_document_source: true`, expect XML format instead of markdown
    headers

### Fixed

* **Preset loading formatter inconsistency**
  * Presets with `embed_document_source: true` now trigger XML formatting
  * Previously used markdown headers (### filename.md) while protocols used XML
  * Now both methods use `<files>` and `<file>` tags consistently
  * Default format is now `markdown-xml` when `embed_document_source: true`

## [0.11.3] - 2025-10-07

### Fixed

* **Incomplete migration from top-level params to context.params**
  * PresetManager now correctly reads params from `context.params` location
  * Previously only read from top-level `params:` (old structure)
  * Fixes issue where `context.params.output` and other params were ignored
* **File embedding not working with embed\_document\_source**
  * ContextLoader now correctly checks `context.embed_document_source` flag
  * Previously only checked deprecated `embed_itself` flag
  * Fixes issue where files listed in `context.files` were not embedded in output

### Changed

* **Removed backward compatibility** (pre-1.0 breaking change)
  * No longer supports top-level `params:` structure
  * No longer supports `embed_itself` flag
  * Only `context.params` and `embed_document_source` are supported
  * All tests updated to use new structure exclusively

### Migration Guide

Old structure (no longer supported):

    params:
      output: cache
      embed_itself: true
    context:
      files: [...]
{: .language-yaml}

New structure (required):

    context:
      params:
        output: cache
      embed_document_source: true
      files: [...]
{: .language-yaml}

## [0.11.2] - 2025-10-06

### Changed

* **`embed_document_source` output format** - Raw content with XML blocks
  * Source document now output as unmodified raw content (frontmatter + markdown)
  * Embedded files, commands, and diffs wrapped in semantic XML blocks: `<files>`, `<commands>`, `<diffs>`
  * Removed "# Context" wrapper and markdown sections when embedding source
  * **Impact**: Cleaner separation between source document and embedded content
  * **Use case**: Workflow files can embed themselves with their dependent workflows in proper format

### Fixed

* **Frontmatter preservation in output** - YAML format maintained
  * Original YAML frontmatter now output with `---` delimiters instead of bulleted list
  * Applies to both `markdown` and `markdown-xml` output formats when using `embed_document_source`

## [0.11.1] - 2025-10-06

### Fixed

* **Regex anchor bug in `load_auto`** - Critical bugfix for YAML config detection
  * Changed `/^[\w-]+$/` to `/\A[\w-]+\z/` to match string boundaries, not line boundaries
  * Fixed protocol detection regex `/^[\w-]+:\/\//` to `/\A[\w-]+:\/\//`
  * Added detection for `include:`, `diffs:`, `presets:` keys in inline YAML
  * **Impact**: YAML configs like `files: ["lib/**/*.rb"]` were incorrectly detected as preset "---"
  * **Fixes**: "No code to review" error in ace-review when using file/diff configs
* **Glob pattern support in `files:` configuration**
  * Added automatic detection of glob characters (`*`, `?`, `[`) in file patterns
  * Routes glob patterns to `aggregate()` and literal paths to `aggregate_files()`
  * Added `exclude:` parameter support in file aggregation
  * **Impact**: Patterns like `lib/**/*.rb` now correctly expand to matching files

## [0.11.0] - 2025-10-06

### Added

* **Protocol resolution support** via ace-nav integration
  * Load resources using protocols: `ace-context wfi://workflow-name`
  * Supported protocols: `wfi://` (workflows), `guide://`, `task://`, and any ace-nav protocol
  * Works in input arguments and `context.files` arrays
* **YAML frontmatter template support**
  * Detect and process files with YAML frontmatter (starts with `---`)
  * Support `context:` key in frontmatter for configuration
  * Merge `params:` from frontmatter into processing options
* **Workflow embedding via protocols**
  * Reference workflows in `context.files: [wfi://draft-task, wfi://plan-task]`
  * Automatic recursive protocol resolution
  * Zero duplication - workflows reference each other declaratively

### Changed

* `load_auto()` now detects `://` pattern and delegates to protocol resolution
* `load_file()` treats files with YAML frontmatter as templates
* `load_template()` processes frontmatter config directly when `context:` key present
* CLI updated to use `load_auto()` instead of `load_preset()` for flexible input handling

### Technical Details

* `resolve_protocol()` delegates to `ace-nav` for path resolution
* `resolve_file_reference()` handles protocols in file arrays
* Protocol resolution integrated in both preset and template config processing
* Maintains backward compatibility with existing file paths, presets, and inline YAML

## [0.10.0] - 2025-10-06

### Added

* Git diff support via `diffs:` configuration key
* `Ace::Context::Atoms::GitExtractor` for secure git operations
* Support for combining files, commands, diffs, and presets in unified configuration
* Git diff formatting in all output modes (markdown, xml, markdown-xml, json, yaml)
* Comprehensive test suite for git operations (10 tests)

### Changed

* ace-core `OutputFormatter` now handles diffs section in all formats
* README updated with Content Sources section documenting all supported types

## [0.9.0] - 2025-10-05

Initial release with preset management, file aggregation, and command execution support.



[1]: https://keepachangelog.com/en/1.0.0/
[2]: https://semver.org/spec/v2.0.0.html
