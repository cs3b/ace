# Changelog

All notable changes to ace-git will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.16.1] - 2026-03-21

### Added
- Add GitHub release publish workflow (`wfi://github/release-publish`) for creating GitHub releases from unpublished CHANGELOG entries with daily grouping, commit targeting, and dry-run support.
- Add `as-github-release-publish` skill for invoking the GitHub release publish workflow.

## [0.16.0] - 2026-03-20

### Changed
- Expanded `TS-GIT-001` E2E coverage with new goal-level checks for diff output-path security and deterministic status JSON/no-PR behavior.
- Tightened PR summary runner/verifier contracts to require explicit fallback evidence when PR context is unavailable.

## [0.15.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.15.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.14.6] - 2026-03-17

### Fixed
- Updated CLI routing tests to match the shared `ace-support-cli` help output headers and short-help behavior.

## [0.14.5] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.14.4] - 2026-03-13

### Technical
- Updated canonical Git workflow skills for workflow-first execution compatibility.

## [0.14.3] - 2026-03-13

### Changed
- Updated canonical git workflow skills to explicitly run bundled workflows in the current project and execute them end-to-end.

## [0.14.2] - 2026-03-13

### Changed
- Replaced provider-specific Codex execution metadata on the canonical `as-github-pr-create` skill with a unified canonical skill body that declares arguments, variables, and explicit workflow-execution guidance.
- Removed the Codex-specific delegated execution metadata from the canonical `as-github-pr-update` skill so provider projections now inherit the canonical skill body unchanged.
- Limited provider-specific forking for `as-github-pr-create` to Claude frontmatter only.

## [0.14.1] - 2026-03-12

### Changed
- Updated README and handbook guide examples to load workflows through `ace-bundle` and removed legacy shared-handbook path assumptions.

## [0.14.0] - 2026-03-12

### Added
- Added Codex-specific delegated execution metadata to the canonical `as-github-pr-create` and `as-github-pr-update` skills so the generated Codex skills run in fork context on `gpt-5.3-codex-spark`.

## [0.13.0] - 2026-03-10

### Added
- Added canonical handbook-owned git and GitHub PR skills for rebase, commit reorganization, and PR create/update workflows.


## [0.12.0] - 2026-03-09

### Changed
- Rebase workflow now treats localized conflicts as continue-first instead of automatically aborting into cherry-pick fallback.
- Cherry-pick fallback is now documented as an escalation path for repeated, large, or explicitly requested conflict handling.

### Fixed
- Cherry-pick replay progress now uses session-local applied SHA tracking instead of commit-subject matching, making resumed replay more reliable.

## [0.11.18] - 2026-03-05

### Fixed
- Rebase workflow cherry-pick skip detection now uses commit subject matching instead of SHA comparison (cherry-pick produces new SHAs, so SHA-based skip never fired on resume).
- Rebase workflow Phase 3.3 now restores upstream tracking after `git branch -m` rename, which silently drops the upstream config.
- Rebase workflow Phase 5 push now uses `-u` flag to guarantee tracking is set after force-push.

## [0.11.17] - 2026-03-05

### Changed
- Diff generation now falls back safely when default git refs are unavailable, using tracking branch, `origin/main`, then `HEAD~1`.


## [0.11.16] - 2026-03-04

### Changed
- Default diff ignore artifacts now use `.ace-local/**/*`.


## [0.11.15] - 2026-03-04

### Fixed
- Rebase workflow cleanup `find` command corrected to `.ace-local/git/` (missed one occurrence in previous fix)

## [0.11.14] - 2026-03-04

### Fixed
- Rebase workflow session path corrected to short-name convention (`.ace-local/git/` not `.ace-local/ace-git/`)

## [0.11.13] - 2026-03-04

### Changed
- Rename PR workflows to domain-namespaced URIs and paths:
  - `wfi://git/create-pr` -> `wfi://github/pr/create`
  - `wfi://git/update-pr-desc` -> `wfi://github/pr/update`
  - `handbook/workflow-instructions/git/{create-pr,update-pr-desc}.wf.md` -> `handbook/workflow-instructions/github/pr/{create,update}.wf.md`
- Update PR workflow frontmatter names to `github-pr-create` and `github-pr-update`
- Update README workflow references to the new `wfi://github/pr/create` URI

## [0.11.12] - 2026-02-27

### Changed
- Add explicit code-block formatting rule and correct/incorrect example for grouped-stats output in PR creation and update workflows
- Update embedded PR templates (feature, bugfix, default) to instruct verbatim code-block pasting of grouped-stats output

## [0.11.11] - 2026-02-26

### Fixed
- Add untracked-file detection helper in command execution so callers can correctly treat untracked-only repositories as having changes.

### Technical
- Add regression tests for untracked change detection helper behavior.

## [0.11.10] - 2026-02-26

### Changed
- Refine grouped-stats header rendering so icon and label are displayed as separate columns with consistent spacing and no extra icon-side padding
- Keep file rows aligned to the same name column as package/layer headers while preserving explicit icon-column separation

## [0.11.9] - 2026-02-26

### Fixed
- Parse brace renames with an empty side (for example `{ => _archive}`) in numstat output so grouped-stats keeps move entries in the correct group

### Changed
- Compact shared rename prefixes in grouped-stats file lines to surface only the changed destination tail on the first rename line
- Normalize project-root group labeling to `./`, hide redundant layer headers when layer totals match the group totals, and suppress anonymous `other/` summary rows
- Switch repeated path-prefix squashing from space padding to explicit `.../basename` formatting for clearer relative context

## [0.11.8] - 2026-02-26

### Added
- Add emoji-prefixed grouped-stats layer headers for faster visual scanning: `🧱 lib/`, `🧪 test/`, and `📚 handbook/`

## [0.11.7] - 2026-02-25

### Changed
- Update `create-pr` and `update-pr-desc` workflows to use emoji section headers (`📋 Summary`, `✏️ Changes`, `📁 File Changes`, `🧪 Test Evidence`, `📦 Releases`) for visual section separation
- Add bullet formatting rules requiring the first key term (feature name, class name, CLI flag) to be bolded in Changes, Test Evidence, and Releases bullets

## [0.11.6] - 2026-02-25

### Added
- Squash repeated directory prefixes in `grouped-stats` file lines — consecutive files in the same directory show the shared prefix once, subsequent files show only the basename indented to align
- Squash consecutive renames sharing the same from-dir and to-dir — second and later renames show only the indented basenames on each side of the arrow
- Non-rename file following a rename always shows its full path (rename dir is not a real filesystem directory for comparison purposes)

### Changed
- Update `update-pr-desc` workflow: `## File Changes` must use the complete, untruncated `grouped-stats` output — trimming or abbreviating is explicitly forbidden

## [0.11.5] - 2026-02-25

### Fixed
- Remove blank lines within groups in `grouped-stats` plain output (between group header and first layer, and between layers)
- Wire positional `range` argument in `ace-git diff` so `ace-git diff origin/main..HEAD` correctly passes the range to the diff generator instead of silently falling back to working-tree state

### Changed
- Align stats and name columns in `grouped-stats` output: stats use `%5s, %5s` (12 chars, handles ±9999) and file-count field is right-padded so names start at a consistent column across package, layer, and file lines
- Update `update-pr-desc` workflow to use `ace-git diff $(git merge-base HEAD origin/main)..HEAD --format grouped-stats` for correct PR diff coverage

## [0.11.4] - 2026-02-25

### Fixed
- Classify single-segment dotfiles (e.g. `.gitignore`) as "Project root" instead of creating per-file groups

### Technical
- Add inline comment for unbraced exact rename fallback in `DiffNumstatParser`

## [0.11.3] - 2026-02-25

### Fixed
- Filter numstat entries by `rename_from` path in addition to `rename_to` so renames from excluded locations are correctly suppressed
- Consolidate duplicate `ace-` and dot-prefix classification branches in `FileGrouper#classify`

## [0.11.2] - 2026-02-25

### Fixed
- Short-circuit full diff generation for `grouped-stats` format to avoid redundant git subprocess
- Standardize zero-value display in grouped stats — file-level stats now show `+0`/`-0` consistently with group totals

## [0.11.1] - 2026-02-25

### Changed
- Rewrite PR description workflows to require evidence-based sections and sourcing rules (`Summary`, `Changes`, `File Changes`, `Test Evidence`, `Releases`) derived from diff, commit, test, and changelog evidence.
- Align PR creation workflow guidance with grouped-stats-first file change reporting, user-impact-first summary writing, and explicit omission/fallback rules for missing evidence.

### Technical
- Replace feature/default PR template scaffolds with concise evidence-oriented placeholders and update embedded workflow template blocks accordingly.

## [0.11.0] - 2026-02-25

### Added
- Add `ace-git diff --format grouped-stats` with package/layer grouped and aligned diff statistics output.
- Add grouped stats configuration defaults (`layers`, `collapse_above`, `show_full_tree`, `dotfile_groups`) and numstat-based grouping/formatting internals.

### Changed
- Normalize `--format grouped-stats` handling to internal `:grouped_stats` format dispatch and support markdown-oriented grouped rendering for file output.

### Technical
- Add grouped-stats unit coverage for parser, grouper, formatter, diff config, diff generator, orchestrator, and diff command integration points.

## [0.10.18] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.10.17] - 2026-02-22

### Changed
- Migrate `ace-git` CLI to standard multi-command help pattern with registered `help`, `--help`, and `-h` commands.
- Move shorthand git range routing (`ace-git HEAD~5..HEAD`) to the executable wrapper while preserving `diff` shorthand behavior.

### Technical
- Rewrite CLI routing integration tests to executable-level assertions for help/version/default routing behavior.
- Update usage documentation to reflect explicit help invocation and shorthand diff examples.

## [0.10.15] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.10.14] - 2026-02-19

### Technical
- Namespace workflow instructions into git/ subdirectory with updated wfi:// URIs

## [0.10.13] - 2026-02-17

### Added

- `dirty_file_count` method to RepoStatus for counting uncommitted files from git status output
- `dirty_files` key in RepoStatus#to_h for downstream consumers

## [0.10.12] - 2026-02-17

### Fixed

- `fetch_pr_data_parallel` now matches PRs in any state (OPEN, MERGED, CLOSED) for the current branch, preferring OPEN over MERGED over CLOSED, so branches with merged PRs show PR metadata in status views

## [0.10.11] - 2026-02-04

### Changed
- Add scope determination guidance to reorganize-commits workflow for handling user-provided vs embedded status scope

## [0.10.10] - 2026-02-01

### Changed
- Use progressive retry delays (1s, 2s, 3s, 4s) for lock handling instead of fixed 500ms
- Lower stale lock threshold from 60s to 10s for faster orphan detection
- Always show lock wait messages (not just in debug mode)

## [0.10.9] - 2026-01-31

### Fixed
- `load_for_pr` no longer fetches unnecessary PR activity (saves ~1s per call)

### Technical
- Add missing stubs for `fetch_recently_merged`/`fetch_open_prs` in test helper (2.3s → 16ms)

## [0.10.8] - 2026-01-31

### Technical
- Stub Kernel.sleep in lock retry tests for 98% speedup (2.5s → 32ms)

## [0.10.7] - 2026-01-30

### Changed
- Simplify rebase workflow from 677 to 373 lines (45% reduction)

## [0.10.6] - 2026-01-30

### Added
- Improve rebase workflow with state capture and verification

### Technical
- Apply review feedback to rebase workflow documentation
- Clarify ace-git-commit usage for automatic scope grouping

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

[0.1.0]: https://github.com/cs3b/ace/releases/tag/ace-git-v0.1.0


## [0.10.16] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
