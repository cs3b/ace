# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
