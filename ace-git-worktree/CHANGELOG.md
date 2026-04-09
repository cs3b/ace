# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.19.11] - 2026-04-09

### Technical
- Moved deterministic E2E coverage into sandboxed `test-e2e/integration` Minitest and reserved `test-e2e/scenarios` for LLM-driven flows by removing the package's markdown scenario suite.

### Fixed
- Stabilized the multi-task worktree E2E by requiring explicit post-create cwd evidence and blocking create-time auto-navigation drift before listing both tasks.
- Updated remaining worktree E2E runners to use the current positional create syntax and explicit forced cleanup captures for task-aware remove flows.
- Updated the remaining worktree E2E scenarios to use the current create/list command forms, including explicit branch-aware create syntax and explicit task-aware list filters.
- Aligned worktree lifecycle E2E setup with `ACE_E2E_SOURCE_ROOT`, pre-created the worktree parent path, and updated dry-run/remove expectations to match current behavior.
- Corrected `TS-WORKTREE-001` lifecycle E2E coverage to create new worktrees beneath `.ace-wt/` and accept explicit missing-path filesystem evidence for dry-run, remove, and prune checks.


### Fixed
- Relaxed `TS-WORKTREE-002` branch-name verification so task-aware worktree creation accepts the current task-derived branch naming contract instead of requiring the full task ID string.

## [0.19.4] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.

## [0.19.3] - 2026-03-29

### Fixed
- Bumped the `ace-git` runtime dependency constraint to `~> 0.19` so ace-git-worktree stays aligned with the current git workflow release.

## [0.19.2] - 2026-03-29

### Technical
- Register package-level `.ace-defaults` skill-sources for ace-git-worktree to enable canonical skill discovery in fresh installs.


## [0.19.1] - 2026-03-29

### Fixed
- **ace-git-worktree v0.19.1**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.19.0] - 2026-03-23

### Changed
- Moved Installation from README to Getting Started guide.
- Clarified agent workflow references in Use Cases (removed raw `/as-` prefix).
- Replaced generic "coordinate with git tools" use case with ace-overseer integration paragraph.
- Explained "hooks" in README intro with parenthetical definition.
- Converted Related Tools in usage guide to linked sibling packages.
- Redesigned getting-started demo tape: proper sandbox setup with git-init, branch-based worktree creation.
- Re-recorded getting-started demo GIF from new tape.

## [0.18.3] - 2026-03-23

### Changed
- Refreshed the package README to align with the current ACE layout pattern, including standardized section labels, bullet style, and footer link format.

## [0.18.2] - 2026-03-22

### Changed
- Updated the getting-started demo to create and reuse a runtime `ace-task` ID for task-aware worktree preview commands instead of hard-coded `001`.
- Added explicit sandbox git bootstrap setup in the demo scenario to keep dry-run worktree commands reproducible in clean environments.

## [0.18.1] - 2026-03-22

### Technical
- Removed `release` template-variable support and references from task configuration runtime paths, aligning package behavior with task ID-based defaults.

## [0.18.0] - 2026-03-22

### Changed
- Shortened default task worktree naming to `t.{task_id}` for all default package behavior.
- Expanded task worktree ID parsing so short and short-prefixed task IDs (`t.*`, `ace-t.*`) resolve consistently with existing `task.*` and `ace-task.*` formats.

## [0.17.2] - 2026-03-22

### Technical
- Aligned the getting-started demo tape output path with the checked-in `docs/demo` asset.

## [0.17.1] - 2026-03-22

### Fixed
- Corrected user-doc frontmatter and Markdown table rendering in the README plus getting-started, usage, and handbook docs.
- Replaced Kramdown-only code block markup with fenced Markdown blocks in user-facing docs.
- Added `docs/**/*` to the gemspec file manifest and removed the duplicated `--keep-directory` option entry from the usage reference.

## [0.17.0] - 2026-03-22

### Changed
- Rewrote the README as a landing page and split long-form package documentation into getting-started, usage, and handbook guides.
- Added committed demo tape and GIF assets for the new documentation flow.
- Refreshed package metadata messaging to match the landing-page positioning.

## [0.16.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.16.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.15.7] - 2026-03-17

### Fixed
- Updated CLI help-output tests to accept the shared `ace-support-cli` help header format after framework migration.

## [0.15.6] - 2026-03-15

### Fixed
- Fixed `--delete-branch` flag raising "missing argument" error after ace-support-cli migration by replacing multi-char `-db` alias with single-char `-D` to avoid OptionParser misparse

## [0.15.5] - 2026-03-15

### Fixed
- Fixed `list` command returning "No worktrees found" after ace-support-cli migration by guarding nil option values from being treated as explicit `--no-*` filters

## [0.15.4] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.15.3] - 2026-03-13

### Changed
- Updated canonical worktree skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.15.2] - 2026-03-13

### Changed
- Removed the Codex-specific delegated execution metadata from the canonical `as-git-worktree` and `as-git-worktree-manage` skills so provider projections now inherit the canonical skill body unchanged.

## [0.15.1] - 2026-03-12

### Fixed
- Kept `ace-git-worktree list --format json` stdout JSON-only by suppressing CLI config summaries and legacy summary footers in JSON mode.

### Technical
- Added regression coverage for JSON list output to ensure downstream parsers receive a single valid JSON document.

## [0.15.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-git-worktree` and `as-git-worktree-manage` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

## [0.14.0] - 2026-03-10

### Added
- Added the canonical handbook-owned git worktree skill for task-aware worktree management.


## [0.13.22] - 2026-03-05

### Fixed
- Fixed `ace-git-worktree` exit-code propagation for command failures so missing tasks and invalid remove/create operations now return a non-zero status from the executable.

## [0.13.21] - 2026-03-05

### Changed
- Worktree task-aware E2E scenarios were migrated to non-legacy `.ace-tasks` fixtures and modern task IDs.

## [0.13.20] - 2026-03-03

### Fixed
- `TaskIDExtractor`: support B36TS directory naming (`ace-task.hy4`, `task.hy4`) in path-based extraction, fixing task ID resolution for new-format worktree paths

## [0.13.19] - 2026-03-03

### Fixed
- `TaskIDExtractor`: support B36TS task ID format (`8pp.t.hy4`) in `extract` and `normalize` methods, fixing `ace-overseer work-on` failure when updating task status with new ace-task IDs

## [0.13.18] - 2026-03-02

### Changed
- Replace `ace-taskflow` dependency with `ace-task` — migrate `TaskFetcher`, `TaskStatusUpdater`, and `TaskIDExtractor` to ace-task APIs
- Update CLI fallback commands from `ace-taskflow` to `ace-task`
- Update user-facing error messages and help text to reference `ace-task`

## [0.13.17] - 2026-02-25

### Technical
- Bump runtime dependency constraint from `ace-git ~> 0.10` to `ace-git ~> 0.11`.

## [0.13.16] - 2026-02-24

### Fixed
- Restore correct `list` filter behavior for `--task-associated`, `--no-task-associated`, and `--no-usable` when invoked via the dry-cli command path by preserving explicit false flags during CLI-to-legacy argument forwarding.

### Technical
- Add CLI regression coverage to assert forwarding of `--task-associated`, `--no-task-associated`, and `--no-usable` to `ListCommand`.

## [0.13.15] - 2026-02-24

### Fixed
- Resolve task-association listing via task-aware worktree metadata whenever `--task-associated` or `--no-task-associated` filters are requested, even without `--show-tasks`.

### Technical
- Add regression coverage for CLI filter option propagation and manager-side task-filter listing path selection.

## [0.13.14] - 2026-02-24

### Fixed
- Compute list statistics from the filtered worktree set in `list` output so `--task-associated` and other filtered views report accurate totals.

## [0.13.13] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.13.12] - 2026-02-22

### Changed
- Migrate CLI to standard multi-command help pattern with explicit `help`, `--help`, and `-h` registration via `HelpCommand`
- Remove implicit default routing behavior and require explicit command selection for unknown inputs

### Technical
- Route executable through `Dry::CLI.new(...).call(arguments: ...)` with no-argument normalization to `--help`
- Update CLI command tests to use explicit `Dry::CLI` and executable-level routing assertions

## [0.13.10] - 2026-02-21

### Fixed
- Fix task ID extraction from worktree path matching incidental 3-digit numbers in parent directories (e.g., `ace-task.273`) by using `File.basename` instead of full path

### Technical
- Add `WorktreeInfoTest` covering task ID extraction from porcelain output, parent-path false matches, and branch fallback

## [0.13.9] - 2026-02-21

### Fixed
- Rewrite `from_git_output_list` to parse porcelain format by blank-line-separated blocks instead of fixed 3-line assumption, correctly handling prunable and detached worktrees

## [0.13.8] - 2026-02-21

### Fixed
- Fix worktree filter to handle `false` values for `task_associated` and `usable` options (use nil check instead of truthy check, preventing false from being treated as "not set")
- Show `target_branch` in dry-run output when present

### Technical
- Add tests for `list_all` with `false` filter values to prevent regression
- Improve E2E test for `switch` command to verify path existence dynamically

## [0.13.7] - 2026-02-19

### Technical
- Namespace worktree workflow instructions into git/ subdirectory

## [0.13.6] - 2026-02-19

### Fixed
- Update TaskIDExtractor tests to remove `.00` orchestrator suffix references after TaskReferenceParser change

## [0.13.5] - 2026-02-19

### Fixed
- Pass `--force` flag to `git worktree remove` when force removal is requested, fixing "contains modified or untracked files" errors during forced prune

## [0.13.4] - 2026-02-19

### Fixed
- Add `ignore_untracked` support to worktree removal dirty checks so callers can treat untracked-only trees as safe while still blocking tracked changes

## [0.13.3] - 2026-02-18

### Fixed
- Ensure parent directory exists before worktree path validation to prevent PathExpander rejection when `.ace-wt/` directory doesn't exist yet

## [0.13.2] - 2026-02-16

### Fixed
- Fix ace-tmux invocation in CreateCommand: remove hardcoded `start` subcommand so ace-tmux can auto-detect context (add window inside existing tmux session vs start new session)

## [0.13.1] - 2026-02-16

### Fixed
- Fix `tmux_enabled?` and `should_auto_navigate?` config loading: `ConfigLoader#load` returns a `WorktreeConfig` object, not a raw hash — remove redundant `WorktreeConfig.new()` wrapping that caused tmux config to be silently ignored

## [0.13.0] - 2026-02-16

### Added
- Tmux integration for worktree creation: optional `tmux: true` config under `git.worktree` launches an `ace-tmux` session rooted at the new worktree after creation
- `tmux?` config accessor in WorktreeConfig model
- Runtime detection of `ace-tmux` binary with graceful fallback to `cd` hint when unavailable

### Technical
- Migrate E2E tests to TS-format and enhance task-awareness
- Consolidate E2E test configuration fixtures

## [0.12.7] - 2026-02-11

### Fixed
- TaskIDExtractor regex now correctly matches `task.NNN` in paths containing `ace-task.NNN` directory prefixes

### Technical
- Add path extraction test cases for TaskIDExtractor

## [0.12.6] - 2026-02-01

### Fixed
- Prevent non-zero exit on help command
- Correct target branch fallback for non-subtask worktrees
- Stub `GitCommand.current_branch` in integration tests to prevent tests from reading actual git branch

### Technical
- Adopt exception-based exit codes
- Standardize E2E test artifact paths
- Update E2E test directory structure for worktree operations

## [0.12.5] - 2026-01-28

### Fixed

- Use current branch as target branch fallback for non-subtask tasks instead of always defaulting to main, fixing wrong PR target branch when creating worktrees from feature branches

## [0.12.4] - 2026-01-22

### Fixed
- Correct branch existence detection in `branch_exists?` to check local and remote refs separately (git show-ref --verify requires ALL refs to exist, not ANY)
- Correct remote branch detection in `detect_remote_branch` to validate remote names via `validate_remote_exists`, preventing branches like `feature/login` from being incorrectly treated as remote branches

## [0.12.3] - 2026-01-20

### Fixed
- Fallback to current branch for target branch resolution when parent task has no worktree metadata (Task 222)

## [0.12.2] - 2026-01-16

### Changed
- Rename context: to bundle: keys in configuration files

## [0.12.1] - 2026-01-14

### Changed
- Migrate CLI to Hanami pattern (per ADR-023)
  - Moved command classes from `cli/*.rb` to `cli/commands/*.rb`
  - Updated namespace from `CLI::*` to `CLI::Commands::*`
  - SharedHelpers module moved to `cli/commands/shared_helpers.rb`
  - Commands still delegate to `commands/*_command.rb` for business logic

## [0.12.0] - 2026-01-13

### Added
- Target branch tracking in worktree metadata
  - `WorktreeMetadata` now includes `target_branch` attribute for tracking PR target branch
  - `ParentTaskResolver` molecule automatically determines target branch from parent task
  - Subtasks target their orchestrator's worktree branch instead of defaulting to main
  - CLI `--target-branch` option allows manual override of auto-detected target branch
  - Fallback to `main` when parent task or worktree metadata is not found

### Technical
- New `ParentTaskResolver` molecule for resolving parent task's worktree branch
- Updated `WorktreeMetadata` model with optional `target_branch` field
- Updated `WorktreeCreator.create_for_task` to accept and return `target_branch`
- Updated `TaskWorktreeOrchestrator` to determine and pass target branch through workflow

## [0.11.0] - 2026-01-07

### Changed
- **BREAKING**: Migrate CLI framework from Thor to dry-cli (per ADR-018)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Added `ace-support-core ~> 0.10` dependency for CLI base classes
  - New CLI structure: `lib/ace/git/worktree/cli/` contains dry-cli command classes
  - Existing `commands/` directory preserved (contains command implementations)
  - Command aliases: `list` → `ls`, `switch` → `cd`, `remove` → `rm`
  - Version command now uses standardized `Ace::Core::CLI::DryCli::VersionCommand`
  - `--verbose` (`-v`) is now verbose output, `--version` is for version (ADR-018)
  - Tests updated to check output instead of return values (dry-cli limitation)
- **BREAKING**: Renamed `--branch`/`-b` option to `--from`/`-b` in create command
  - Clarifies that this specifies the source branch, not the target branch name
  - The `-b` short alias still works for backward compatibility

### Fixed
- **Critical**: Command aliases (`ls`, `cd`, `rm`) now work correctly
  - Previously, aliases were misrouted to the default `create` command
  - Added `COMMAND_ALIASES` constant to `KNOWN_COMMANDS` for proper routing
- Fixed `ConfigSummary.display` to pass actual CLI options instead of empty hash
- Fixed security validation test to use `capture_io` for proper output capture

### Technical
- CLI module now extends `Dry::CLI::Registry` with command registration
- Command classes in `cli/` directory wrap existing `commands/` implementations
- Config command accepts subcommand as positional argument (backward compatibility)
- All commands support `--quiet`, `--verbose`, `--debug` flags from base module
- Default command routing preserved (empty args → `create`)
- Extracted shared helpers into `cli/shared_helpers.rb` module (DRY)
- Standardized verbose option aliases to just `["-v"]` across all commands

## [0.10.2] - 2026-01-06

### Fixed
- Thor CLI consuming `--files` option in `config` command instead of passing to ConfigCommand

### Changed
- Add `:config` to `stop_on_unknown_option!` to fix `ace-git-worktree config --files`

## [0.10.1] - 2026-01-06

### Fixed
- Thor CLI consuming command-specific options (`--task`, `--pr`, `--branch`, etc.) instead of passing them to command handlers, causing `ace-git-worktree create --task 178` to show help instead of executing

### Changed
- Add `stop_on_unknown_option!` to let command handlers parse their own options

## [0.10.0] - 2026-01-05

### Added
- Thor CLI migration with standardized command structure
- ConfigSummary display for effective configuration with sensitive key filtering
- Comprehensive CLI help documentation across all commands
- self.help overrides for custom command descriptions

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Migrated from OptionParser to Thor framework
- Added method_missing for default subcommand support

### Fixed
- CLI routing and dependency management for feature parity
- --help dispatch for all ACE commands

### Technical
- Refactored tests to use capture_io and assert exceptions

## [0.9.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.0.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.8.4] - 2026-01-03

### Changed

* Optimize test execution time from 6.6s to under 5s (28% improvement)
* Strengthen security assertions and add dependency injection to commands
* Remove unnecessary git init calls from test setup

### Technical

* Add detailed implementation plan for test performance optimization

## [0.8.3] - 2026-01-02

### Changed

* **BREAKING**: `TaskStatusUpdater#update_status`, `#mark_in_progress`, `#mark_done`, `#mark_blocked` now return `{success: Boolean, message: String}` instead of Boolean
  - Enables rich error propagation for dependency-blocked tasks
  - Orchestrator now displays actionable error messages with hints
* Improved error message for dependency-blocked tasks with `--no-status-update` hint

## [0.8.2] - 2026-01-01

### Changed

* Centralize timeout configuration in gem config file
* Add `default_timeout` and `max_timeout` to `.ace-defaults/git/worktree.yml`

## [0.8.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.8.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.7.0] - 2025-12-27

### Changed
- **Configuration**: Migrate to ADR-022 configuration pattern
  - Removed unused `DEFAULT_*` constants from Configuration module
  - Configuration now fully delegated to ace-support-core cascade and `.ace.example` defaults
  - Reduces code duplication (~40 LOC) and aligns with project-wide configuration standards
  - Default values remain available via `WorktreeConfig::DEFAULT_CONFIG` model

## [0.6.1] - 2025-12-27

### Changed
- **Error Handling**: Removed `StandardError` from inner rescue clause in `create_pr_worktree`
  - Specific ace-git errors now bubble up correctly to top-level handler
  - Prevents silently swallowing unexpected errors
- **Code Organization**: Extracted error handling methods from `handle_pr_fetch_error`
  - `handle_pr_not_found`, `handle_gh_auth_error`, `handle_gh_not_installed`, `handle_unknown_error`
  - Improved code readability and maintainability
- **Debug Output**: Added backtrace info for unknown errors when `ENV["DEBUG"]` is set
- **Documentation**: Added schema documentation for `pr_data_from_metadata` method
- **Defensive Access**: Added fallback to "unknown" for `headRepositoryOwner` dig access
- **README**: Added version compatibility table for ace-git dependency
- **Dependency**: Updated ace-git dependency constraint to `~> 0.4`

## [0.6.0] - 2025-12-26

### Added
- **Fork PR Detection**: PR worktree creation now detects and warns about fork PRs
  - Shows warning when PR is from a fork (`isCrossRepository`)
  - Displays fork owner info (`headRepositoryOwner`)
  - Informs user they cannot push to fork PR branches directly
- **PR Number Validation**: Extracted `PR_NUMBER_PATTERN` constant for consistent validation
- **Debug Output**: Added `ENV["DEBUG"]` support for unexpected error diagnostics
- **Test Coverage**: Added CLI integration tests for `--pr` flag and timeout parameter tests

### Changed
- **Dependency Update**: Replaced ace-git-diff dependency with ace-git (~> 0.3)
  - GitCommand atom now delegates to `Ace::Git::Atoms::CommandExecutor` from ace-git
  - Creates unified Git operations across ACE ecosystem packages
  - Maintains full backward compatibility for existing code
- **PR Worktree Creation**: Migrated to use `Ace::Git::Molecules::PrMetadataFetcher`
  - More robust PR metadata fetching with better error handling
  - Consistent with ace-git's PR operations used across other packages
- **Simplified GitCommand**: `current_branch` now delegates directly to ace-git
  - ace-git handles detached HEAD state internally (returns SHA)
  - Removed local workaround code (~20 lines)
- **Ruby 3 Syntax**: Updated to use keyword argument forwarding (`timeout:`)
- **Test Helpers**: Promoted `with_git_stubs` to shared `test_helper.rb`

### Removed
- Deleted `molecules/pr_fetcher.rb` - replaced by ace-git's `PrMetadataFetcher`
- Deleted corresponding `test/molecules/pr_fetcher_test.rb`

## [0.5.0] - 2025-12-17

### Added
- **Current Task Symlink**: Creates `_current` symlink inside worktree when creating task worktrees
  - Symlink created at worktree root (e.g., `.ace-wt/task.145/_current`)
  - Points to the task directory within the worktree (e.g., `.ace-taskflow/v.0.9.0/tasks/145-feat/`)
  - Quick access from worktree: `cat _current/*.s.md`, `ls _current/`
  - Uses relative paths for portability
  - Configurable: `task.create_current_symlink` (default: `true`) and `task.current_symlink_name` (default: `"_current"`)
  - Non-blocking: symlink failure doesn't abort worktree creation
  - New `CurrentTaskLinker` molecule handles symlink lifecycle
  - Dry-run shows planned symlink creation

## [0.4.8] - 2025-12-03

### Fixed
- **Upstream Branch Reliability**: Enhanced upstream tracking setup with fallback mechanism
  - Added `set_upstream` method to TaskPusher using `git branch --set-upstream-to`
  - `setup_upstream_for_worktree` now tries `git push -u` first, falls back to `--set-upstream-to` if push fails but remote branch exists
  - Added `remote_branch_exists?` helper to check remote branch availability
  - Fixes inconsistent upstream tracking when creating task worktrees

## [0.4.7] - 2025-12-01

### Changed
- **Default Behavior**: `auto_setup_upstream` and `auto_create_pr` now default to `false`
  - Pushing branches and creating PRs now require explicit opt-in via config or CLI flags
  - Follows principle of least surprise - network/remote operations should not happen unexpectedly
  - To enable: set `git.worktree.task.auto_setup_upstream: true` and `auto_create_pr: true` in config

### Fixed
- **Detached HEAD PR Base**: When creating PR from a detached HEAD (SHA as start_point):
  - Now creates a branch on remote (`base-{sha-short}`) for the commit SHA
  - Uses that branch as PR base instead of failing with invalid `--base` argument
  - Falls back to `main` only if remote branch creation fails

## [0.4.6] - 2025-11-30

### Fixed
- **Worktree Task Update**: Set `PROJECT_ROOT_PATH` env var when updating task in worktree
  - Ensures TaskManager updates the task file in the worktree, not the main project
  - Fixes "No commits between branches" error when creating PRs
  - The `started_at` timestamp is now correctly committed to the worktree branch

## [0.4.5] - 2025-11-30

### Added
- **Initial Worktree Commit**: Adds `started_at` timestamp to task before PR creation
  - Creates initial commit in worktree branch enabling PR creation
  - GitHub requires at least one commit difference between branches for PRs
  - New step 9.5 in workflow: update task → commit → push → then create PR
  - Uses `TaskStatusUpdater.add_started_at_timestamp()` method

## [0.4.4] - 2025-11-30

### Fixed
- **PR Creation Bug**: Always pass `--body` flag when creating draft PRs
  - `gh pr create` requires both `--title` and `--body` in non-interactive mode
  - Now defaults `--body` to the PR title when no body is provided

## [0.4.3] - 2025-11-30

### Fixed
- **Metadata Commit Bug**: Task changes now properly commit when metadata is added
  - Previously, commits only happened when task status was updated
  - Now commits happen when either status is updated OR metadata is added
  - Ensures worktree metadata is committed before detaching to new worktree
- Dry run (`--dry-run`) now accurately reflects when commit/push will happen

## [0.4.2] - 2025-11-29

### Fixed
- **Branch Source Bug**: New worktree branches now correctly use the current branch as their start-point
  - Previously, worktrees created from within another worktree would base their branch on main worktree's HEAD
  - Now `git worktree add` explicitly passes the current branch (or commit SHA) as the start-point
  - Added `--source <ref>` option to specify a custom git ref as branch start-point (e.g., `--source main`)
  - Handles detached HEAD state by using the commit SHA as start-point

### Added
- `GitCommand.ref_exists?`: New method to validate that a git ref exists before using it
- `--source` CLI option for `create` command: Explicitly specify which git ref to base the new branch on
- Result hash now includes `start_point` field showing which ref was used as the branch base

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

[Unreleased]: https://github.com/cs3b/ace/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/cs3b/ace/releases/tag/v0.1.0


## [0.13.11] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
