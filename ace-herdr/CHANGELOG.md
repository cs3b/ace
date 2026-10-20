# Changelog

All notable changes to `ace-herdr` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]


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

