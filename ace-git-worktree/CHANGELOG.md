# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.1] - 2025-11-28

### Fixed
- **TaskPusher Loading**: Add missing require statement for TaskPusher module
  - Fixes "uninitialized constant Ace::Git::Worktree::Molecules::TaskPusher" error
  - Restores functionality of `ace-git-worktree remove --task` command

## [0.4.0] - 2025-11-28

### Added
- **TaskIDExtractor Atom**: Shared helper for consistent task ID extraction across all components
  - Properly handles hierarchical subtask IDs (e.g., `121.01`)
  - Provides `extract()` for task data hashes and `normalize()` for reference strings
  - Uses ace-taskflow's `TaskReferenceParser` when available, with regex fallback
- **PR and Branch Worktree Creation**: Create worktrees from GitHub pull requests or branches
  - `--pr <number>` flag fetches PR metadata and creates worktree
  - `-b <branch>` flag for local and remote branches

### Changed
- **TaskFetcher**: Now uses `TaskManager` (organism-level API) instead of `TaskLoader` (molecule)
  - Let ace-taskflow handle all path resolution internally
  - Simplified initialization (no root_path needed)
  - Uses `TaskIDExtractor` in `parse_cli_output` for deriving task numbers
- **Unified Task ID Extraction**: All components now use `TaskIDExtractor` for consistent subtask support
  - `worktree_info.rb`: Uses `TaskIDExtractor.normalize()` for path/branch extraction
  - `worktree_manager.rb`: Uses `TaskIDExtractor.normalize()` in `find_worktree_by_identifier`
  - `task_worktree_orchestrator.rb`: Uses `TaskIDExtractor` for task ref normalization
  - `task_status_updater.rb`: Uses `TaskIDExtractor.normalize()`
  - `worktree_creator.rb`: Uses `TaskIDExtractor.extract()`
  - `worktree_config.rb`: Uses `TaskIDExtractor.extract()`
  - `remove_command.rb`: Uses `TaskIDExtractor` for task matching

### Fixed
- **Subtask ID Handling**: Fixed critical bug where subtask IDs (e.g., `121.01`) were stripped to parent ID (`121`)
  - Worktree operations now correctly distinguish between parent tasks and subtasks
  - Prevents accidental operations on wrong tasks (e.g., deleting `task.121` instead of `task.121.01`)
- **Worktree Lookup by Subtask**: Fixed `remove --task 121.01` not finding worktrees
  - `find_worktree_by_identifier` now correctly matches subtask worktrees
  - `WorktreeInfo.extract_task_id` preserves subtask suffix in parsed output
- All failing tests from PR/branch worktree integration

### Technical
- Mocked sleep in `pr_fetcher` tests for 65% speedup
- Configured push for mismatched branch names

## [0.3.0] - 2025-11-13

### Added
- **PR-based Worktree Creation**: `--pr <number>` flag to create worktrees from GitHub pull requests
  - Automatically fetches PR metadata using GitHub CLI (`gh`)
  - Creates worktree with remote tracking
  - Detects and warns about fork PRs
  - Configurable directory and branch naming via `.ace/git/worktree.yml`
- **Branch-based Worktree Creation**: `-b <branch>` flag for local and remote branches
  - Auto-detects remote vs. local branches
  - Automatically fetches remote branches before creation
  - Sets up tracking for remote branches
  - Preserves full branch path to avoid naming collisions
- **PrFetcher Molecule**: GitHub CLI integration with comprehensive error handling
  - Custom exception classes for clear error types
  - Timeout support (30s default)
  - Input validation and security checks
  - Fork PR detection
- **Retry Logic**: Automatic retry with exponential backoff for transient network failures
  - Up to 2 retries by default (configurable)
  - Smart retry only for NetworkError, not permanent errors
- **Performance**: Cached gh CLI availability check to avoid repeated system calls

### Changed
- Extended `WorktreeCreator` with `create_for_pr()` and `create_for_branch()` methods
- Extended `WorktreeConfig` model with `pr` and `branch` configuration namespaces
- Extended `WorktreeManager` with `create_pr()` and `create_branch()` orchestration
- Improved branch naming to use full path and avoid collisions (e.g., `feature/auth/v1` → `feature-auth-v1`)
- Enhanced CLI help text with PR and branch usage examples

### Fixed
- Branch name collision issue when multiple remote branches share the same last segment
  - Changed from `branch.split("/").last` to full branch path preservation
  - Example: Both `origin/feature/auth/v1` and `origin/login/auth/v1` now create unique worktrees

### Documentation
- Added "PR and Branch-Based Workflows" section to README
- Comprehensive usage examples for `--pr` and `-b` options
- Configuration examples with template variables
- Requirements and troubleshooting guidance

### Testing
- Added 12 new unit tests for WorktreeCreator PR/branch methods
- Added 14 unit tests for PrFetcher molecule
- Test coverage for happy paths, error scenarios, and edge cases

### Technical
- Follows ATOM architecture pattern (Atoms → Molecules → Organisms)
- GitHub CLI (`gh`) is required for PR functionality
- Supports template variables: `{number}`, `{slug}`, `{base_branch}` for PR naming

## [0.2.2] - 2025-11-12

### Changed
- Simplified test suite architecture from complex mocks to focused smoke tests (843 line reduction)
- Converted organism/molecule tests to verify public API contracts instead of internal implementation
- Updated command tests to match actual method signatures and result formats

### Added
- Missing `--no-mise-trust` flag support in create command
- Missing `--force` flag support in prune command
- Security validation for dangerous patterns in paths and search queries
- Help display when create command invoked without arguments

### Fixed
- Config command now accepts subcommand arguments (show/validate) as aliases for flags
- Test helper to require ace/git_diff for CommandExecutor mocking
- Mock expectations in command tests to match actual API signatures
- Integration test skips with clear explanatory messages

### Technical
- Added ace/git_diff dependency to test_helper for proper mocking
- Improved test maintainability by focusing on behavior over implementation
- Enhanced security validation across user input points

## [0.2.1] - 2025-11-11

### Fixed
- Execute after-create hooks for classic branches (previously only worked for task-based branches)
- Proper hook configuration structure in tests for reliable test execution

### Changed
- Made `WorktreeRemover#delete_branch_if_safe` public for better API encapsulation
- Improved error messages for orphaned branch deletion to include detailed reasons
- Enhanced documentation with hooks configuration examples and orphaned branch cleanup guide

### Technical
- Addressed code review feedback improving encapsulation and test coverage
- Added test for hook failure handling as non-blocking warnings
- Fixed tests to use correct `@hooks_config` structure instead of direct instance variable

## [0.2.0] - 2025-11-11

### Added
- **Configurable Worktree Root Path**: `root_path` configuration now supports paths outside the project directory
  - Relative paths are resolved relative to project root (not current directory)
  - Allows worktrees in parent directory (`../`), home directory (`~/worktrees`), or custom locations
  - Benefits: keeps project clean, avoids IDE file watcher overhead, prevents nested git issues
- **Branch Deletion on Worktree Removal**: New `--delete-branch` flag for remove command
  - Safely deletes branches when removing worktrees
  - Without `--force`: only deletes merged branches (safe mode)
  - With `--force`: can delete unmerged branches (use with caution)
  - Clear user feedback when branch is kept vs. deleted

### Changed
- **Path Expansion**: `PathExpander.expand()` now accepts optional `base` parameter for context-aware expansion
- **Path Validation**: Relaxed to allow worktrees in subdirectories or outside git root (only prevents creation AT git root)
- **WorktreeCreator**: Now accepts configuration object to respect `root_path` setting for traditional worktrees
- **WorktreeRemover**: Enhanced with `delete_branch_if_safe()` method that checks merge status before deletion

### Fixed
- **Configuration Respect**: Fixed bug where `root_path` configuration was ignored for traditional worktrees
- **Branch Orphaning**: Fixed issue where removing worktrees left orphaned branches causing "branch already exists" errors

## [0.1.11] - 2025-11-05

### Fixed
- **Ruby API Integration**: Replace CLI dependency with direct ace-taskflow Ruby API calls
- **TaskFetcher**: Update availability check to prioritize Ruby API over CLI subprocess calls
- **TaskStatusUpdater**: Add Ruby API integration via TaskManager with CLI fallback
- **Mono-repo Optimization**: Improve performance by using in-process Ruby API instead of subprocess calls
- **Error Messages**: Better distinction between mono-repo and standalone installation environments
- **Configuration**: Update default worktree path for Git compatibility

### Changed
- **Architecture**: Both TaskFetcher and TaskStatusUpdater now use Ruby API as primary method
- **Fallback Strategy**: Graceful degradation to CLI when Ruby API unavailable
- **Debug Output**: Enhanced debugging capabilities for troubleshooting integration issues
- **Performance**: Eliminate subprocess overhead when Ruby API available

## [0.1.10] - 2025-11-05

### Fixed
- **Completed Task Cleanup Messaging**: Replace confusing "Task metadata cleanup would require task access - skipped for completed task" message with clear status-based messaging
- **Task Status Detection**: Fix status parsing to handle stripped format (" done" instead of "done") from CLI output
- **User Experience**: Provide clear feedback when removing worktrees for completed tasks, which is the normal workflow

### Added
- **Clear Completion Messages**: Show "Task completed: no metadata cleanup needed" for done/completed tasks
- **Status-based Messaging**: Different messages for different task statuses to avoid confusion

### Changed
- **Remove Command Logic**: Updated messaging to be informative rather than suggesting errors for normal completed task workflows
- **User Communication**: Focus on clarity and explaining normal workflow expectations

## [0.1.9] - 2025-11-05

### Fixed
- **CLI Format Parsing**: Major rewrite of TaskMetadata parser to handle ace-taskflow CLI human-readable format instead of expected YAML frontmatter
- **Method Resolution Failures**: Implement inline parsing logic as workaround for Ruby class method loading issues
- **Task ID Extraction**: Fix parsing of task IDs from "v.0.9.0+task.089" format in CLI output
- **Timeout Parameter Error**: Fix Open3.capture3 timeout parameter syntax causing command execution failures
- **TaskMetadata Branch Accessor**: Add missing branch method for completed tasks returning nil

### Added
- **Inline CLI Parser**: Complete implementation for parsing ace-taskflow CLI key-value format
- **Comprehensive Debug Output**: Added DEBUG environment variable support for troubleshooting integration issues
- **Fallback Logic**: Enhanced error handling when ace-taskflow direct API integration fails

### Changed
- **TaskMetadata Architecture**: Rewrote from_ace_taskflow_output() to parse CLI format instead of YAML frontmatter
- **Error Handling**: Better distinction between task not found vs worktree not found scenarios

## [0.1.8] - 2025-11-04

### Fixed
- **Remove Command Dry-run Inconsistency**: Fix critical bug where `--dry-run` worked but actual execution failed for completed tasks
- **Task Lookup for Completed Tasks**: Add fallback logic to remove worktrees even when task metadata not found (tasks moved to done/)
- **Consistent Task Validation**: Ensure dry-run and actual execution use identical task validation logic
- **Graceful Worktree Removal**: Remove worktrees with clear messaging when tasks are completed but worktrees exist
- **PathExpander Namespace**: Fix namespaced PathExpander reference for proper module loading

### Added
- **Fallback Worktree Detection**: Search for worktrees by task reference when ace-taskflow metadata unavailable
- **Direct Git Worktree Removal**: Use direct git worktree commands to bypass problematic safety checks
- **Clear User Feedback**: Inform users when task not found but worktree removal proceeds
- **Completed Task Support**: Enable cleanup of worktrees for tasks marked as done in ace-taskflow

### Changed
- **Task Removal Logic**: Remove dependency on task metadata availability for worktree cleanup
- **Error Handling**: Provide helpful messages instead of failures when tasks are completed
- **Remove Command Behavior**: Now works consistently across all task states (active, completed, missing)

## [0.1.7] - 2025-11-04

### Fixed
- **Worktree Detection**: Fix critical issue where `ace-git-worktree list` showed "No worktrees found" despite existing worktrees
- **Git Output Parsing**: Update porcelain format parsing to handle 3-line format per worktree (worktree/HEAD/branch lines)
- **CommandExecutor Integration**: Fix timeout parameter mismatch causing git help output instead of worktree listing
- **Module Path**: Correct require path from `ace/git/diff/atoms/command_executor` to `ace/git_diff/atoms/command_executor`
- **YAML Loading**: Add missing `require "yaml"` to ConfigLoader classes

### Added
- **Full Worktree Support**: Now detects and displays all 7 existing worktrees (6 task-associated + 1 main)
- **Task Association**: Proper task ID extraction from existing worktree paths (086, 089, 090, 091, 093, 097)
- **Mixed Environment**: Support for both task-aware and traditional worktrees in unified view

### Changed
- **Porcelain Parsing**: Complete rewrite of `from_git_output_list()` to handle structured porcelain format
- **Worktree Information**: Enhanced display showing Task, Branch, Path, and Status for all worktrees

## [0.1.6] - 2025-11-04

### Fixed
- **Binstub**: Fix hardcoded path from `.ace-wt/task.089-zai/ace-git-worktree/` to `ace-git-worktree/`
- **VERSION**: Eliminate duplicate VERSION constant warnings by loading from correct gem location
- **Open3**: Add fallback for `Open3::CommandTimeout` constant for Ruby installations where it's not available
- **Configuration**: Improve template validation to be template-specific rather than overly strict
- **Configuration**: Add YAML fallback loading when `ace-support-core` is not available

### Changed
- **Template Validation**: Directory format requires `{task_id}`, branch format requires `{id, slug}`, commit format requires `{release, task_id, slug}`
- **Configuration Loading**: Now loads from `.ace/git/worktree.yml` even when ace-support-core gem is missing

## [0.1.5] - 2025-11-04

### Fixed
- **Documentation**: Remove duplicate changelog entry for version [0.9.109] in project CHANGELOG.md
- **Documentation**: Remove duplicated retrospective template content from task 0891 retro document
- Clean up placeholder template sections that were accidentally included in documentation
- Improve professional documentation quality by eliminating redundancies

### Added
- Comprehensive review documentation including GPT-5 codex review and Google Pro review reports
- Complete documentation of all review feedback implementations and resolutions
- Enhanced project documentation with detailed review metadata and analysis

### Documentation
- Verified README.md version flag documentation is correct
- Clean changelog without duplicate entries for better maintainability
- Professional documentation standards meeting Google Pro review recommendations

## [0.1.4] - 2025-11-04

### Fixed
- **CRITICAL**: Fix CLI override flags being ignored (--no-mise-trust, --no-status-update, --no-commit, --commit-message)
- **CRITICAL**: Fix overly restrictive branch validation that rejected / characters and main/master branches
- WorktreeManager now properly respects --no-mise-trust flag before applying configuration defaults
- TaskWorktreeOrchestrator respects all CLI override flags instead of always using configuration defaults
- Branch validation now follows Git's actual branch naming rules while maintaining security
- Fix regex syntax errors in task_fetcher.rb and mise_trustor.rb character classes

### Added
- Comprehensive test coverage for branch validation with slash characters and main/master branches
- Integration tests for CLI override functionality across all override flags
- Tests for custom commit message functionality
- Enhanced CLI command tests with override flag verification

### Technical
- Updated valid_branch_name? to allow legitimate Git branch patterns (feature/login, bugfix/issue-123, etc.)
- Enhanced option merging logic in WorktreeManager and TaskWorktreeOrchestrator
- Fixed CreateCommand initialization to use fully qualified constant names
- Maintained all existing security protections while fixing functional regressions

## [0.1.3] - 2025-11-04

### Security
- **CRITICAL**: Fix path traversal vulnerability in PathExpander atom
- **CRITICAL**: Fix command injection vulnerability in MiseTrustor and TaskFetcher
- Add comprehensive input validation for task IDs and file paths
- Implement command whitelisting and argument sanitization
- Add protection against symlink-based attacks with realpath resolution

### Fixed
- Update gemspec metadata from placeholder ACE team values to correct author information
- Fix Gemfile to use eval_gemfile pattern following ACE standards
- Modernize Rakefile to use ace-test patterns instead of outdated rake/testtask
- Remove Gemfile.lock from gem directory to follow ACE conventions

### Added
- Comprehensive test coverage for all CLI commands (6/6 commands)
- Security tests for path traversal and command injection prevention
- Integration tests for molecules and organisms
- Graceful error handling when ace-taskflow is unavailable
- Helpful error messages with installation guidance
- Troubleshooting section in README.md with step-by-step solutions

### Technical
- Enhanced security validation across all user input points
- Improved dependency management with graceful degradation
- Better error reporting with specific guidance for common issues
- Comprehensive security test suite with attack vector coverage

## [0.1.2] - 2025-11-04

### Fixed
- Update dependency from ace-core to ace-support-core in gemspec
- Add required support gems (ace-support-markdown, ace-support-mac-clipboard) to Gemfile
- Resolves dependency conflicts after ace-core → ace-support-core migration

## [0.1.1] - 2025-11-04

### Fixed
- Resolve syntax and runtime errors in ace-git-worktree gem
- Fix comment formatting errors in model files (task_metadata.rb, worktree_metadata.rb)
- Fix Ruby syntax errors (hash conditional values, constant assignment in methods)
- Fix initialization order in WorktreeManager
- Implement lazy loading for CLI commands to prevent configuration validation during help

### Technical
- Update gemspec dependencies to use less restrictive version constraints
- Improve CLI command registration with lazy loading pattern

## [0.1.0] - 2025-11-04

### Added
- Initial release of ace-git-worktree gem
- Task-aware worktree creation with ace-taskflow integration
- Configuration-driven naming conventions
- Automatic mise trust execution
- Traditional worktree operations (create, list, remove, prune, switch)
- ATOM architecture implementation
- CLI interface with comprehensive commands
- Configuration cascade support via ace-core

### Features
- Task metadata fetching from ace-taskflow
- Automatic task status updates
- Worktree metadata tracking in task frontmatter
- Configurable directory and branch naming
- Support for multiple worktrees per task
- Error handling and validation
- Comprehensive test coverage

[Unreleased]: https://github.com/ace-ecosystem/ace-meta/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/ace-ecosystem/ace-meta/releases/tag/v0.1.0