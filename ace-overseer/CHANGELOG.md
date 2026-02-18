# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
