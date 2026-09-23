# Changelog

All notable changes to `ace-hitl` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.9.0] - 2026-09-23

### Added
- **`ace-hitl ask`**: requester-side effect-callback API. Creates the local HITL event, binds it to a Lab HITL request via `--ace-hitl-id`, and passes effect declarations (`--effect-match`, `--effect-arg`, `--effect-cwd`, `--effect-timeout-s`) through verbatim after client-side bounds mirroring (match <= 200 chars and compilable; argv 1..16 x 1..512 chars using the lab's strip-then-bounds check so whitespace-only elements fail fast, valid values pass through verbatim; at least one element when any effect flag is present; cwd absolute and existing; timeout 1..600). Prints both the event id and the Lab request id, records `lab_request_effect: declared|none` on the event, and — when the Lab submit fails after the event was created — surfaces the orphan event id in the error.
- **`ace-hitl wait` Lab awareness**: while waiting on the event answer, the waiter also observes the Lab request public projection (`/run/lab/hitl/public/<id>.json`, overridable via `ACE_HITL_LAB_PUBLIC_DIR`) across BOTH schema fields — the lifecycle `state` (created / answer-delivered / consumed / cancelled) and the separate `effect_state` (callback-pending-with-answer / callback-ok / callback-escalated). Terminal semantics are effect-aware: requests without a declared effect terminate on lifecycle states; effect-declaring requests keep waiting until the callback verdict appears instead of ending at answer delivery, and `callback-escalated` output points at `lab-hitl duty`. The event's `lab_request_state` records the effective state and never claims plain `answer-delivered` while an effect outcome exists. Relay consumption stays the agent's choice (`lab-hitl consume`).


## [0.8.10] - 2026-09-02

### Technical
- Included in the coordinated all-package patch release preparation for ACE monorepo review.
## [0.8.9] - 2026-08-12

### Technical
- Raised the `ace-support-core` dependency floor to `~> 0.31` after the principles-first bootstrap guidance release.
## [0.8.8] - 2026-08-12

### Technical
- Aligned gemspec dependency floors with current ACE package minor release lines and safe external minor dependency bumps (no major version jumps).

## [0.8.7] - 2026-04-13

### Changed
- **ace-hitl v0.8.7**: Published handbook and HITL migration release changes for HitL package.



### Technical
- Replaced the CLI library-contract version assertion with a semantic-version schema check so the fast test validates version shape instead of a pinned release line.
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
