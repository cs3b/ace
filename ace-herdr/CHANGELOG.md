# Changelog

All notable changes to `ace-herdr` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.11.2.pre.1] - 2026-11-12

### Changed

- Pin native handoff schema 2 retaining terminal IDs and guarded process handles with close-on-exec descriptors.
- Local UTM acceptance candidate; publication is not part of this run.


## [0.11.1] - 2026-11-12

### Fixed

- Preserve child session, remote and help arguments when launching with an explicit environment.

## [0.11.0] - 2026-11-11

### Added

- Add ace-herdr start using native configuration; apply configured binary, socket, native config and toolchain consistently to startup and agent dispatch, including managed Pi extensions.

## [0.10.0] - 2026-11-10

### Added

- Launch ordinary agents with an explicit private JSON environment file, without exposing credentials in terminal commands. Preserve real pane/session identity and refuse cold auto-resume without the original environment. Retain protected installed extensions and package reproducible native source builds for Linux ARM64, including cross-building on macOS.

## [0.9.0] - 2026-10-30

### Changed

- `HerdrExecutor#agent_start` accepts harness passthrough `args:` forwarded
  after `--` (model/thinking/standing-instruction flags), used by
  `ace-overseer start` (8xs.t.pu0.1).

## [0.8.1] - 2026-10-20

### Fixed
- Honor `ACE_TOOLCHAIN=installed` for published-gem execution and context propagation without source-runtime fallback; retain default auto development behavior.


## [0.8.0] - 2026-10-20

### Added
- Documented the L7.3 report-delivery surface to a pi overseer (task
  8xg.t.sbz.6.2) in `docs/usage.md`: pane push via `ace-herdr deliver`
  (idempotent per event id, concurrent deliveries prompt once) and the
  provider-native pi queue client (`ACE_HERDR_PI_QUEUE_CLIENT`), with the
  single-execution guarantee — a delivery during an active overseer turn
  joins the one session run and never starts a second overseer.

### Changed

- `ace-herdr status` refined to the reviewed `l7-statuses` implementation
  (task 8xg.t.sbz.6.0; extracted from the superseded PR #382): composition
  moved into a `StatusComposer` molecule, new `--workspace <id>` scoping,
  counts recomputed from the nesting with panes referencing vanished
  tabs/workspaces kept visible in a synthetic `(unlinked)` group, and a
  live-but-empty layout printing `No live herdr workspaces.` (exit 0) while
  an unreachable runtime stays an actionable non-zero error.

