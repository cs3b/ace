# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
## [0.12.1] - 2026-04-13

### Changed
- Completed the batch i05 migration follow-through for this package and aligned it with the restarted `fast` / `feat` / `e2e` verification model.

### Technical
- Included in the coordinated assignment-driven patch release for batch i05 package updates.


## [0.12.0] - 2026-04-12

### Changed
- Migrated deterministic tests to the restarted layout under `test/fast/` and updated E2E scenario metadata to reference the new deterministic paths.
- Added explicit package testing contract guidance for `ace-test ace-tmux`, `ace-test ace-tmux feat`, `ace-test ace-tmux all`, and `ace-test-e2e ace-tmux` in README and docs.

## [0.11.3] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.


## [0.11.2] - 2026-03-29

### Fixed
- **ace-tmux v0.11.2**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.11.1] - 2026-03-24

### Fixed
- Fixed `ace-tmux window` to rescue `Ace::Tmux::NotInTmuxError` instead of `Organisms::NotInTmuxError`.

## [0.11.0] - 2026-03-24

### Changed
- Removed demo GIF from README to streamline the landing page.

## [0.10.2] - 2026-03-23

### Changed
- Refreshed package README layout, quick-link navigation, and section flow to align with the current package pattern.

## [0.10.1] - 2026-03-22

### Changed
- Renamed overseer work-on pane/window presets from `work-on-tasks*` to `work-on-task*` for canonical preset naming consistency.

## [0.10.0] - 2026-03-22

### Added
- Added `work-on-tasks` pane and window presets for overseer-driven work-on workflows.

## [0.9.2] - 2026-03-22

### Fixed
- Restore YAML composition examples for pane and window preset reuse in usage docs.

## [0.9.1] - 2026-03-22

### Fixed
- Include `docs/**/*` in gemspec so documentation ships with the gem.
- Fix VHS tape output path to `docs/demo/` instead of `.ace-local/demo/`.
- Clarify `on_project_exit` as reserved/not-yet-implemented in usage docs.

## [0.9.0] - 2026-03-22

### Added
- Reworked package documentation with a new landing-page README, tutorial getting-started guide, full usage reference, handbook catalog, demo assets, and aligned gem metadata messaging.

## [0.8.0] - 2026-03-21

### Changed
- Expanded `TS-TMUX-001` E2E lifecycle coverage with a new window-management goal and tightened artifact-evidence contracts for preset discovery and session start flows.

## [0.7.1] - 2026-03-18

### Changed
- Migrated CLI namespace from `Ace::Core::CLI::*` to `Ace::Support::Cli::*` (ace-support-cli is now the canonical home for CLI infrastructure).


## [0.7.0] - 2026-03-18

### Changed
- Removed legacy backward-compatibility behavior as part of the 0.10 cleanup release.


## [0.6.3] - 2026-03-17

### Fixed
- Updated CLI help-output assertions to match `ace-support-cli` output casing (`COMMANDS`/`EXAMPLES`).

## [0.6.2] - 2026-03-15

### Changed
- Migrated CLI framework from dry-cli to ace-support-cli

## [0.6.1] - 2026-02-23

### Changed
- Centralized error class hierarchy: PresetNotFoundError and NotInTmuxError now inherit from Ace::Tmux::Error

### Technical
- Updated internal dependency version constraints to current releases

## [0.6.0] - 2026-02-22

### Changed

- **Breaking**: Removed DWIM context-aware default routing
  - `ace-tmux` (no args) now shows help instead of routing to `start`/`window` based on TMUX env
  - Users must now use explicit commands: `ace-tmux start`, `ace-tmux window`, `ace-tmux list`
  - Unknown first arguments are no longer prepended with default command
- Migrated to standard help pattern (ADR-023)
  - Added `HELP_EXAMPLES` constant with usage examples
  - Registered `HelpCommand` for `help`, `--help`, `-h`
  - Updated `REGISTERED_COMMANDS` to include descriptions

### Technical

- Updated CLI tests to test standard help pattern instead of DWIM routing

## [0.5.5] - 2026-02-20

### Fixed
- `WindowManager#detect_current_session` now checks `ACE_TMUX_SESSION` env var first, enabling E2E test isolation without requiring an active tmux session

## [0.5.4] - 2026-02-19

### Fixed

- Fix "index N in use" error when creating tmux windows in sessions with `base-index` set

## [0.5.3] - 2026-02-19

### Fixed

- Include stderr details in "Failed to create window" error message for better debugging

## [0.5.2] - 2026-02-14

### Fixed

- First window name now always derives from the effective working directory (`--root` override > preset `root:` > CWD), matching the existing behavior of `ace-tmux window --root`

## [0.5.1] - 2026-02-14

### Fixed

- Bundler/Ruby environment variables (`BUNDLE_GEMFILE`, `BUNDLE_BIN_PATH`, `RUBYOPT`, `RUBYLIB`) no longer leak into tmux sessions and spawned processes
  - `bin/ace-tmux` cleans env vars from its own process after Bundler setup
  - `SessionManager` unsets env vars from the tmux session environment via `set-environment -u`
  - New `TmuxCommandBuilder.set_environment` atom for `tmux set-environment` commands

## [0.5.0] - 2026-02-14

### Changed

- **Breaking**: Gem renamed from `ace-support-tmux` to `ace-tmux` (task 266)
  - Namespace changed from `Ace::Support::Tmux` to `Ace::Tmux`
  - Require path changed from `ace/support/tmux` to `ace/tmux`
  - Binary name (`ace-tmux`) and config path (`.ace/tmux/`) unchanged
  - No backward compatibility shims provided (per ADR-024)

## [0.4.1] - 2026-02-14

### Fixed

- `ace-tmux --root /path` inside tmux now adds a window instead of erroring with "sessions should be nested" — unknown-arg routing is now context-aware

## [0.4.0] - 2026-02-14

### Added

- Context-aware default presets — `ace-tmux` with no arguments starts default session (outside tmux) or adds default window (inside tmux)
- `defaults` config section in `config.yml` with `session` and `window` default preset names
- `--root`/`-r` option on `start` command for working directory override (parity with `window` command)
- `inside_tmux?` detection method on CLI for context-aware routing

### Changed

- `preset` argument is now optional on both `start` and `window` commands — falls back to configured defaults

## [0.3.4] - 2026-02-13

### Fixed

- Session creation failing with `base-index 1` tmux config by using window IDs instead of index-based targeting

## [0.3.3] - 2026-02-13

### Fixed

- Window targeting uses unique window ID (`@42` format) instead of name-based resolution, eliminating "can't find window" errors when duplicate names exist
- Window name derived from `--root` basename instead of preset's `name` field — `ace-tmux window cc --root /path/to/project` names the window `project`

### Added

- `--name`/`-n` flag on `ace-tmux window` for explicit window name override (priority: `--name` > `--root` basename > preset argument)

### Changed

- Removed `name: cc` from cc.yml window preset — presets define layout, not window names

## [0.3.2] - 2026-02-13

### Fixed

- Pane startup race condition — `send-keys` commands now execute after `select-layout`, preventing resize artifacts in apps like nvim/LazyVim

### Changed

- Restored per-pane `sleep 0.15` in claude and nvim pane presets — shell-side sleep absorbs async resize signals that Ruby-side delay cannot

## [0.3.1] - 2026-02-13

### Fixed

- Per-leaf pane `root` overrides now apply in nested layouts — previously all nested panes used the window/session root
- `LayoutStringBuilder` pane ID assignment falls back to sequential index when `pane_ids` array is shorter than expected

## [0.3.0] - 2026-02-12

### Added

- Nested pane layouts with arbitrary tree structure via `direction` key in YAML presets
- `LayoutNode` model — tree node (leaf or container) for nested layout representation
- `LayoutStringBuilder` atom — pure function that generates tmux custom layout strings with CRC16 checksum from a `LayoutNode` tree
- `list_panes` and `display_message_target` commands in `TmuxCommandBuilder`
- `layout_tree` attribute and `nested_layout?` predicate on `Window` model
- Recursive preset resolution for nested containers in `PresetResolver`
- Nested pane setup flow in `SessionManager` and `WindowManager` — flat splits → list-panes → layout string → select-layout

## [0.2.0] - 2026-02-12

### Added

- Generic `options` hash on Window and Pane models — pass-through for any tmux option via `set-window-option` and `set-option -p`
- `--root`/`-r` flag on `ace-tmux window` command to set working directory for the new window and all its panes
- `set_window_option` and `set_pane_option` commands in TmuxCommandBuilder

### Changed

- Default session preset: 3-pane layout (claude left 40%, shell right-top, nvim right-bottom) with `main-vertical` layout and `main-pane-width` option
- Code-editor window preset: 3 equal vertical panes (claude | shell | nvim) with `even-horizontal` layout

## [0.1.0] - 2026-02-12

### Added

- Initial release of ace-support-tmux
- Composable tmux session management via YAML presets
- Deep-merge composition at session, window, and pane levels
- `ace-tmux start <session-preset>` — Create tmux session from YAML preset
- `ace-tmux window <window-preset>` — Add window to existing session from preset
- `ace-tmux list [sessions|windows|panes]` — List available presets
- ACE config cascade integration (project > user > gem defaults)
- tmuxinator-compatible YAML keys


## [0.5.6] - 2026-02-22

### Fixed
- Standardized quiet, verbose, debug option descriptions to canonical strings
