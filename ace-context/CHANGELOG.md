# Changelog

All notable changes to ace-context will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.17.4] - 2025-11-07

### Fixed
- **Critical Format Regression**: Fixed markdown-xml format not being applied to section-based presets
  - Issue was in PresetManager where preset format defaulted to 'markdown' instead of respecting CLI options
  - Removed hardcoded format default in `load_preset_from_file` method
  - Preset composition no longer overrides explicitly requested formats
  - CLI `--format markdown-xml` option now works correctly with sections

- **Format Parameter Propagation**: Ensured format parameters flow correctly from CLI through ContextLoader
  - CLI format options properly propagate through the entire processing chain
  - `embed_document_source: true` now correctly defaults to `markdown-xml` format
  - Explicit format specifications take precedence over preset defaults

### Technical
- Modified `PresetManager#load_preset_from_file` to not set hardcoded format defaults
- Updated `PresetManager#merge_preset_data` to preserve format resolution in ContextLoader
- All 27 integration tests passing with no regressions
- Verified XML output format with proper section tags and file order preservation

## [Unreleased]

## [0.17.3] - 2025-11-07

### Added
- **Integration Tests**: Added comprehensive integration tests based on Gemini Pro review feedback
  - Complex section workflow integration test (`section_workflow_integration_test.rb`)
  - Security review section test with preset-in-section functionality (`security_review_section_test.rb`)
  - Tests validate end-to-end workflow, XML output format, and error handling

- **Documentation Enhancements**: Improved user experience with better guidance
  - Added composition best practice note to `configuration.md` to prevent over-composition
  - Added preset discovery section to `usage.md` with filesystem navigation tips
  - References enhanced error messages that list available presets

### Technical
- All 98 tests passing (17 atoms + 43 molecules + 11 organisms + 27 integration tests)
- No regressions introduced with new functionality
- Enhanced test coverage for section-based workflows and preset composition

## [0.17.2] - 2025-11-06

### Added
- **Documentation Restructuring**: Enhanced user documentation with clear separation
  - Renamed `section_guide.md` → `configuration.md` covering all YAML configuration options
  - Added new `usage.md` with comprehensive command-line interface documentation
  - Removed outdated documentation files

### Fixed
- **Critical Section Merging Bug**: Fixed issue where sections without `content_type` were losing content during merging
  - Implemented content detection based on actual keys present (`files?`, `commands?`, etc.)
  - Added comprehensive helper methods for content type detection
  - Resolved data loss when merging sections with mixed content types

- **Enhanced Error Messages**: Improved error reporting with better context and troubleshooting guidance
  - Section validation errors now include specific fix suggestions
  - Preset loading errors show available preset options
  - Dependency resolution errors provide clear action items for users

### Changed
- **Code Refactoring**: Improved performance and maintainability
  - Refactored `detect_language` method to use Hash lookup instead of case statement
  - Centralized content detection helper methods in `SectionProcessor`
  - Simplified test suite by removing deprecated `content_type` references

- **Test Enhancements**: Added comprehensive integration tests
  - Added integration tests for section merging without `content_type`
  - Updated all tests to work with simplified validation approach
  - All 91 tests now passing (0 failures, 0 errors)

## [0.17.1] - 2025-11-06

### Fixed
- **Section Processing**: Fixed critical issues with section-based content organization
  - Resolved embed_document_source access bug in ContextLoader
  - Fixed file order preservation within sections to maintain preset configuration order
  - Fixed exclude pattern handling in legacy-to-section migration
  - Fixed command processing to maintain backward compatibility
  - Fixed format detection to respect explicit format requests
  - Fixed infinite recursion bug in format_sections_for_yaml method
- **Test Suite**: All ace-context tests now passing (91 tests, 0 failures, 0 errors)

## [0.17.0] - 2025-11-06

### Added
- **Preset-in-Section Functionality**: Allow sections to reference and combine multiple presets
  - Sections can now contain `presets` field with array of preset names
  - Full preset composition support within sections with circular dependency detection
  - Intelligent content merging with automatic deduplication of files and commands
  - Mixed content support - combine preset content with local files, commands, and content
  - Comprehensive error handling for missing or invalid preset references

- **Enhanced Section System**: Improved section-based content organization
  - Removed content_type and priority requirements for simpler usage
  - YAML order preservation for natural section sequencing
  - Better mixed content support within single sections

- **Comprehensive Testing**: Full test coverage for preset-in-section functionality
  - SectionValidator updates for preset validation
  - SectionProcessor enhancements for nested preset composition
  - ContextLoader integration for preset processing
  - Error handling and edge case coverage

- **Documentation and Examples**: Complete usage guide and examples
  - Updated section guide with preset-in-section documentation
  - New example presets demonstrating functionality
  - Migration guide and best practices

### Technical
- Updated ace-support-core dependency references
- Enhanced validation and error handling systems
- Improved content merging algorithms for mixed data types

## [0.16.1] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.16.0]
 - 2025-10-24

### Added
- Enable file path and protocol arguments for ace:load-context command
- New workflow file `handbook/workflow-instructions/load-context.wf.md` with flexible input support
- Source registrations for wfi:// protocol discovery (ace-context.yml)
- Support for preset names, file paths, and protocol URLs in context loading

### Changed
- Compact load-context workflow from 127 to 98 lines (23% reduction)
- Convert error handling to scannable table format
- Merge redundant sections for improved readability

### Technical
- Update README and documentation examples for flexible input
- Update slash command to thin interface pattern (delegates to wfi://load-context)

## [0.15.1] - 2025-10-24

### Fixed
- Address PR #3 review issues for ace-git-diff integration

### Technical
- Standardize diff/diffs API documentation to ace-git-diff format
- Update changelog and version documentation

## [0.15.0] - 2025-10-23

### Changed
- Integrated with ace-git-diff for unified diff operations
- GitExtractor now delegates all diff methods to ace-git-diff
- `git_diff()`, `staged_diff()`, `working_diff()` now use ace-git-diff for consistent filtering
- Added ace-git-diff (~> 0.1.0) as runtime dependency
- Example preset configs updated to show diff: key usage

### Technical
- Maintains full backward compatibility for all public APIs
- extract_diff() still uses direct git command for detailed error reporting

## [0.14.2] - 2025-10-18

### Fixed
- `load_file_as_preset` now extracts markdown body content after frontmatter for proper formatting
- File paths always resolve from project root (forced `base_dir` to `project_root` in merged options)
- Body content included in preset_data structure for content formatting
- Files embedded as XML when `embed_document_source` is true (calls `format_context`)

## [0.14.1] - 2025-10-18

### Fixed
- Preset composition merge order in file loading - presets now properly override each other in sequence before file config applies
- `inspect_config` now handles preset composition when files reference presets via `presets:` key
- `compose_file_with_presets` now merges all presets together first, then applies file config last (file config correctly wins over all presets)
- Correct argument format for `merge_preset_data` calls - wrapped contexts in preset structures

## [0.14.0] - 2025-10-18

### Added
- File configuration loading via `-f/--file` CLI option
- Support for YAML files and markdown with frontmatter as configuration sources
- Multiple file loading with `-f file1.yml -f file2.md`
- Mix presets and files: `ace-context -p base -f custom.yml`
- Files can reference and compose with existing presets via `presets:` key
- New public API methods: `load_file_as_preset` and `load_multiple_inputs`
- Comprehensive file loading tests

### Changed
- Enhanced `inspect_config` to handle both presets and files
- Updated CLI help with file loading examples
- Expanded documentation with file configuration section
- Improved CLI help message to clarify positional argument accepts multiple input types (preset, file, protocol, inline YAML)
- Added input auto-detection documentation to README

## [0.13.0] - 2025-10-17

### Added
- Preset composition support via `presets:` array in YAML configuration
- CLI accepts multiple presets via `-p` flags or `--presets` comma-separated list
- Configuration inspection mode with `--inspect-config` flag
- Intelligent merging: arrays deduplicated, scalars follow "last wins" pattern
- Circular dependency detection for preset references
- Example composed presets (base, development, team)

### Fixed
- Extract all params to root level in preset composition
- Store preset output mode in metadata for multi-preset loading
- Cache filename generation for multi-preset mode

## [0.12.0] - 2025-10-14

### Added
- Standardize Rakefile test commands and add CI fallback

## [0.11.4] - 2025-10-07

### Changed
- **Unified XML embedding format across all loading methods** (Breaking change)
  - Preset loading now uses XML format when `embed_document_source: true`
  - Files embedded as `<file path="...">content</file>` instead of markdown headers
  - Commands embedded as `<command name="..." success="true">output</command>` instead of markdown sections
  - Consistent format between protocol loading (`wfi://`) and preset loading (`--preset`)
  - **Impact**: Better nesting support for markdown files, clearer boundaries for LLM agents
  - **Migration**: If parsing preset output with `embed_document_source: true`, expect XML format instead of markdown headers

### Fixed
- **Preset loading formatter inconsistency**
  - Presets with `embed_document_source: true` now trigger XML formatting
  - Previously used markdown headers (### filename.md) while protocols used XML
  - Now both methods use `<files>` and `<file>` tags consistently
  - Default format is now `markdown-xml` when `embed_document_source: true`

## [0.11.3] - 2025-10-07

### Fixed
- **Incomplete migration from top-level params to context.params**
  - PresetManager now correctly reads params from `context.params` location
  - Previously only read from top-level `params:` (old structure)
  - Fixes issue where `context.params.output` and other params were ignored
- **File embedding not working with embed_document_source**
  - ContextLoader now correctly checks `context.embed_document_source` flag
  - Previously only checked deprecated `embed_itself` flag
  - Fixes issue where files listed in `context.files` were not embedded in output

### Changed
- **Removed backward compatibility** (pre-1.0 breaking change)
  - No longer supports top-level `params:` structure
  - No longer supports `embed_itself` flag
  - Only `context.params` and `embed_document_source` are supported
  - All tests updated to use new structure exclusively

### Migration Guide
Old structure (no longer supported):
```yaml
params:
  output: cache
  embed_itself: true
context:
  files: [...]
```

New structure (required):
```yaml
context:
  params:
    output: cache
  embed_document_source: true
  files: [...]
```

## [0.11.2] - 2025-10-06

### Changed
- **`embed_document_source` output format** - Raw content with XML blocks
  - Source document now output as unmodified raw content (frontmatter + markdown)
  - Embedded files, commands, and diffs wrapped in semantic XML blocks: `<files>`, `<commands>`, `<diffs>`
  - Removed "# Context" wrapper and markdown sections when embedding source
  - **Impact**: Cleaner separation between source document and embedded content
  - **Use case**: Workflow files can embed themselves with their dependent workflows in proper format

### Fixed
- **Frontmatter preservation in output** - YAML format maintained
  - Original YAML frontmatter now output with `---` delimiters instead of bulleted list
  - Applies to both `markdown` and `markdown-xml` output formats when using `embed_document_source`

## [0.11.1] - 2025-10-06

### Fixed
- **Regex anchor bug in `load_auto`** - Critical bugfix for YAML config detection
  - Changed `/^[\w-]+$/` to `/\A[\w-]+\z/` to match string boundaries, not line boundaries
  - Fixed protocol detection regex `/^[\w-]+:\/\//` to `/\A[\w-]+:\/\//`
  - Added detection for `include:`, `diffs:`, `presets:` keys in inline YAML
  - **Impact**: YAML configs like `files: ["lib/**/*.rb"]` were incorrectly detected as preset "---"
  - **Fixes**: "No code to review" error in ace-review when using file/diff configs
- **Glob pattern support in `files:` configuration**
  - Added automatic detection of glob characters (`*`, `?`, `[`) in file patterns
  - Routes glob patterns to `aggregate()` and literal paths to `aggregate_files()`
  - Added `exclude:` parameter support in file aggregation
  - **Impact**: Patterns like `lib/**/*.rb` now correctly expand to matching files

## [0.11.0] - 2025-10-06

### Added
- **Protocol resolution support** via ace-nav integration
  - Load resources using protocols: `ace-context wfi://workflow-name`
  - Supported protocols: `wfi://` (workflows), `guide://`, `task://`, and any ace-nav protocol
  - Works in input arguments and `context.files` arrays
- **YAML frontmatter template support**
  - Detect and process files with YAML frontmatter (starts with `---`)
  - Support `context:` key in frontmatter for configuration
  - Merge `params:` from frontmatter into processing options
- **Workflow embedding via protocols**
  - Reference workflows in `context.files: [wfi://draft-task, wfi://plan-task]`
  - Automatic recursive protocol resolution
  - Zero duplication - workflows reference each other declaratively

### Changed
- `load_auto()` now detects `://` pattern and delegates to protocol resolution
- `load_file()` treats files with YAML frontmatter as templates
- `load_template()` processes frontmatter config directly when `context:` key present
- CLI updated to use `load_auto()` instead of `load_preset()` for flexible input handling

### Technical Details
- `resolve_protocol()` delegates to `ace-nav` for path resolution
- `resolve_file_reference()` handles protocols in file arrays
- Protocol resolution integrated in both preset and template config processing
- Maintains backward compatibility with existing file paths, presets, and inline YAML

## [0.10.0] - 2025-10-06

### Added
- Git diff support via `diffs:` configuration key
- `Ace::Context::Atoms::GitExtractor` for secure git operations
- Support for combining files, commands, diffs, and presets in unified configuration
- Git diff formatting in all output modes (markdown, xml, markdown-xml, json, yaml)
- Comprehensive test suite for git operations (10 tests)

### Changed
- ace-core `OutputFormatter` now handles diffs section in all formats
- README updated with Content Sources section documenting all supported types

## [0.9.0] - 2025-10-05

Initial release with preset management, file aggregation, and command execution support.
