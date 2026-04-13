# Changelog

All notable changes to `ace-hitl` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- **ace-hitl v0.8.7**: Published handbook and HITL migration release changes for HitL package.


## [0.8.6] - 2026-04-11

### Technical

- Updated the CLI contract test assertion to `0.8.6` so it matches the current released line.

## [0.8.5] - 2026-04-11

### Technical

- Updated the CLI contract test version assertion to match the `Ace::Hitl::VERSION` release line (`0.8.5`) after fit-cycle feedback fixes.

## [0.8.4] - 2026-04-11

### Technical

- Updated the CLI contract test to assert `Ace::Hitl::VERSION` (`0.8.4`) after the follow-up review-cycle patch release.

## [0.8.3] - 2026-04-11

### Technical

- Updated the CLI contract test to assert the current released package version after the 0.8.2 batch migration release.

## [0.8.2] - 2026-04-11

### Technical

- Migrated deterministic CLI test coverage to `test/fast/commands/` for fast-only package alignment.
- Updated package docs and demo test references to document and use the fast-only test contract.

## [0.8.1] - 2026-04-05

### Changed

- Expanded package description wording to use the explicit "human in the loop (HITL)" phrase.

## [0.8.0] - 2026-04-02

### Changed

- Changed `ace-hitl list` default status behavior to include all statuses in the selected folder scope when `--status` is omitted (instead of implicitly filtering to `pending`).
- Updated list row rendering to task-like compact output with leading status icons for each HITL event.

### Technical

- Updated list command/docs/workflow wording and command-level tests to reflect explicit pending filtering (`--status pending`) and icon-led row assertions.

## [0.7.0] - 2026-04-02

### Changed

- Renamed the canonical HITL object terminology from "item" to "event" across CLI help/output, package docs, and workflow instructions.
- Performed immediate API/contract cutover for `HitlManager` resolution payloads from `:item` to `:event`.

### Added

- Added a list-output stats footer (`HITL Events: ...`) for `ace-hitl list`, including empty-result output and filtered `X of Y` summaries.
- Added explicit lifecycle event naming contract documentation under the `hitl.event.*` namespace.

## [0.6.0] - 2026-04-02

### Changed

- Switched the default HITL runtime root from `.ace-hitl` to `.ace-local/hitl` to align with ACE local-artifact layout conventions.

### Technical

- Updated scope and status test fixtures that embedded legacy `.ace-hitl` paths to use `.ace-local/hitl`.

## [0.5.0] - 2026-04-02

### Added

- Added `ace-hitl wait <id>` polling support with per-event lease metadata (`waiter_*`) so agents wait only on their own HITL question IDs by default.
- Added requester session metadata capture (`requester_provider`, `requester_model`, `requester_session_id`) from assignment session traces during HITL creation.
- Added resume fallback dispatch plumbing for answered items through provider session resume and command fallback paths.

### Changed

- Extended `ace-hitl update` with `--resume` to dispatch answer handoff only when no active waiter lease is detected.
- Updated HITL workflow and usage docs to make polling the default reliability path and resume dispatch the explicit fallback path.

### Technical

- Added CLI/manager regression coverage for wait timeout/success paths and resume dispatch skip/dispatch behavior.

## [0.4.3] - 2026-04-02

### Changed

- Switched `ace-hitl` configuration loading to ACE shared namespace resolution (`Ace::Support::Config`), with defaults fallback behavior for resilience.
- Added a package-owned `handbook/` skeleton (`agents/`, `guides/`, `skills/`, `templates/`, `workflow-instructions/`) for architectural consistency.

### Fixed

- Collapsed combined `ace-hitl update` metadata and answer mutations into one locked read/mutate/write cycle to avoid double write passes.

### Technical

- Added `ace-support-config` as a runtime dependency in `ace-hitl.gemspec`.

## [0.4.2] - 2026-04-01

### Fixed

- Made `ace-hitl update` honor scoped multi-worktree resolution semantics (`--scope`) consistent with `show`.
- Prevented duplicate HITL IDs during rapid event creation by regenerating IDs when collisions are detected.
- Narrowed loader exception handling so programming errors surface instead of being silently treated as not-found.

### Technical

- Added CLI regression coverage for scoped `update` behavior and ID collision avoidance.

## [0.4.1] - 2026-04-01

### Technical

- Updated CLI version contract tests to assert the current `Ace::Hitl::VERSION` (`0.4.0`) after the 0.4.0 release line.

## [0.4.0] - 2026-04-01

### Added

- Added smart multi-worktree scope resolution for `ace-hitl list` and `ace-hitl show` with explicit `--scope current|all`.
- Added context-aware default scope behavior: linked worktrees default to current scope, main checkout defaults to all-scope operator view.
- Added strict all-scope ambiguity handling for `show` with candidate path reporting.

### Changed

- Changed `ace-hitl list` default behavior to show only `pending` items when `--status` is omitted.
- Changed `ace-hitl show` to perform local-first lookup with implicit all-scope fallback only when scope is not explicitly provided.
- Changed show output to include explicit resolved-location details for cross-worktree item resolution.
- Updated usage and README documentation to describe local-first HITL semantics versus global `ace-overseer` dashboard usage.

## [0.3.0] - 2026-04-01

### Added

- Implemented full HITL event store behavior with package-owned model/molecules/manager flow.
- Added complete CLI behavior for `create`, `list`, `show`, and `update` with filtering and mutation options.
- Added usage documentation for end-to-end item management flows.

### Fixed

- Corrected answer section updates to handle empty `## Answer` blocks and persist answer text reliably.
- Updated CLI tests to align with current package version and answer-write behavior.

## [0.2.0] - 2026-04-01

### Added

- Initial package skeleton for `ace-hitl`.
- Root and package executables (`bin/ace-hitl`, `ace-hitl/exe/ace-hitl`).
- Minimal CLI registry for `list`, `show`, `create`, and `update`.
- Baseline docs and config scaffold.
