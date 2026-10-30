# Changelog

All notable changes to `ace-hitl` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Case lifecycle (task 8xs.t.pu0.6): `ace-hitl apply CASE --ref OWNER_REF`
  records the applied effect with its owner reference (idempotent per
  reference, conflicting references rejected), `ace-hitl close CASE` is
  terminal only after the applied proof (duplicate no-op, closed cases never
  re-open), `cancel_case` terminates without application, and
  `ace-hitl sweep [--apply]` lists/removes ONLY the ask-wake request
  leftovers of terminally closed/cancelled cases — active cases, unknown
  ids and the canonical decision history are always preserved. Lifecycle
  state lives in the canonical case file (receipt pending/received,
  application pending/applied/closed/cancelled); transitions are locked and
  conflict-rejecting.

- `ace-hitl reply CASE_ID --stdin` (task 8xs.t.pu0.5): receiver-side answer
  delivery on the owner's machine. Output carries only the case and its state
  (`received`/`duplicate`); the reference must be the exact case id (no
  shortcut/latest resolution), identical redelivery is idempotent without a
  rewrite, a conflicting answer never overwrites the decision, and empty
  answers/reports/unknown references fail as explicit non-deliveries.

## [0.24.3] - 2026-10-29

### Fixed

- Answer and field-update rebuilds parse the case file strictly: an unparsable frontmatter block aborts the mutation instead of silently rebuilding the case from an empty frontmatter (HOTFIX cycle-2b follow-up to the 8xsdfo ask-flow corruption).

## [0.24.2] - 2026-10-27

### Added

- Add the one-turn `ask` command: create + send the question through the configured route, auto-arm the asking agent's own answer wake (ace.wake.ask/v1 request delivered through the ace-wake bridge), print the bare case id as the final stdout line, and end the turn — never block, never poll, no asker-side timeouts; undelivered routes exit 1 before any wake request is dropped, and `ask` completes on accepted-queued frames.

### Changed

- Formalize route recipients as first-class ordered data in the route loader.

## [0.24.1] - 2026-10-25

### Changed

- Replace wait-by-polling with the semantic wake contract in the HITL workflow (PR74): one scoped watch per pending answer, end the turn, reconcile on wake.

## [0.24.0] - 2026-10-23

### Added

- Add read-only semantic event observations with configured-owner filtering; exclude delivery metadata and unrelated recipients.

## [0.23.2] - 2026-10-20

### Fixed

- Select addressed-event routes by configured recipient names resolved to the
  exact stored address. Unrelated terminal/Telegram routes no longer send or
  create false delivery failures. Zero matches fail before adapter IO.
  **Configuration migration:** add `recipients: [name]` to each addressed route;
  names must exist in `hitl.recipients`. Recipient-less local events retain their
  explicitly configured route set.
- Accept native Herdr panel handles such as `w7:p1` without changing machine or
  folder validation.
- Provide first-answer-wins `HitlManager#accept_answer` for native transport
  imports; exact replays preserve bytes and conflicting answers cannot replace
  an existing answer under the case write lock.

## [0.23.1] - 2026-10-18

### Fixed

- Terminal routes are machine-scoped (round-9 review H1): the adapter now
  reads the route's `machine` (defaults to `hitl.machine`) and refuses a
  panel recipient on a different machine instead of delivering to a
  local pane that merely shares the panel name and reporting a false
  `delivered`. The refusal mirrors the hermes adapter, so both shipped
  adapters apply the same address check.

### Changed

- Docs only: `docs/usage.md` now documents that route delivery requires
  a panel-form recipient (folder-form recipients have no shipped delivery
  route and are refused per-route), the per-route refusal semantics of
  both shipped adapters, per-route `unavailable` retention for unknown
  adapters, dotted route-name rejection, and the absolute `reply_to`
  folder. `HitlConfigLoader.normalize` notes that mixing flat/shaped
  config documents across tiers can invert cascade precedence.

## [0.23.0] - 2026-10-18

### Fixed

- Adapters deliver to the event's recipient, not just the route's own
  destination (PR #383 audit F1): the terminal adapter sends to the
  recipient's `panel` (the route `pane` remains the fallback only for
  legacy recipient-less events) and explicitly refuses a folder-form
  recipient it cannot serve — never a silent send to the route pane.
  Flat hitl config documents are no longer silently dropped (F11):
  `.ace/hitl/config.yml` without the `hitl:` key now merges over the
  shipped defaults instead of being shadowed by them. The default reply
  address is built from the resolved sender folder (F6): an absolute
  path that identifies the originating worktree, so two worktrees on
  one machine never share a reply address (the relative `root_dir`
  setting stays relative in config). Route names containing a dot
  (e.g. `captain.telegram`) are rejected before any delivery attempt
  (F10): delivery retention keys route names literally and a dot would
  nest frontmatter keys, breaking retry/skip — `send` now fails closed
  with `InvalidRouteError` naming the route.

### Changed

- An unknown adapter on one route no longer aborts the whole send
  (PR #383 audit F5): the route is retained as `unavailable` with the
  resolution error as its reason (never a bare `in_flight` marker), the
  remaining routes still deliver, and the send still reports overall
  delivery failure.

## [0.22.0] - 2026-10-18

### Added

- Retention and redelivery of undelivered messages (8xg.t.sbz.1.3 / L2.4):
  `send` now persists each route's last outcome, failure reason, and attempt
  timestamp on the event's own file (`delivery.<route>` frontmatter — the
  single state owner per ADR-034; no journal or queue). Default `send`
  retries only undelivered or unknown-result routes and skips confirmed
  delivered ones; `--force` redelivers every route and `--dry-run` reports
  the retry/skip decisions without delivering. A `in_flight` marker written
  before each attempt means a crashed send leaves an unknown result that the
  next `send` retries — at-least-once semantics: a retry may duplicate, and
  every rendering carries the same `(case <ID>)` + task binding so
  recipients dedup by ID (exactly-once is not promised). Redelivery retries
  the delivery, never the assignment. `list --delivery undelivered|delivered`
  discovers retained events; `show` prints a per-route `Delivery:` block
  with the retained failure reason. Redelivering an all-delivered event is a
  no-op success (`nothing to retry (use --force to redeliver)`).

## [0.21.0] - 2026-10-18

### Added

- Configurable adapter delivery routes (8xg.t.sbz.1.2 / L2.3): `ace-hitl
  send <ref>` delivers a persisted event through the routes configured under
  `hitl.adapters.routes` — the sender interface is adapter-independent, so
  switching transports is pure configuration (no assignment or coworker
  change). Every route reports its own result line; one route's success never
  hides another's failure and an unavailable adapter never silently reroutes
  (per-route isolation, fail-closed unknown-adapter/no-route errors).
  Built-in `terminal` adapter pushes the shared event text to a pane via any
  `ace-runtime` terminal (tmux/herdr); `ace-hitl-hermes` 0.8.0 ships the
  `hermes` adapter entrypoint (publishes the shared rendering to the channel
  folder; identical resend is idempotent, different-bytes collision fails
  without overwrite, missing folder is `unavailable`). New adapters register
  through the duck-typed `Ace::Hitl::Adapters` registry
  (`lib/ace/hitl/adapters/<name>.rb` entrypoint — a future Nervus adapter
  needs no ace-hitl change). Shared rendering (`Atoms::HitlEventText`):
  `[HITL question]`/`[HITL report <result>]` prefix, `Reply-To:` on questions
  only, task/assignment/step context. Delivery results are reported, not
  persisted — retention and redelivery of undelivered messages is
  8xg.t.sbz.1.3.

## [0.20.0] - 2026-10-18

### Added

- Recipient addressing and Reply binding (8xg.t.sbz.1.1 / L2.2): `ace-hitl
  create ... --to <name>` resolves a configured recipient into an explicit
  address — machine + events folder + case ID (folder form, ID stamped from
  the new event) or machine + panel — read from the `hitl` cascade
  (`machine`, `default_recipient`, `recipients:<name>:{machine,folder|panel}`).
  Questions record a `reply_to` address (sender machine + events folder + own
  case ID) so answers bind to the original case and the right agent;
  task/assignment/step stay context, never an ID substitute. Local Reply is
  unchanged: `update <ref> --answer` bound by exact ID with strict ambiguity
  and explicit not-found — no write to a foreign event. Unknown recipient
  names, malformed configured addresses, and a missing `hitl.machine` fail
  closed before anything is written. `show`/create output print
  `Recipient:`/`Reply-To:`; `HitlEvent#recipient`/`#reply_to` expose the
  address hashes for adapters (delivery itself lands in 8xg.t.sbz.1.2/.1.3;
  local write is not delivery).

## [0.19.0] - 2026-10-18

### Fixed (review PR #383, round 3)

- Report events carry no `kind` (loader returns nil), so question-oriented
  `list --kind` filters never mix reports into a clarification list.

### Added

- Report events: the same `ace-hitl` file interface now records work-done/error notifications alongside questions. `ace-hitl create "..." --type report --result success|error [--body line]... [--task REF]` writes an event with status `recorded`, a `## Report` body, task/assignment/step references, and its own ID. Reports never await an answer: `wait`, `update --answer`, and `update --resume` on a report fail fast with an explicit error (exit 1); generic `--set/--add/--remove/--move-to` still work so an overseer can archive processed reports.
- `--type question` is now written explicitly on new question events (loader defaults keep existing files without `type` valid questions); `--task` is accepted for both types; `list --type question|report` filters by type; `show` prints `Type:`/`Result:` and list gains the `recorded` status symbol.
- Library guards: `HitlManager#update(answer:)` raises `NotAnswerableError` on reports before any file mutation; `wait_for_answer` and `dispatch_resume` return `{status: :report}` without sleeping.

### Notes

- Local write is not delivery: `recorded` means the report is persisted in `.ace-local/hitl/`, not that it reached the overseer. Remote addressing, reply routing, and configurable adapters land in 8xg.t.sbz.1.1–.1.3.

## [0.18.0] - 2026-10-18

### Removed

- Remove the installed Lab provider and its attempt-bound managed HITL path: `Providers::Lab::AssignmentBinding`, `ProtectedAssignmentBinding`, the provider `ask`/native-delivery methods, the `ask` CLI command, and the Herdr-native delivery client in `LiveClient` (the old ace-assign `AttemptCoordinator`/journal identity).
- Remove the second-commander proposal surface: the `proposal` CLI command, `Lifecycle::Proposals`, the proposal policy/evaluator, proposal frames, and the publication HITL binding tied to the removed publication authority.
- Remove managed and TLS `serve` modes: `serve` requires `--operator-only` and fails clearly otherwise.
- Remove the unused old-lab Root Overseer reverse-address channel: `Lifecycle::Overseer`, the `overseer-send`/`overseer-pending`/`overseer-ack` CLI commands, the default `mo` responder, the `ACE_HITL_OVERSEER_CHANNEL_ROOT`/`/lab/state/overseer-channel` default, and the `[decyzja]`/`[pytanie]`/`[info]` response policy. Generic HITL transport and the ready lifecycle surface are unchanged; there is no replacement queue or relay for this role policy.
- Remove the now-dead `LifecycleCommand::STDIN_READER` constant (`deliver` reads stdin inline) and add a Duty projection regression test covering the answer-delivered pending state and mixed effect visibility.

### Changed

- `LiveClient` keeps the requester-side authenticated boundary operations (`wait`, `status`, `pending`); the lifecycle/relay transport (`Lifecycle::*`) remains for `ace-hitl-hermes`.
- Drop the now-unused `ace-assign` and `ace-herdr` runtime dependencies (the managed attempt binding required them); re-lock the workspace Gemfile.lock locally.

## [0.17.0] - 2026-10-16

### Added

- Add explicit unassigned operator questions with kernel requester UID, exact installed project grants, stable retries and existing request/terminal recovery. Expose public client/CLI creation/read and an operator-only service binding that refuses managed execution, secrets and effects.

### Changed

- Require the ace-hitl-contract 0.3 operator-question envelope for the tagged request union.

### Fixed

- Require a reconciliation checkpoint to name the canonical proposal project before silence can authorize its effect.

## [0.16.0] - 2026-10-16

### Added

- Require explicit predelegation for sixteen-hour proposal decisions and bind ordinary project proposals to the selected canonical owner. Refresh project and owner grants at transitions and replay; compose existing Unix/TLS listeners under the authority lifetime.

### Fixed

- Read TLS authority configuration through bounded protected descriptors, rejecting symlinks, unsafe ancestors, special files and concurrent replacement before startup. Declare the direct Runtime dependency used by this reader.

## [0.15.0] - 2026-10-14

### Added

- Add `ace-hitl serve --tls-authority FILE` for the host/Incus mTLS crossing: a TLS 1.3-only loopback lifecycle authority with mutual X.509 identity (closed-form URI SANs, exact SHA-256 fingerprint pins, configured issuing CA, serverAuth/clientAuth EKU), fail-closed credential provisioning-layout enforcement before any socket opens, and remote peer-to-project binding that refuses pending flows, creates, and proposals for any non-bound project. Unix peer-credential serving is unchanged; shared frame/store logic is extracted without behavior change.

### Changed

- Narrow `ace-hitl serve --group` to dedicated lifecycle groups: a missing group, broad or known-shared control groups (gid 0, `lab-control`), the legacy `/run/lab` directory, and directories containing a legacy `labd.sock` entry now refuse startup fail-closed before any endpoint is created.

## [0.14.0] - 2026-10-11

### Added

- Add `ace-hitl serve --group` so each repository authority can expose its lifecycle socket through a dedicated control group.

### Changed

- Direct unsafe socket-directory failures to dedicated service-owned directories that do not contain unrelated service sockets.
- Apply the configured authority group to root-owned public lifecycle projections as well as the service socket.

### Fixed

- Refuse startup if the configured socket group cannot be resolved or assigned, and retag existing public projections to the configured group before serving.

## [0.13.1] - 2026-10-10

### Fixed

- Require the published producer and consumer patch versions containing the protected context and managed-attempt APIs; exclude incompatible prior dependency graphs.

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
