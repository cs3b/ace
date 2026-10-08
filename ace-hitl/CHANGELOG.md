# Changelog

All notable changes to `ace-hitl` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.13.0] - 2026-10-08

### Added

- Bind scoped publication to the original canonical HITL challenge and authorization; keep OTP material out of agent messages and ordinary transport.

### Changed

- Read delivery history from the original Inbox owner. Complete human attention on terminal submission without requiring an agent-read receipt or querying recovery caches.

### Fixed

- Route proposals through the retained project journal and preserve exact protected attempt identity across lifecycle calls.
- Exercise concurrent creation under the actual lifecycle lock.

### Fixed

- Accept exact protected launch attempt identifiers for HITL requests while preserving assignment syntax and authoritative binding checks.

## [0.12.0] - 2026-10-05

### Added

- Add an opt-in installed proposal scenario with an isolated local gem closure, real Unix and tmux owner binding, controlled sixteen-hour restart, technical refusal, and one verified service effect/receipt.
- Resolve immutable second-commander proposals through confirmed-delivery sixteen-hour policy and canonical Assign authorization.

### Changed

- Declare the required direct dependencies and minimum producer versions for this coordinated release: `ace-assign ~> 0.64`, `ace-herdr ~> 0.4`, `ace-hitl-contract ~> 0.2`.

- Replace daemon/Work bindings with the managed assignment envelope and kernel-attributed exact native reverse owner. Add explicit in-process delivery/watch, authenticated pane-less wait, visible pending recovery, and existing signed Inbox reconciliation; keep native transport and business effect receipts separate.

### Fixed

- Recover revision operations by explicit source revision and stable operation identity without resetting delivery; require current project authority for proposal reads, refuse generic proposal creation, and preserve ordinary question character limits.

- Recover stable-ID proposal creation from canonical prepared requests, retain exact reply deduplication across retry ordering, and queue proposer reconciliation wakes for the existing transport actor.
- Bound pending IPC pages by encoded frame size while retaining all native recovery claims and project authorization; Ruby callers traverse keyset pages.
- Preserve the accepted native incarnation through answer consumption and require explicit signed-supersession retry before another submission.

## [0.11.1] - 2026-10-04

### Fixed
- Enforce the persisted OTP challenge deadline at locked consumption, including vault reads that cross expiry. Expired secrets are discarded without a success receipt; memory retention is bounded by both vault TTL and challenge expiry.

- Preserve the authenticated service endpoint when another HITL startup is refused. Serialize listener ownership and remove only the socket acquired by the stopping invocation; stale recovery requires a protected service-owned socket.

### Changed

- Load shared provider references, results, and errors from `ace-hitl-contract`; retain provider registration and locked assignment authority in HITL.

## [0.11.0] - 2026-10-04

### Added
- **Scoped privilege boundary for multi-user HITL state (spec 8wq.t.34i)**: the lifecycle store is now the PRIVATE state of one authenticated boundary service. `ace-hitl serve` runs the boundary over a peer-credential-authenticated UNIX socket (`Ace::Hitl::Lifecycle::Service`): every connection is identified from kernel peer credentials (`getpeereid` — payload fields and environment variables are never authority), clients authenticate the endpoint back (socket must be owned by the trusted service uid from the grants document, not world-writable, connected peer must BE the service uid), and the store root is service-owned (`0711` traverse-only root, `0700` private directories, `0755` public projections with `0440` non-secret records — no chmod-to-world workaround anywhere). Bounded newline-JSON protocol (`Lifecycle::Protocol`) with classified errors: `PermissionError`, `BindingError`, `StateError`, `AnswerError`, and the new `TransportError` for boundary unavailability — transport failures are visible and recoverable, never silent.
- **Managed assignment binding**: requests bind to the exact ACTIVE MANAGED attempt of the calling actor through the ace-assign coordinator (`Providers::Lab::AssignmentBinding`). `ace-assign` gained `AttemptCoordinator#with_verified_attempt`, which holds the assignment `LifecycleExclusion` (shared side) across the caller's whole locked transition while `finish`/`reconcile` hold the exclusive side — stale, ended, replaced, or unproven (uncertain) attempts cannot acquire authority, and terminal commits can never interleave with a liveness check. CLI: `ace-hitl ask --assignment ID --attempt ID --project ID`.
- **Transport authorization from trusted grants** (`Lifecycle::GrantsPolicy` + `TrustedFile`): transport uids and the service identity come only from the deployment-owned grants document (same file and traversal trust rules as ace-lab's `GrantResolver`: root-owned, no group/world-writable components, symlink-verified). ace-lab ships the matching `Molecules::HitlAuthorizer` for the lab-side delivery path.
- **Idempotent terminal receipts**: every consume/cancel commits a durable receipt under the stable per-request lock (lock files live in `locks/` and survive id reuse); retries report the committed outcome instead of failing, conflicting transitions stay classified errors.
- **OTP exact-operation challenges**: an `otp` request exists only with its non-secret publisher evidence (`{operation, result_ref, input_digest, expires_at}`, bounded to 24h); consumption requires the challenge's authorized operation; duplicate consumes replay the receipt WITHOUT the secret bytes. OTP effects are forbidden (the authorized operation consumes the OTP transiently). The service holds OTP bytes in a bounded, TTL-bound memory vault (`OtpVault::MemoryVault`) — secret bytes persist nowhere, transfer exactly once, and a restart deliberately loses the challenge (prompt again).

### Changed
- **Hardened privileged lifecycle boundary handling**: boundary-facing provider flows no longer trust ambient test fixtures and the lab-side authorizer validates the same privileged transition rules the service enforces.
- **BREAKING (pre-1.0, ADR-024)**: `ace-hitl ask/deliver/consume/cancel/pending/states/duty` run through the boundary client — the CLI no longer touches shared store files directly, and broker operations no longer require root (the configured transport identity from the grants document does). The admin binding bypass is removed: EVERY request validates against its live attempt. The `LAB_ATTEMPT_ID` environment default is gone (environment is never attempt authority); `--attempt` is required, and binding requires `--assignment` (managed) or `--work` (legacy path, kept until vs2 switches consumers). Answers and store files are service-owned `0600` — requesters receive bytes over the authenticated boundary, not through file ownership. The multi-UID acceptance fixture (`test/edge/lifecycle/`) proves requester isolation, protected ownership, forged-identity rejection, and one-terminal-transition races under real distinct OS accounts (requires root; CI records the run as advisory evidence).


## [0.10.0] - 2026-09-27

### Added
- **Generic HITL request lifecycle (spec 8wm.t.y21, M1 migration from lab-config lab-hitl)**: the generic core now lives natively in the gem under `Ace::Hitl::Lifecycle` — request store (`create`/`pending`/`states`/`deliver`/`consume`/`cancel`), kinds + OTP/secret-shape answer gates, 0400 requester-owned answer relay, 0440 merge-on-write public projection under a per-request `flock`, no time-based expiry (W651: only an answer, its consumption, or an explicit audited `cancel` ends a request), requester-declared effect callbacks executed AS THE REQUESTER (exec-argv with `{answer}`, fullmatch regex gate, bounded timeout, redacted root-only effects log, deduped escalation with `callback-ok`/`callback-escalated` projection states and the pending+escalated duty projection), and the Overseer reverse-address surface (`overseer-send`/`overseer-pending`/`overseer-ack`: bounded, type-tagged `[decyzja]`/`[pytanie]`/`[info]`, no SHA/Work/Attempt/task IDs). New CLI commands: `deliver`, `consume`, `cancel`, `pending`, `states`, `duty`, `overseer-send`, `overseer-pending`, `overseer-ack` (machine output: one JSON line). Store root: `ACE_HITL_STORE_ROOT` (default `/run/lab/hitl`); Overseer channel root: `ACE_HITL_OVERSEER_CHANNEL_ROOT` (default `/lab/state/overseer-channel`).
- **Binding policy seam**: the generic store requires a fail-closed `Lifecycle::Binding` policy; provider=lab supplies `Providers::Lab::DaemonBinding`, the minimal client of the lab daemon's read-only `hitl_binding` socket op (Work/Attempt binding authority stays lab-side, per audit 8wl.t.gad.6). Escalation spooling stays behind the store's `escalation_sink` seam (the wake/`lab_control` glue stays lab-config).
- **Provider adapter interface + provider=lab contract (spec 8wm.t.vrz)**: `ace-hitl ask` dispatches through the `Ace::Hitl::Providers` registry (selection: `--provider` flag → `ACE_HITL_PROVIDER` env → `lab`). The ask performs the local-event + transport send in ONE operation and captures the asker's reverse address fail-closed from the herdr environment (`HERDR_SESSION` / `HERDR_PANE`; versioned schema `ace.hitl.ref/v1`), persisting `provider`, `ref_schema`, `ref_session`, `ref_pane` alongside the existing `lab_request_*` fields. Pinned error model: `UnknownProviderError`, `InvalidRefError` (fail closed before any event or transport state), `ProviderUnavailableError` (transport failure; orphan event id message preserved), `UnsupportedOperationError` (`deliver(ref, answer)` lands with ace-herdr push delivery 8wm.t.vs0 + provider=lab integration 8wm.t.vs2; `wait` remains the pane-less CLI path outside the adapter).

### Changed
- **provider=lab `ask` creates the relay request through the native lifecycle store** (binding + effect declared in-process). The external-binary transport `Providers::Lab::Transport` is DELETED (pre-1.0; supersedes the 8wm.t.vrz §7 re-homing); the orphan-event `ProviderUnavailableError` contract is preserved. File and record formats stay byte-compatible with the deployed lab consumers.
- **Zero-lab-hitl guard**: the legacy `Molecules::LabRequestSubmitter` was deleted and re-homed (same behavior, provider error model) as `Providers::Lab::Transport`, the sole owner of the lab transport binary reference. A fast guard test keeps every agent-facing ace-hitl path free of direct lab transport references, and agent-facing ask/wait output no longer names the relay binary.

### Removed
- `Providers::Lab::Transport` and the `ACE_HITL_LAB_BIN` selection: the relay request path no longer shells out to an external binary.

### Fixed
- **PR#336 review hardening (codex astra high)**: unique atomic-writer temporary files so competing writers can no longer delete each other's in-flight temp (store answer relay included); delivery and cancel re-validate the request incarnation and ownership under the per-request lock (a cancel+recreate of the same id can no longer redirect an answer into the new incarnation); the first projection is initialized inside the lifecycle lock behind a per-incarnation token so a broker delivery can never be regressed to `created`; effect callbacks spawn with forced exec/argv semantics (a single-element declaration can no longer reach a shell) as process group leaders whose whole group is terminated on timeout; `{answer}` substitution is literal (block-form `gsub`, no replacement-string backreferences); answer bounds are enforced on decoded UTF-8 characters with a separate byte bound, so valid multibyte answers through real IO are accepted.

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
