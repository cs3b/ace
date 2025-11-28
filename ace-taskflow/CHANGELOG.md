# Changelog

All notable changes to ace-taskflow will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.20.0] - 2025-11-27

### Added

- **Subtask Workflow Support**: Comprehensive hierarchical task execution workflow for task 122
  - Added CLI support for subtasks with `--child-of` flag for creating hierarchical task relationships
  - Added task scanner support for orchestrator + subtask patterns to identify parent-child relationships
  - Added orchestration workflow for subtask execution with automated cascade handling
  - Honor `--release/--backlog` with `--child-of` for proper task placement in context hierarchy
  - Fixed display formatting and lifecycle management for hierarchical tasks
  - Made terminal statuses configurable through project configuration
  - Addressed code review feedback across multiple subtasks (122.03, 122.04, 122.05, 122.07, 122.08)
  - Updated task_manager test fixture to use configured task_dir for proper test isolation

### Fixed

- **Task Manager Test Configuration**: Fixed test fixture to use configured task_dir instead of hardcoded paths
  - Ensures proper test isolation and respects project configuration settings
  - Prevents test pollution across different task directory configurations

### Technical

- Clarified dynamic PR base branch documentation in work-on-subtasks workflow

## [0.19.3] - 2025-11-17

### Changed

- **Task Reference Format Standardization**: Introduced 'task.' prefix for qualified references
  - Updated qualified references from `v.0.9.0+018` to `v.0.9.0+task.018`
  - Modified `PathBuilder` to include 'task.' prefix when constructing qualified references
  - Updated `TaskReferenceParser` to parse both old and new formats for backward compatibility
  - Adjusted `Task` model to use new format for qualified task identifiers
  - Updated `TestFactory` to generate test data with standardized format
  - Ensures consistent and unambiguous format for task references across the system

## [0.19.2] - 2025-11-16

### Fixed

- **Task Counting Bug**: Fixed statistics counting where pending tasks showed incorrect count (3 instead of 12)
  - Updated `get_statistics` glob pattern to match both old format (`task.NNN.s.md`) and new hierarchical format (`NNN-slug.s.md`)
  - Standardized all task IDs to canonical format (`v.0.9.0+task.NNN`) for consistent task reference resolution
  - Updated test expectations to match canonical format
  - Ensures accurate task statistics across all task naming formats

### Technical

- Updated capture-idea workflow documentation with current API and examples
- Applied code review feedback improvements for better maintainability
- Improved idea create output to show full file path instead of folder path

## [0.19.1] - 2025-11-15

### Changed

- **Task 111 Completion**: Marked task 111 (Fix ace-review cache path resolution in git worktrees) as done
  - Moved task file from `tasks/` to `tasks/done/` folder
  - All success criteria met and verified
  - Core fix implemented and tested

## [0.19.0] - 2025-11-15

### Added

- **Idea Folder Structure Validation and Enforcement**: Comprehensive validation system for idea file organization
  - New `validate-structure` command checks idea file organization with detailed error reporting
  - Enforces ideas must be in subfolders within ideas/ directory (e.g., `ideas/folder-name/file.md`)
  - Provides clear error messages with suggested proper locations for misplaced files
  - Warning shown in `ideas` list command when misplaced ideas are detected
  - Environment variable `SKIP_IDEA_VALIDATION` available for performance optimization in large repositories
  - Comprehensive YARD documentation with exit codes (0=success, 1=failures) for CI/CD integration
  - 26 comprehensive tests covering all validation scenarios including edge cases
  - Command integrated into help text for easy discoverability

### Changed

- **Idea Create Output Enhancement**: Improved `ace-taskflow idea create` output to display full file path instead of just folder path
  - Modified `IdeaWriter#write` to return complete path to created `.s.md` file
  - Updated output message to show exact file created (e.g., `.ace-taskflow/v.0.9.0/ideas/20251115-085126-test/test.s.md`)
  - Makes it immediately clear which file was created and easier to open in editors
  - Added YARD documentation for `IdeaWriter#write` method with parameter and return value specifications
  - Added regression test to ensure file path (not directory) is returned
- **Code Quality Improvements**: Refactored path formatting for better maintainability
  - Removed duplicate `format_path_relative_to_pwd` method from `IdeaCommand`
  - Now uses `Atoms::PathFormatter.format_relative_path` for DRY principle
  - Eliminates code duplication across command classes

## [0.18.4] - 2025-11-04

### Fixed

- **Task Update Command Restoration**: Restored the complete `ace-taskflow task update` command implementation that was accidentally deleted in commit 54cac8b3
  - Restored `TaskFieldUpdater` molecule for field parsing and validation
  - Restored `FieldArgumentParser` molecule for CLI argument parsing
  - Restored `update_task` method in `task_command.rb` with full help text and examples
  - Restored `update_task_fields` in `task_manager.rb` for task orchestration
  - Restored `update_task_field` in `task_loader.rb` using ace-support-markdown integration
  - Restored comprehensive unit tests (10 tests, 19 assertions)
  - Command supports `--field key=value` syntax for simple and nested YAML updates
  - Enables worktree metadata updates for ace-git-worktree integration (task 089)
  - Updated task 089 with verified working examples and implementation notes

## [0.18.3] - 2025-11-04

### Fixed

- **Task Header Statistics**: Fixed missing three-line header with release statistics in `ace-taskflow tasks` output
  - Fixed `StatsFormatter#initialize` (line 36) to pass `@root_path` to `ReleaseResolver.new`
  - Fixed `TasksCommand#initialize` to initialize `@root_path` and pass it to `StatsFormatter.new`
  - Header now correctly displays release info, idea stats, and task counts instead of minimal "X tasks" output
  - Pre-existing bug (not introduced by unified filter PR) that manifested when running from subdirectories

## [0.18.2] - 2025-11-04

### Fixed

- **Releases Preset Type Dispatch**: Fixed `releases_command.rb` to correctly pass `:releases` type parameter to `ListPresetManager.apply_preset` method (3 occurrences at lines 64, 70, 251)
  - Without this fix, release-specific presets (e.g., `type: "releases"`) would fail to load, falling back to `:tasks` namespace and returning "preset not found" error
  - Affected commands: `ace-taskflow releases <preset>`, `ace-taskflow releases --stats`
  - Identified by GPT-5 code review (review-20251104-005003)

## [0.18.1] - 2025-11-04

### Fixed

- **Return Value Consistency**: Fixed `releases_command.rb` to return error code `1` instead of `nil` when preset configuration fails
- **Error Message Whitespace Handling**: Fixed legacy flag error messages to properly handle spaces after commas (e.g., `--status pending, done` now correctly suggests `--filter status:pending|done` instead of `--filter status:pending| done`)
  - Updated error message conversion in `tasks_command.rb` for `--status` and `--priority` flags
  - Updated error message conversion in `ideas_command.rb` for `--status` and `--priority` flags

## [0.18.0] - 2025-11-04

### Added

- **Unified Filter System**: New `--filter key:value` syntax replaces legacy filtering flags across tasks, ideas, and releases commands
- **FilterParser Atom**: Parses filter syntax with support for OR values (`key:value1|value2`), negation (`key:!value`), and array matching
- **FilterApplier Molecule**: Applies filter specifications with AND logic across filters and OR logic within filters
- **Filter-Clear Flag**: `--filter-clear` option to override preset filters while keeping release/scope/sort configuration
- **Universal Field Filtering**: Filter by any frontmatter field including custom fields (e.g., `--filter team:backend`, `--filter sprint:12`)
- **Comprehensive Test Coverage**: 52 new tests (23 for FilterParser, 29 for FilterApplier) with 100% pass rate

### Changed

- **BREAKING**: Removed `--status` flag from tasks/ideas commands - use `--filter status:value` instead
- **BREAKING**: Removed `--priority` flag from tasks/ideas commands - use `--filter priority:value` instead
- **BREAKING**: Removed `--active` flag from releases command - use `--filter status:active` instead
- **BREAKING**: Removed `--done` flag from releases command - use `--filter status:done` instead
- **BREAKING**: Removed `--backlog` flag from releases command - use `--filter status:backlog` instead
- Updated all command help text with new filter syntax, operators, and examples
- Enhanced TaskFilter molecule to integrate with FilterApplier for universal filtering

### Technical

- Helpful error messages show exact migration syntax when legacy flags are used
- Clean break approach for backward compatibility (no deprecation period)
- Comprehensive usage guide with 30+ examples in `ux/usage.md`
- Fixed test suite to use new filter syntax

## [0.17.0] - 2025-11-02

### Added

- **Flexible Task Transitions**: Tasks can now transition from any status directly to "done" without requiring intermediate steps (default behavior)
- **Custom Status Support**: Support for custom statuses like "ready-for-review" that aren't in the predefined status list
- **Idempotent Operations**: Running `task done` or status updates multiple times succeeds gracefully with informative messages instead of errors
- **Configuration Support**: New `strict_transitions` config option to enable rigid status validation (opt-in for legacy behavior)
- **Enhanced User Feedback**: Context-aware messages distinguish between new transitions, no-op operations, and already-satisfied states

### Fixed

- **Critical Bug - Frontmatter Corruption**: Replaced dangerous regex-based frontmatter editing with safe `DocumentEditor` from ace-support-markdown, preventing task files from being corrupted to 3 lines
- **Task Directory Mover Idempotency**: Moving tasks to done/ directory now succeeds when task is already in done/ instead of failing

### Changed

- **Default Behavior**: Flexible transitions are now the default (can transition from any status to any other status)
- **Status Validator**: Updated to support both flexible and strict modes with idempotency checks
- **Task Manager**: Enhanced to read configuration and provide better error messages

### Technical

- Added comprehensive test coverage: 12 new tests for flexible validation, 10 new tests for idempotent operations, 5 new safety tests for frontmatter preservation
- Updated existing tests to explicitly use strict mode where appropriate for backward compatibility

## [0.16.1] - 2025-11-02

### Added

- Enhance array parsing to handle quoted items with commas in CLI arguments

### Fixed

- Prevent accumulating newlines in task update command
- Address code review feedback for task update command

### Changed

- Complete ace-support-markdown integration for document manipulation
- Extract CLI parsing logic to FieldArgumentParser molecule
- Address code review feedback for task update command

## [0.16.0] - 2025-11-02

### Added

- **Task Update Command**: Implemented `ace-taskflow task update` command for updating task metadata fields
  - Support for updating any frontmatter field via `--field key=value` syntax
  - Dot notation support for nested YAML structures (e.g., `worktree.branch=value`)
  - Multiple `--field` flags for batch updates in a single command
  - Smart type inference for integers, floats, booleans, arrays, and strings
  - Atomic file writes with automatic timestamped backups
  - Comprehensive error handling with specific exit codes (0=success, 1=not found, 2=invalid syntax, 3=write error)
  - 34 comprehensive test cases covering all functionality
  - Primary use case: Enable ace-git-worktree to add worktree metadata to tasks

### Fixed

- Address code review feedback on documentation and hygiene
- Handle directory-based ideas in glob matching for idea_loader
- Correct Symbol loading and update task metadata
- Rename 'context' to 'release' across the codebase for consistency
- Remove hardcoded directory names from glob patterns
- Update file extension from .md to .s.md for task files
- Update TaskReferenceParser to return :release key
- Improve glob filtering and handle empty results

### Changed

- Refactor: Extract filter_glob_by_type to shared helper for better code organization
- Refactor: Rename 'context' to 'release' across the project for clarity
- Refactor: Rename context to release for IdeaLoader
- Refactor: Extract glob filtering logic to helper method
- Refactor: Refactor preset and configuration architecture

### Technical

- Update tests to use release parameter
- Rename infrastructure gems (ace-core → ace-support-core, ace-test-support → ace-support-test-helpers)
- Bump versions for dependency updates (0.15.0, 0.15.1)

## [0.15.2] - 2025-11-01

### Changed

- **Dependency Migration**: Updated to use renamed infrastructure gems
  - Changed dependency from `ace-core` to `ace-support-core`
  - Part of ecosystem-wide naming convention alignment for infrastructure gems

## [0.15.1] - 2025-11-01

### Fixed

- **YAML Parser**: Added `Symbol` to permitted classes in `YamlParser.parse_frontmatter` to fix "Tried to load unspecified class: Symbol" error when running `ace-taskflow doctor` on files with Symbol-style YAML keys (`:key_name` format)
- **Task Metadata**: Fixed incomplete frontmatter in tasks 074 and 075 (missing closing `---` delimiter, priority, estimate, and dependencies fields)
- **Task Dependencies**: Removed invalid dependency references to non-existent `task.079` in tasks 081 and 082

### Changed

- Tasks 074 and 075 now include minimal task descriptions for better documentation

## [0.15.0] - 2025-11-01

### 🚨 Breaking Changes

#### API Renaming: Context → Release

Complete terminology change across the entire codebase for improved clarity. The term "release" better reflects the purpose of identifying which version/scope an item belongs to.

**Affected Components:**

- **Models**: `Task#context` → `Task#release`, `Idea#context` → `Idea#release`
- **Commands**: All CLI commands now use `--release` instead of `--context`
- **Configuration**: Preset YAML files now use `release:` key instead of `context:`
- **API Methods**: All method parameters renamed from `context` to `release`
- **Internal Components**: TaskReferenceParser, validators, formatters, loaders

**Migration Guide:**

For Ruby API usage:

```ruby
# Before
loader.load_all(context: "current")
task = Task.new(context: "v.1.0.0")

# After
loader.load_all(release: "current")
task = Task.new(release: "v.1.0.0")
```

For YAML preset files:

```yaml
# Before
context: current

# After
release: current
```

For CLI commands:

```bash
# Before
ace-taskflow tasks --context v.0.9.0

# After
ace-taskflow tasks --release v.0.9.0
```

**Impact**: 53+ files changed across models, commands, molecules, organisms, and tests. All existing code and configurations using `context` must be updated to use `release`.

### Changed

- **Architecture Improvements**:
  - Refactored preset and configuration architecture for better maintainability
  - Enhanced ListPresetManager with improved glob handling and error messages
  - Extracted `filter_glob_by_type` to shared `commands/helpers.rb` module
  - Reduced code duplication across IdeasCommand and TasksCommand
  - Improved PathBuilder and loader architecture

### Fixed

- **Glob Pattern Handling**: Removed hardcoded directory names from glob patterns
  - Added `Configuration#default_glob_pattern` method (returns `['**/*.s.md']`)
  - Single source of truth for default glob patterns
  - Patterns now automatically prefixed with correct directory (ideas/ or tasks/)

- **Empty Results Handling**: Improved glob filtering and error handling for empty result sets

- **File Extension References**: Fixed remaining `.md` references that should be `.s.md` in:
  - ReleaseResolver
  - StructureValidator
  - TaskManager

- **TaskReferenceParser**: Updated to return `:release` key instead of `:context` for consistency

### Technical

- Updated all 734 tests to use `release` parameter naming
- Comprehensive refactoring across 36+ files in final context→release migration
- All tests passing with new terminology

## [0.14.2] - 2025-11-01

### Added

- Use .s.md extension and clarify GTD scope

## [0.14.1] - 2025-11-01

### Added

- Implement .s.md extension and remove backward compatibility
- Implement glob-based preset system for ideas and tasks

### Fixed

- Adjust universal presets and statistics logic
- Require configuration and update universal preset expectations
- Fix glob patterns to be relative to ideas directory
- Address PR review feedback and fix failing tests

### Changed

- Clarify comments and refine exception handling
- Make presets universal and parse status/priority

## [0.14.0] - 2025-10-26

### 🚨 Breaking Changes

#### File Extension Migration

- **All spec files now use `.s.md` extension** (specification markdown)
  - Ideas: `*.md` → `*.s.md` (212 files migrated)
  - Tasks: `task.*.md` → `task.*.s.md` (623 files migrated)
  - Clear separation: `.s.md` = specifications, `.md` = documentation only

#### API Changes

- **`IdeaLoader#load_all` signature changed**:
  - **Removed**: `scope` parameter
  - **Added**: `glob` parameter (optional, defaults to `["**/*.s.md"]`)
  - Example: `loader.load_all(context: "current", glob: ["maybe/**/*.s.md"])`
- **Removed backward compatibility**: `PRESET_TO_SCOPE` constant deleted from IdeasCommand

#### Configuration Changes

- Simplified config: `ideas: "ideas"` (folder name only, not path)
- Removed path-splitting logic duplication from configuration

### Migration Guide

For custom scripts using the API:

```ruby
# Before
loader.load_all(context: "current", scope: :maybe)

# After
loader.load_all(context: "current", glob: ["maybe/**/*.s.md"])
```

For file references in custom scripts:

```bash
# Update any hardcoded .md extensions to .s.md
# Ideas: 20251026-123456-title.md → 20251026-123456-title.s.md
# Tasks: task.088.md → task.088.s.md
```

**Note**: All existing files have been automatically migrated. This only affects new integrations.

### Added

- **Glob-Based Preset System**: Eliminated configuration duplication with self-defining presets
  - Presets now declare content via glob patterns that work universally across contexts
  - Simplified patterns: `maybe/**/*.s.md` vs previous complex type-specific patterns
  - Glob validation: Rejects dangerous characters and absolute paths
  - Universal patterns work across backlog and all releases
- **Maybe and Anyday Idea Scopes**: Support for organizing ideas by priority and timeline
  - New subdirectories: `ideas/maybe/` for uncertain ideas, `ideas/anyday/` for low-priority ideas
  - Preset support: `ace-taskflow ideas maybe` and `ace-taskflow ideas anyday`
  - Creation flags: `--maybe` and `--anyday` for `ace-taskflow idea create`
  - Statistics display with emoji indicators: 💡 (pending), 🤔 (maybe), 📅 (anyday), ✅ (done)

### Changed

- **Architecture Improvements**:
  - Added `determine_context_root()` to IdeaLoader - returns release/backlog root path
  - Refactored `determine_idea_directory()` to use context_root + folder name
  - Simplified `IdeaLoader#load_all` to only use glob-based loading
  - Added glob support to TaskLoader with `load_tasks_with_glob()`
  - Configuration simplified: folder names instead of paths
- **Code Quality Improvements**: Refactored implementation based on code review recommendations
  - Extract SCOPE_SUBDIRECTORIES constant to centralize scope definitions
  - Improve status determination using dirname inspection
  - Reduce code duplication in IdeaLoader with loop-based scope loading
  - Add validate_subdirectory_exclusivity helper for mutual exclusivity checks

### Technical

- Updated all 835 spec files to use `.s.md` extension
- Updated test fixtures and assertions for new extension
- Add glob pattern validation in ListPresetManager
- Clean up test artifacts and finalize task 088
- Fix missing final newlines in IdeaWriter templates for POSIX compliance
- Add comprehensive test coverage for --maybe/--anyday flag mutual exclusivity
- All 734 tests passing

## [0.13.2] - 2025-10-25

### Fixed

- **Task Sorting**: Correct task sorting logic for string/symbol keys in preset configurations
  - Tasks were displayed in reverse order when using `ace-taskflow tasks next` command
  - Fixed apply_preset_sorting to handle both string and symbol keys from YAML configs
  - Added comprehensive tests for ascending and descending sort orders

## [0.13.1] - 2025-10-24

### Fixed

- **Task File Corruption Prevention**: Fixed incomplete ace-support-markdown integration in task_loader.rb
  - `update_task_status` and `update_task_dependencies` now use SafeFileWriter for atomic writes with backups
  - Previously these methods used raw `File.write`, which could corrupt task files if interrupted
  - All file write operations in ace-taskflow now use SafeFileWriter for data protection
  - Backup files (*.backup.*) are created automatically before modifications

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
