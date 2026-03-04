# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.19] - 2026-03-04

### Changed
- Assignment launcher temporary job files now use `.ace-local/overseer`.


## [0.4.18] - 2026-03-03

### Added
- `StatusCollector`: show non-task worktrees in status when they have active assignments
- `WorktreeContextCollector`: support B36TS task ID extraction from worktree paths and branch names

### Fixed
- `PruneOrchestrator`: allow pruning non-task worktrees when targeted by path (removes `task_associated` filter)

## [0.4.17] - 2026-03-02

### Changed
- Replace `ace-taskflow` dependency with `ace-task` — migrate `WorkOnOrchestrator` and `PruneSafetyChecker` to use `Ace::Task::Organisms::TaskManager` API
- Remove bare `require "ace/taskflow"` import, add `require "ace/task"`

## [0.4.16] - 2026-02-26

### Fixed
- Fix repeated `--task` flags (`--task 288 --task 287`) being silently dropped by dry-cli; values are now coalesced before parsing

## [0.4.15] - 2026-02-26

### Fixed
- Raise descriptive error when no valid task references are provided to `WorkOnOrchestrator`, preventing `NoMethodError` on empty input.

## [0.4.14] - 2026-02-26

### Added
- Support ordered multi-task input for `ace-overseer work-on --task` using repeated flags, comma-separated values, or mixed forms.
- Add explicit `task_refs` launch parameter support in `AssignmentLauncher` for multi-task presets using `taskrefs`.

### Fixed
- Validate all provided task references before worktree/tmux/assignment side effects.
- Fail early with actionable guidance when multiple task refs are provided to a single-task (`taskref`) preset.

### Changed
- Preserve left-to-right task execution order while expanding orchestrator refs in-place to subtask sequences.

## [0.4.13] - 2026-02-24

### Fixed
- Isolate `TS-OVERSEER-001` E2E tmux execution per run by switching scenario setup to `tmux-session: { name-source: run-id }`, preventing cross-run/default-session collisions.

### Changed
- Clarify runner guidance for tmux evidence collection to always target `ACE_TMUX_SESSION` explicitly.

## [0.4.12] - 2026-02-24

### Changed
- Refine `TS-OVERSEER-001` TC-005 prune workflow runner instructions to explicitly resolve task.001 worktree path and execute `ace-assign` steps from that worktree while writing artifacts to the sandbox `results/` tree.

## [0.4.11] - 2026-02-24

### Changed
- Update `TS-OVERSEER-001` TC-005 prune workflow instructions to require explicit assignment-completion evidence and post-prune verification artifacts.

## [0.4.10] - 2026-02-23

### Technical
- Updated internal dependency version constraints to current releases

## [0.4.9] - 2026-02-22

### Changed
- Migrate CLI to standard dry-cli help pattern with HelpCommand registration
- Remove custom `start()` method and `KNOWN_COMMANDS` constant in favor of standard pattern

## [0.4.8] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings

## [0.4.7] - 2026-02-22

### Changed
- Migrate skill naming and invocation references to hyphenated `ace-*` format (no underscores).

## [0.4.6] - 2026-02-21

### Fixed
- Fix TC-003 tmux window verification to use `tmux list-windows -a` (all sessions) to avoid env var propagation issues in E2E test agents

## [0.4.5] - 2026-02-21

### Fixed
- Fix `WorkOnOrchestrator` to pass `task_root_path` (resolved from `PROJECT_ROOT_PATH` env var or `Dir.pwd`) to `TaskLoader`, ensuring tasks are found correctly in worktree environments
- Fix E2E tests to use `ACE_TMUX_SESSION` variable instead of hardcoded `ace-e2e-test` session name for tmux window verification

## [0.4.4] - 2026-02-20

### Fixed
- E2E scenarios (TS-OVERSEER-001, TS-OVERSEER-002) now use `tmux-session` setup step for isolated tmux sessions instead of leaking windows into the developer's active session
- Remove hardcoded `tmux kill-session -t "ace-e2e-test"` from TS-OVERSEER-002 setup that was polluting the developer environment

## [0.4.3] - 2026-02-19

### Fixed
- Prune orchestrator now passes `delete_branch: true` to worktree manager's `remove` call, ensuring git branches are cleaned up when worktrees are pruned

## [0.4.2] - 2026-02-19

### Added
- Orchestrator subtask expansion for `work-on-tasks` preset — when a task is an orchestrator with subtasks, `AssignmentLauncher` expands subtask refs into individual foreach phases (e.g., `work-on-272.01`, `work-on-272.02`) instead of a single `work-on-272` phase
- `extract_subtask_refs` helper in `WorkOnOrchestrator` to extract subtask numbers from orchestrator task data
- `subtask_refs:` keyword argument on `AssignmentLauncher#launch` for passing expanded subtask references

## [0.4.1] - 2026-02-19

### Added
- `--watch` / `-w` option for `status` command — auto-refreshing dashboard with ANSI screen clear
- Two-tier refresh: fast interval (15s default) refreshes assignment data only, slow interval (5min default) does full git/PR refresh
- `collect_assignments_only` method on `WorktreeContextCollector` for lightweight assignment-only collection with cached git data
- `collect_quick` method on `StatusCollector` to reuse previous snapshot's git data while refreshing assignments
- `format_watch_footer` on `StatusFormatter` showing dim timestamp and countdown to next full refresh
- Configurable watch intervals via `watch.refresh_interval` and `watch.git_refresh_interval` in overseer config

## [0.4.0] - 2026-02-19

### Added
- Progress bar visualization in assignment sub-rows — filled/empty bar segments alongside numeric counts
- Current phase name display for running assignments (e.g., `implement` shown dimmed after progress)
- Header row and separator line above hierarchical dashboard for column labeling
- Blank line separators between location groups for visual breathing room
- `current_phase` field propagated from `QueueState` through `WorktreeContextCollector` to status display

### Changed
- Widen progress column to accommodate progress bar and current phase text

## [0.3.1] - 2026-02-19

### Changed
- Hierarchical status display — location header rows with assignment sub-rows replace flat single-row format
- `WorkContext` model uses `assignments` array instead of singular `assignment_status` + `assignment_count`
- `WorktreeContextCollector` loads all assignments via `AssignmentDiscoverer` instead of only active via `AssignmentExecutor`
- `StatusFormatter` emits two row types: location header (basename + PR + Git) and indented assignment sub-rows (ID + name + state + progress)
- IPC serialization in `StatusCollector` uses `assignments` array
- Main branch inclusion check uses `assignments.any?` instead of `assignment_status`

### Removed
- `assignment_executor_factory` dependency from `WorktreeContextCollector`
- Flat single-row dashboard format with header/separator lines

## [0.3.0] - 2026-02-19

### Added
- Assignment-aware status display — main branch appears in `status` when it has active assignments
- Assignment count shown in Assign column when location has multiple assignments (e.g., `abc12 (3)`)
- `--assignment` / `-a` option for `prune` command to remove a specific assignment's cache directory
- `AssignmentPruneCandidate` model for assignment-level prune safety checking
- `AssignmentPruneSafetyChecker` molecule to evaluate assignment prune safety
- `AssignmentManager#delete` method in ace-assign for removing assignment cache and cleaning up symlinks
- `assignment_count` and `location_type` fields on `WorkContext` model

### Changed
- `StatusCollector` now collects main branch context alongside worktree contexts
- `StatusFormatter` sorts main branch row last, displays `main` in Task column with dim styling
- `WorktreeContextCollector` counts assignments per location via `AssignmentDiscoverer`
- `PruneOrchestrator` supports assignment-level pruning path with safety checks and force override
- Widened Assign column from 6 to 10 characters to accommodate count display
- IPC serialization includes `assignment_count` for parallel subprocess collection

## [0.2.17] - 2026-02-19

### Changed

- `TmuxWindowOpener` delegates entirely to `ace-tmux window` CLI — no longer manages session names, window names, or presets
- Remove `tmux_session_name`, `window_name_format`, and `window_preset` config options
- Remove `WindowNameFormatter` atom — window naming is ace-tmux's responsibility
- `PruneOrchestrator` uses worktree path basename for window cleanup instead of formatted names

## [0.2.16] - 2026-02-19

### Changed

- `TmuxWindowOpener` no longer manages tmux sessions — delegates entirely to ace-tmux `WindowManager` for window creation, session detection, and dedup

## [0.2.15] - 2026-02-19

### Fixed
- Task ID extraction now recognizes `ace-task.NNN` worktree paths, fixing mismatch where overseer status showed branch-derived task ID instead of the path-derived one

## [0.2.14] - 2026-02-19

### Added
- `--force` (`-f`) flag for `prune` command to bypass safety checks and force-remove unsafe worktrees
- Positional target arguments for `prune` to filter by task ref or folder name (e.g., `ace-overseer prune 230 265`)
- Dry-run output shows `[FORCE]` tag on forced candidates

## [0.2.13] - 2026-02-19

### Added
- Progress callbacks (`on_progress:`) for `work-on` and `prune` orchestrators — one-line status output per step
- Prune now displays safe/skipped candidates with reasons before the "Continue?" confirmation prompt

### Changed
- `work-on` command output replaced with real-time progress messages instead of post-hoc summary

## [0.2.12] - 2026-02-19

### Fixed
- Prune workflow now removes safe worktrees with `ignore_untracked: true`, allowing untracked-only trees to be pruned while still protecting tracked changes
- Tighten prune E2E assertions with task-specific grep patterns and aligned fixture/config expectations for TS-OVERSEER-002

## [0.2.11] - 2026-02-19

### Fixed
- Add `exit!(1)` safety net after `exec` in forked status worker to prevent child process leaking parent state if exec fails
- Filter nil contexts from failed parallel workers with `.compact` to prevent `NoMethodError` in dashboard formatting

## [0.2.10] - 2026-02-18

### Changed
- Right-size `ace-overseer` E2E coverage from 11 to 6 focused test cases by removing command error-path duplicates already covered in package tests.
- Consolidate prune workflow assertions so retained E2E cases validate dry-run no-side-effects and tmux cleanup in fewer scenarios.

### Fixed
- Reuse existing tmux windows in `work-on` to avoid duplicate task windows on idempotent reruns.
- Treat repositories with only untracked files as prune-safe when tracked changes are clean, preventing false `git not clean` outcomes.
- Return a user-friendly CLI error when `ace-overseer work-on` is invoked without `--task`.

### Added
- Add command tests for `work-on` missing `--task` and task-not-found error behavior.

## [0.2.9] - 2026-02-18

### Fixed
- Manage PROJECT_ROOT_PATH environment variable and clear ProjectRootFinder cache when switching worktree contexts to ensure ace-assign and other tools find correct configuration

### Technical
- Add comprehensive E2E test cases for overseer workflows
- Add E2E test configuration presets

## [0.2.8] - 2026-02-17

### Changed

- Parallelize worktree context collection using fork/exec for 3-4x speedup (5-7s → 1.5s for 6 worktrees)
- Use subprocess isolation to avoid Dir.chdir thread-safety issues

### Fixed

- Test expectation for status header ("ASSIGNMENTS" → "Assign")

## [0.2.7] - 2026-02-17

### Added

- Assign column showing compact assignment ID for quick reference
- Git dirty file count display (e.g., `✗ 3`) instead of just `✗`

### Changed

- Reorder columns: Assign first, Progress last
- Fix column alignment by pre-padding colored fields before ANSI codes
- Remove redundant "ASSIGNMENTS" title (table header is self-explanatory)

## [0.2.6] - 2026-02-17

### Changed

- Replace text status labels with Unicode icons and ANSI colors for compact, scannable output
- Sort dashboard rows by PR number descending; rows without PR appear first (sorted by task desc)
- Remove Path column (redundant with Task ID) to save horizontal space
- Colorize PR state (OPN green, MRG blue, CLS dim, DFT yellow) and Git state (✓/✗ with colors)

### Added

- Support for new `:stalled` assignment state icon (◼ yellow)

## [0.2.5] - 2026-02-17

### Fixed

- Set `PROJECT_ROOT_PATH` per worktree in context collector so each worktree resolves its own assignment cache directory instead of all sharing the invoking worktree's data
- Restore `PROJECT_ROOT_PATH` and clear `ProjectRootFinder` cache after collection to prevent cross-worktree contamination

## [0.2.4] - 2026-02-17

### Changed

- Replace release-centric status view with assignment-focused dashboard showing path, state, progress, and PR columns.
- Remove release resolver dependency from status collector.
- Add phase summary data (total/done/failed) to worktree context collection.
- Add PR metadata display with abbreviated state (OPN, MRG, CLS, DFT) in status output.

## [0.2.3] - 2026-02-17

### Changed

- Protect `gem_root` memoization with mutex synchronization.
- Use atomic tempfile writes for generated assignment job files.
- Improve task ID extraction robustness in worktree context collector.

## [0.2.2] - 2026-02-17

### Fixed

- Ensure `prune --quiet` still executes prune logic instead of returning early.
- Add missing runtime dependencies in gemspec for required ACE gems.
- Handle `SIGINT` in executable with exit code `130`.

### Changed

- Expand assignment preset lookup to include `.ace/assign/presets` before defaults.
- Use post-action wording in `work-on` command output for accurate UX timing.
- Improve prune task-done checks to account for repository common root context.

## [0.2.1] - 2026-02-17

### Changed

- Release patch after the valid review cycle with no additional code changes required.

## [0.2.0] - 2026-02-17

### Changed

- Promote the initial `ace-overseer` implementation set to a minor release.
- Align release metadata for assignment-driven delivery flow.

## [0.1.0] - 2026-02-17

### Added

- New `ace-overseer` gem scaffold, executable, and CLI registry.
- `work-on` command orchestration:
  - provision/reuse task worktree
  - open tmux window for task context
  - create assignment from configured preset
- `status` command with table and JSON output for active task worktrees.
- `prune` command with safety checks, dry-run mode, and confirmation flow.
- Core models:
  - `WorkContext`
  - `PruneCandidate`
- Core atoms:
  - `WindowNameFormatter`
  - `PresetResolver`
  - `StatusFormatter`
- Molecule layer:
  - `WorktreeProvisioner`
  - `TmuxWindowOpener`
  - `AssignmentLauncher`
  - `WorktreeContextCollector`
  - `PruneSafetyChecker`
- Organism layer:
  - `WorkOnOrchestrator`
  - `StatusCollector`
  - `PruneOrchestrator`
- Test coverage for atoms, models, molecules, organisms, and CLI command registration.
