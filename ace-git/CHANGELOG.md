# Changelog

All notable changes to ace-git will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.10.5] - 2026-01-29

### Added
- Integrate exception-based CLI error handling
- Enhance commit reorganization workflow with bundle integration

### Technical
- Clarify reorganize-commits workflow: reorganize means reorder, not squash

## [0.10.4] - 2026-01-28

### Added
- Add bundle section to reorganize-commits workflow for context loading via ace-bundle

## [0.10.3] - 2026-01-27

### Changed
- Lock retry now detects active lock PID and increases wait time on active locks
- Lock cleanup reports lock status metadata (pid/age) for better diagnostics
- CLI now shows error for unknown commands instead of routing to diff

## [0.10.2] - 2026-01-27

### Technical
- Simplified reorganize-commits workflow documentation

## [0.10.1] - 2026-01-27

### Changed
- Renamed squash-commits workflow and skill to reorganize-commits
  - Workflow: `squash-commits.wf.md` → `reorganize-commits.wf.md`
  - Skill: `ace:squash-commits` → `ace:reorganize-commits`
  - Better reflects the workflow purpose: organizing commits into logical groups

## [0.10.0] - 2026-01-26

### Added
- **Reset-split rebase strategy** as default in rebase workflow
  - Uses `ace-git-commit` path-based splitting for zero-conflict rebases
  - Automatically groups files by scope and generates distinct messages
  - Orders commits logically: feat → fix → chore → docs
  - Eliminates manual CHANGELOG conflict resolution for most rebases

### Changed
- Rebase workflow redesigned with three named strategies:
  - `reset-split` (DEFAULT): Soft reset + ace-git-commit for clean history
  - `manual`: Traditional rebase for preserving exact commit history
  - `interactive`: For commit squashing/reordering
- Simplified default rebase to 3 steps: fetch, reset --soft, ace-git-commit

## [0.9.0] - 2026-01-19

### Added
- Package-based commit squashing strategy (default for monorepo)
  - Documents one commit per package/module approach
  - Includes package-prefixed commit message format (e.g., `feat(ace-lint): ...`)
  - Added Strategy 1: Package-Based as default monorepo approach
  - Renumbered existing strategies (Logical Grouping, Commit Per Feature, One Commit Per Version)

### Changed
- Renamed squash-pr workflow and skill to squash-commits
  - Workflow: `squash-pr.wf.md` → `squash-commits.wf.md`
  - Skill: `ace:squash-pr` → `ace:squash-commits`
  - Updated ace-git-commit path handling documentation
    - Removed incorrect `git add` + `ace-git-commit paths` pattern
    - Documented correct pattern: `ace-git-commit <path1> <path2> --intention "..."`
    - Added warning about passing paths directly to ace-git-commit
  - Clarified PR-based vs commit-range-based workflow usage methods
- Updated for ace-bundle integration
  - Workflow integration via wfi:// protocol
  - Improved workflow discovery and loading

## [0.8.2] - 2026-01-16

### Changed
- Updated README.md workflow examples from /ace:load-context to /ace:bundle (task 206)

## [0.8.1] - 2026-01-13

### Added
- PID-based orphan detection for git lock files
  - New `orphaned?` method checks if lock-owning process still exists
  - Instant cleanup of orphaned locks (dead PID) regardless of age
  - Age-based stale detection remains as fallback for edge cases

### Changed
- Lock retry now uses fixed 500ms delay (was exponential 50→100→200→400ms)
- Lock cleanup attempted on every retry (was only first retry)
- Updated `initial_delay_ms` default from 50 to 500 in config
- Updated create-pr workflow to use worktree metadata for target_branch detection
  - Added `yq` command to read `target_branch` from `.ace-taskflow/task.yml`
  - Worktree metadata is now the preferred method for determining PR target branch
  - Falls back to legacy parent task detection when metadata unavailable
- Updated rebase workflow with auto-detection from worktree metadata
  - Added example for rebasing subtasks against parent branch
  - `target_branch` now auto-detects from worktree metadata → origin/main fallback

## [0.8.0] - 2026-01-12

### Added
- Git index lock retry with stale lock cleanup (task 210)
  - `LockErrorDetector` atom to detect git index lock errors from stderr
  - `StaleLockCleaner` atom to detect and remove stale lock files (>60s old)
  - Automatic retry with exponential backoff (50ms → 100ms → 200ms → 400ms)
  - `lock_retry` configuration section in `.ace-defaults/git/config.yml`
  - Configurable retry behavior: `enabled`, `max_retries`, `initial_delay_ms`, `stale_cleanup`, `stale_threshold_seconds`

### Changed
- Modified `CommandExecutor.execute()` to wrap git commands with lock retry logic
- Updated `CommandExecutor.repo_root()` to use `execute_once()` directly to prevent recursion
- All 459 tests pass including 30 new tests for lock retry behavior

## [0.7.1] - 2026-01-09

### Changed
- **BREAKING**: Eliminate wrapper pattern in dry-cli commands
  - Merged business logic directly into `Branch`, `Diff`, `PR`, and `Status` dry-cli command classes
  - Deleted `branch_command.rb`, `diff_command.rb`, `pr_command.rb`, and `status_command.rb` wrapper files
  - Simplified architecture by removing unnecessary delegation layer

## [0.7.0] - 2026-01-07

### Changed
- **BREAKING**: Migrated CLI framework from Thor to dry-cli (task 179.06)
  - Replaced `thor` dependency with `dry-cli ~> 1.0`
  - Created dry-cli command wrappers for all commands (diff, status, branch, pr)
  - Maintained magic git range routing (HEAD~5..HEAD -> diff)
  - All 423 tests pass with complete feature parity

## [0.6.1] - 2026-01-05

### Changed
- Adopted Ace::Core::CLI::Base for standardized options (--quiet, --verbose, --debug)
- Added method_missing for default subcommand support

### Fixed
- Resolved -v flag conflict between --verbose and --version
- Addressed PR #123 review findings for Medium and higher priority issues

## [0.6.0] - 2026-01-03

### Changed
- **BREAKING**: Minimum Ruby version raised to 3.3.0 (was 3.2.0)
- Standardized gemspec file patterns with deterministic Dir.glob
- Added MIT LICENSE file

## [0.5.2] - 2026-01-03

### Changed

- Optimize test execution time from 6.54s to 4.37s (33% reduction)
  - Created `with_mock_repo_load` helper to replace 6-7 levels of nested stubs
  - Created `with_mock_diff_orchestrator` helper for consolidated stub management
  - Extracted `build_mock_prs` to test_helper.rb for reuse
  - Reused single temp directory instead of per-test Dir.mktmpdir calls
  - Organisms layer: 4.82s → 2.72s (44% faster)

### Technical

- Add `setup_repo_status_loader_defaults` helper for cleaner test setup
- Add comprehensive YARD documentation for test helpers
- Improve test hermeticity with proper stub defaults for `find_pr_for_branch` and `fetch_metadata`

## [0.5.1] - 2025-12-30

### Changed

- Replace ace-support-core dependency with ace-config for configuration cascade
- Migrate from Ace::Core to Ace::Config.create() API
- Migrate from `resolve_for` to `resolve_namespace` for cleaner config loading

## [0.5.0] - 2025-12-30

### Changed

* Rename `.ace.example/` to `.ace-defaults/` for gem defaults directory


## [0.4.0] - 2025-12-27

### Changed

- **PrMetadataFetcher**: Extracted `PR_FIELDS` constant for maintainability
  - Field list now defined as frozen constant array
  - Easier to review and modify PR metadata fields
- **BREAKING**: Renamed `context` to `status` throughout
  - CLI: `ace-git status` (no `context` alias)
  - Config: `git.status.*` (not `git.context.*`)
  - Classes: `StatusCommand`, `StatusFormatter`, `RepoStatus`, `RepoStatusLoader`
  - Files: `status_command.rb`, `status_formatter.rb`, `repo_status.rb`, `repo_status_loader.rb`
  - Output header: "# Repository Status" (was "# Repository Context")
  - Output format and JSON structure unchanged

### Removed

- **TimeFormatter.add_relative_times**: Removed unused method (YAGNI cleanup)
  - Method was marked "kept for potential future use" but never used in production
  - StatusFormatter.format_merged_time_compact is the actual method used
  - Related tests removed: test_add_relative_times_adds_merged_ago_field, test_add_relative_times_handles_missing_merged_at

## [0.3.6] - 2025-12-26

### Added

- **PrMetadataFetcher**: Expanded PR metadata with fork detection fields
  - `isCrossRepository`: Boolean indicating if PR is from a fork
  - `headRepositoryOwner`: Object with fork owner's `login` field
  - Enables ace-git-worktree to detect and handle forked PR workflows

- **BranchReader.detached?**: New method to explicitly check if HEAD is detached
  - Returns true when in detached HEAD state
  - Separate from current_branch for clearer API

### Changed

- **CommandExecutor.current_branch**: Now returns commit SHA when in detached HEAD state
  - Previously returned literal string "HEAD" for detached state
  - Consumers no longer need workarounds to get the SHA
  - Use `BranchReader.detached?` instead for explicit detached state detection

## [0.3.5] - 2025-12-24

### Fixed

- **TimeFormatter "0y ago" Bug**: Fixed relative time display for 11-12 month intervals
  - Previously showed "0y ago" for 360-364 day intervals due to rounding error
  - Now correctly shows "12mo ago" for intervals less than 365 days
  - Added regression tests for month/year boundary cases

- **Nil Title Handling**: ContextFormatter now handles missing PR titles gracefully
  - Shows "(no title)" instead of empty string when PR title is nil

- **Git Color Output**: GitStatusFetcher now disables colors with `-c color.status=false`
  - Ensures clean output for LLM context regardless of user's git configuration

### Added

- **CLI Alias**: Added `-n` alias for `--no-pr` option in `ace-git status`
- **Open PR Limit**: `fetch_open_prs` now accepts `limit` parameter (default: 10)
  - Keeps latency predictable on repositories with many open PRs

### Changed

- **Constants**: Extracted `DEFAULT_COMMITS_LIMIT` constant for consistency
  - Referenced by both CLI options and RepoContextLoader defaults
- **Hash Key Normalization**: ContextFormatter now expects symbol keys for pr_activity
  - Documented expected key types in method comments

## [0.3.4] - 2025-12-24

### Changed

- **PR Workflow Improvements**: Enhanced create-pr and update-pr-description workflows
  - Added target branch detection based on task hierarchy from `ace-taskflow status`
  - Subtasks now correctly target parent task branch instead of main
  - PR title format: `<task-id>: <description>` when task ID present (e.g., `140.10: Add feature`)
  - Auto-fix for PRs incorrectly targeting main when parent branch exists

## [0.3.3] - 2025-12-24

### Added

- **PR Activity Awareness**: `ace-git status` now shows recent PR activity
  - Recently merged PRs (last 3) with relative timestamps (e.g., "1d ago")
  - Open PRs from other team members (excluding current branch)
  - New `--no-pr` flag to skip PR lookups for faster output
  - TimeFormatter atom for relative time display

- **Enhanced Context Output**: Improved UX and readability
  - Git status (`git status -sb`) displayed in Position section
  - Recent commits section (configurable via `--commits N`, default: 3)
  - Task ID shown in Position header: `## Position (task: 140.10)`

### Changed

- **Simplified Position Section**: Combined Position and Working Tree into single section
  - Raw `git status -sb` output used directly (no custom formatting)
  - Cleaner, more compact output matching git conventions

### Fixed

- Removed code fences from status output that confused display
- Added proper spacing after section headers for readability

## [0.3.2] - 2025-12-22

### Fixed

- **Error Propagation**: `ace-git diff` now properly reports git errors for invalid ranges
  - Previously returned "(no changes)" silently when git failed
  - Now shows actual git error message and exits with code 1
  - Added `handle_result` helper in DiffGenerator for consistent error handling

## [0.3.1] - 2025-12-22

### Added

- **Examples in Main Help**: `ace-git --help` now shows common usage examples
- **Explicit Diff Command**: `ace-git diff --help` shows full help with options
- **SYNTAX Section**: Clear `[RANGE] [OPTIONS]` documentation in diff help

### Changed

- **Compact PR Output**: Reduced PR section from ~11 lines to ~4 lines
  - Header line with PR #, title, and status in brackets
  - Key-value lines for branch, author, URL
  - Applies to both `ace-git context` and `ace-git pr` commands

## [0.3.0] - 2025-12-22

### Added

- **CLI Executable** (`ace-git`): Full CLI with Thor for all git operations
  - `ace-git diff [RANGE]` - Generate git diff with filtering (migrated from ace-git-diff)
  - `ace-git context` - Show repository context (branch, PR, task pattern)
  - `ace-git branch` - Show current branch information with tracking status
  - `ace-git pr [NUMBER]` - Fetch and display PR metadata via GitHub CLI
  - All commands support `--format json` for machine-readable output

- **Migrated Components** (from ace-git-diff):
  - Atoms: CommandExecutor, DateResolver, DiffParser, PatternFilter
  - Molecules: ConfigLoader, DiffFilter, DiffGenerator
  - Organisms: DiffOrchestrator
  - Models: DiffConfig, DiffResult
  - Full backward compatibility with ace-git-diff functionality

- **New Components**:
  - `TaskPatternExtractor` atom: Extract task IDs from branch names (e.g., "140-feature" -> "140")
  - `PrIdentifierParser` atom: Parse PR identifiers (number, owner/repo#number, GitHub URLs)
  - `RepositoryStateDetector` atom: Detect repository state (:clean, :dirty, :rebasing, :merging)
  - `RepositoryChecker` atom: Check repository type (normal, detached, bare, worktree)
  - `GitScopeFilter` atom: Filter files by git scope (staged, tracked, changed)
  - `BranchReader` molecule: Read branch info with tracking status
  - `PrMetadataFetcher` molecule: Fetch PR metadata via gh CLI
  - `RepoContextLoader` organism: Orchestrate complete context loading
  - `RepoContext` model: Structured repository context with markdown/JSON output

- **Dependencies**:
  - Added `thor` (~> 1.3) for CLI framework
  - Updated `ace-support-core` to ~> 0.11

### Changed

- Package now includes CLI executable (previously workflow-only)
- Updated gemspec to include exe directory and thor dependency
- Summary updated to reflect unified git operations

### Migration Notes

- This version consolidates functionality from ace-git-diff
- ace-git-diff will be deprecated in favor of ace-git
- Use `ace-git diff` instead of `ace-git-diff` for equivalent functionality
- Existing ace-git workflows (wfi://rebase, wfi://create-pr, wfi://squash-pr) remain unchanged

## [0.2.2] - 2025-12-13

### Changed

- **Squash Workflow Enhancement**: Updated `wfi://squash-pr` to recommend logical grouping over single-commit squashing
  - Reframed purpose: "cohesive, logical commits" instead of "one commit per version"
  - Added RECOMMENDED banner for Logical Grouping strategy
  - Reordered strategies: Logical Grouping (1st), Commit Per Feature (2nd), One Commit (3rd)
  - Added real-world example: PR #72 squashed 16 → 3 logical commits
  - Rationale: Single-commit squashing loses valuable context; logical grouping preserves separation of concerns

## [0.2.1] - 2025-11-16

### Changed

- **Dependency Update**: Updated ace-support-core dependency from `~> 0.9` to `~> 0.11`
  - Provides access to latest PromptCacheManager features and infrastructure improvements
  - Maintains compatibility with standardized ACE ecosystem patterns

## [0.2.0] - 2025-11-15

### Added

- **PR Description Workflow** (`wfi://update-pr-description`): Automated PR title and description generation
  - New `/ace:update-pr-desc` command for easy invocation from Claude Code
  - Extracts metadata from CHANGELOG.md entries and task files
  - Analyzes commit messages to identify change patterns and types
  - Generates structured PR descriptions with summary, changes breakdown, breaking changes, and related tasks
  - Auto-detects PR number from current branch or accepts explicit PR number argument
  - Uses conventional commits format for PR titles (e.g., `feat(scope): description`)
  - GitHub CLI integration for updating PR titles and descriptions
  - Comprehensive documentation with examples and best practices
  - Supports multi-line body formatting with heredoc for clean PR updates

## [0.1.0] - 2025-11-11

### Added

- Initial release of ace-git workflow package
- **Rebase Workflow** (`wfi://rebase`): Changelog-preserving rebase operations
  - CHANGELOG.md conflict resolution strategies
  - Version file preservation patterns
  - Recovery procedures for failed rebases
- **PR Creation Workflow** (`wfi://create-pr`): Pull request creation with templates
  - GitHub CLI integration examples
  - Three PR templates: default, feature, bugfix
  - Draft PR workflow support
  - Alternative platform instructions (GitLab, Bitbucket)
- **Squash Workflow** (`wfi://squash-pr`): Version-based commit squashing
  - Automatic version boundary detection
  - Multiple squashing strategies (version, interactive, manual)
  - CHANGELOG preservation during squash
  - Comprehensive commit message templates
- **Templates**: Structured templates for consistent documentation
  - PR templates: default, feature, bugfix
  - Commit squash template with structured format
- **Protocol Integration**: ace-nav protocol support
  - wfi:// protocol for workflow discovery
  - template:// protocol for template access
- **Configuration**: Minimal, preference-based configuration
  - Optional user preferences in `.ace/git/config.yml`
  - Sensible defaults inline in workflows
- Comprehensive README with usage examples
- MIT License

### Design Decisions

- Workflow-first architecture (no CLI executables)
- Self-contained workflows following ADR-001 principles
- Minimal configuration (preferences only, not behavior control)
- GitHub CLI as primary PR creation method with alternatives documented

[0.1.0]: https://github.com/cs3b/ace-meta/releases/tag/ace-git-v0.1.0
