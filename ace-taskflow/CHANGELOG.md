# Changelog

All notable changes to ace-taskflow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.13.0] - 2025-10-23

### Added
- **task:// Protocol Configuration**: Added `.ace.example/nav/protocols/task.yml` for ace-nav integration
  - Enables `ace-nav task://083` to delegate to `ace-taskflow task 083`
  - Provides unified navigation interface across all ACE resources
  - Configuration supports all task reference formats and options (--path, --content, --tree)

## [0.12.1] - 2025-10-23

### Added

- Standardize idea file organization by using ace-taskflow idea done command in draft workflows

## [0.12.0] - 2025-10-23

### Changed

- Use ace-support-markdown for safe file operations, eliminating file corruption risk

## [0.11.5] - 2025-10-14

### Added

- Improve task reference parsing and loading with ID-based search
- Support v.0.9.0+task.070 reference format

### Fixed

- Fix task lookup for done tasks by searching on ID field instead of path-based extraction
- Enable simple references (072, task.072) to find tasks in done directory

### Technical

- Update work-on-task instructions for task selection

## [0.11.4] - 2025-10-14

### Added

- Standardize Rakefile test commands and add CI fallback
- Improve usability and add markdown style checks
- Add support for pending release directory

### Fixed

- Fix 17 atom test failures with architecture-compliant patterns
- Load configuration.rb to resolve NoMethodError
- Make directory names configurable in validators

### Changed

- Consolidate retro directory and update workflows
- Standardize directory names for retros and tasks
- Update task directory configuration
- Extract context resolution and task loading logic
- Use configuration for task directory paths
- Respect configured directory names for component type detection

### Technical

- Update usage.md with resolved configuration decisions

## [0.11.3] - 2025-10-14

### Fixed

- **Work-on-Task Workflow**: Simplified task selection and eliminated unnecessary complexity
  - Removed manual directory scanning and release path lookups
  - Updated workflow to use `ace-taskflow task <ref>` for all task lookups
  - Command now handles all reference formats: `071`, `task.071`, `v.0.9.0+071`
  - Removed unnecessary task listing commands from dependency checking
  - Clearer usage examples showing all supported reference formats
  - Agents no longer struggle to find tasks - single command handles everything

## [0.11.2] - 2025-10-08

### Fixed

- **Idea Create Error Handling**: Improved error handling for `--current` flag when no active release exists
  - When `--current` flag is explicitly provided but no active release is found, displays clear error message
  - Error message suggests creating a release with `ace-taskflow release create` or omitting `--current` to save to backlog
  - Prevents silent fallback to backlog when user explicitly requests current release
  - Note: The `--current` flag path resolution was already working correctly (fixed in v0.9.0)

## [0.11.1] - 2025-10-08

### Fixed

- **Exit Code Handling**: Fixed TypeError when executing tasks and ideas commands
  - `TasksCommand` display methods now return proper Integer exit codes (0 for success, 1 for errors)
  - Fixed `display_tasks_with_preset`, `display_tree_with_preset`, `display_paths_with_preset`, `display_list_with_preset`
  - Fixed `show_statistics_for_preset` to return exit codes
  - Fixed `execute_with_preset` to propagate exit codes from display methods
  - `IdeasCommand` display methods now return proper Integer exit codes
  - Fixed `display_ideas_with_preset`, `display_ideas_as_json`, `show_statistics_for_preset`
  - Resolves `TypeError: no implicit conversion of Array into Integer` when calling `exit(exit_code)`

## [0.10.2] - 2025-10-08

### Fixed

- **Test Isolation**: Fixed tests leaking artifacts to main project directory
  - `IdeaCommand` now initialized inside `with_test_project` blocks to respect stubbed project root
  - Prevents idea files from being created in `.ace-taskflow/v.0.9.0/ideas/` during test runs
  - Fixed in `test_create_idea_with_git_commit` and `test_idea_with_llm_enhancement`

- **Clipboard Tests**: Fixed 9 failing clipboard reader tests on macOS
  - Stubbed `ClipboardReader.macos_clipboard_available?` to return false in tests
  - Forces tests to use fallback `Clipboard` gem path they're designed to test
  - Previously failed because macOS code path uses `Ace::Support::MacClipboard` instead

- **Test Expectations**: Updated test assertions to match actual behavior
  - Fixed retro command tests to expect title format (e.g., "Test retro 1") not slug format
  - Fixed git commit test to use correct flag `--git-commit` instead of `--git`
  - Updated assertion to expect committed file (clean status) not staged

- **Warning Suppression**: Fixed Ruby 3.4 compatibility issue
  - Replaced non-existent `Warning.silence` with `$VERBOSE = nil` pattern
  - Applied to clipboard test constant redefinitions

### Technical

- All 700 tests now pass (0 failures, 0 errors, 83 skips)
- Test isolation properly prevents pollution of main project directory
- Clipboard tests work on all platforms through proper stubbing

## [0.10.1] - 2025-10-08

### Fixed

- **Test Execution**: Fixed critical issue where tests would halt mid-execution and not report results
  - Commands now return status codes instead of calling `exit` directly
  - `RetrosCommand` and `RetroCommand` refactored to return 0 (success) or 1 (failure)
  - `IdeaWriter` organism now raises `IdeaWriterError` exceptions instead of calling exit
  - CLI entry point (`exe/ace-taskflow`) handles exit at top level only
  - Tests now complete properly and report full results (700 tests vs 0 previously)
  - Fixes issue where `ace-test` would report "0 tests, 0 assertions, 0 failures"

### Changed

- Command execution pattern: All commands should return status codes for testability
- Organism error handling: Organisms raise exceptions that commands handle and convert to status codes
- Test expectations: Updated tests to assert on return values and exceptions instead of `SystemExit`

### Technical

- Refactored `RetrosCommand#execute` to return status codes
- Refactored `RetroCommand#execute` and all private methods to return status codes
- Added `IdeaWriterError` exception class for organism-level errors
- Updated `CLI.start` to return status codes instead of exiting
- Updated test assertions for new status code pattern
- Documented exit call anti-pattern in `docs/testing-patterns.md`

## [0.10.0] - 2025-10-07

### Added

- **Rich Clipboard Support (macOS)**: Idea creation now supports rich clipboard content
  - Automatically detects and saves images (PNG, JPEG, TIFF)
  - Copies files from Finder with original filenames
  - Preserves HTML and RTF formatted content
  - Platform detection with graceful fallback to text-only on non-macOS
  - New `ace-support-mac-clipboard` gem with NSPasteboard FFI integration

- **Enhanced Ideas List Display**: Multiple display formats for different use cases
  - Default format shows file paths (LLM-optimized for direct file access)
  - `--short` flag hides paths and shows IDs (human-friendly)
  - `--format json` provides structured output with metadata
  - Rich ideas marked with 📎 icon and attachment count
  - Paths for rich ideas point to `idea.md` file inside directory

- **Directory-based Ideas**: Ideas with attachments stored as directories
  - Simple ideas: Single `.md` file (e.g., `20251007-125830-title.md`)
  - Rich ideas: Directory with `idea.md` + attachments (e.g., `20251007-125830-title/`)

### Changed

- Ideas list default format now optimized for LLM access (shows paths)
- ID display now conditional: hidden when paths shown, visible with `--short`
- Updated help text to document new display formats and options

### Technical

- Added `ace-support-mac-clipboard` package with FFI bridge to AppKit/NSPasteboard
- Implemented ContentType, Reader, and ContentParser for clipboard data
- Enhanced IdeaLoader to handle both flat file and directory-based ideas
- Updated AttachmentManager with `save_attachments` method
- IdeaWriter now supports clipboard merge and attachment handling

## [0.9.0] - 2025-09-24

### Initial Features

- Task and idea management with timestamped organization
- Descriptive task paths with semantic directory names
- Retrospective management
- Configuration cascade system
- ATOM architecture pattern
