# Changelog

All notable changes to ace-taskflow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
