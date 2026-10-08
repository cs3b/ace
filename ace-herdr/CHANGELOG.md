# Changelog

All notable changes to `ace-herdr` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- Allow maintenance preview to refuse contended slot, authority and retained Inbox exclusions within its original deadline, releasing partially acquired locks.

### Fixed

- Load the shared error hierarchy explicitly from Inbox and executor primitives, allowing a fresh protected authority source load without the broad Herdr configuration entrypoint.

- Bound subprocess cleanup to one additional second after execution timeout, retain the unreaped original child through owned signalling, and transfer only unconfirmed cleanup to an eventual reaper. Generic successful calls preserve their no-group-signal behavior; protected handlers may select nonreaping termination observation before owned group cleanup. Native effectiveness remains unverified here.

### Added

- Bind protected direct Inbox admission and retained DeliveryRecord to explicit original project, assignment, mapping and context; recheck canonical original identity outside then under the existing store exclusion before effects.

- Read original canonical Inbox launch identity through the same bounded authenticated context authority client, refusing mismatched registration, guard and native association without authorizing dispatch.

- Construct a maintained context service from held literal configuration, the selected full installation owner, fresh key artifacts and an observed service epoch. Bound listener population and stop, retain issuer epochs, and refuse active-incarnation replacement. Pin native queue/wake executables, dependency bytes, environment and IPC placement; use separate bounded initialization acknowledgement and read-only same-epoch replay before ingress. Actual Lab entry/acknowledgement publication, original guarded native admission and stopped-owner recovery remain required composition gates.

- Permit explicit protected retry only after fixed canonical supersession confirmation, retaining one exact completion binding in the existing DeliveryRecord and invalidating it on each new claim or proof replacement. Revalidate source-returned idle read-only deliveries separately from effectful exact claim ownership.

- Route protected Inbox reconciliation through the existing authenticated authority upload/CAS, and retain exact direct claim ownership and returned-issuer evidence for verified canonical retirement; pre-return recovery and canonical retry remain separate source gates.

- Route protected Inbox enqueue, deliver and status through fixed installed selection and authenticated context admissions, retaining exact inputs and unknown outcomes across restart; ordinary local commands remain independently supported.

- Support explicit bounded read-only regular-file descriptor mappings and exact stdin source handoff; close all unmapped descriptors and reject invalid or stdio-overwriting mappings before spawn.

- Retain pending Inbox effects durably until the fixed authority authenticates their exact canonical completion. Add bounded binary proof exchange and protected snapshot/reconciliation endpoints; exceptions and lost acknowledgements continue to block end/rotation.
- Add the source-owned inbox context admission/rotation core with durable grants, authenticated signer replacement/rollback attestations, protected key readback and bounded fixed transport. Protected Assign/CLI migration and positive orphan reclamation remain required before full context acceptance.
- Select the exact native original-actor input inhibition/drain source, with monotonic admission/write exclusion, bounded closed replies and controlled race coverage. Installed effectiveness and N2 consumer integration remain separate acceptance gates.
- Add explicit original native guard capture, closed guarded prompt decoding and exact-actor input inhibition decoding without changing existing launch binding bytes.

## [0.4.0] - 2026-10-05

### Fixed
- Use the shared typed reverse-reference pair at CLI, Inbox and delivery boundaries, refusing malformed persisted targets and noncanonical serialized files before claim or native observation.
- Pin managed delivery to the accepted original native target under the event lock and reject secret-bearing payloads even without a nested message.

### Changed

- Declare the required direct dependencies and minimum producer versions for this coordinated release: `ace-hitl-contract ~> 0.2`, `ace-runtime ~> 0.2`.
- Bind protected control to the canonical per-attempt server/socket identity while retaining the fixed native executable view selected by installation verification.
- Validate and preserve the shared managed delivery envelope at Inbox enqueue, rejecting mismatched scope/digest/correlation and changed replay metadata.

### Added

- Add protected Herdr control pinned to the installed server/socket and fixed workspace, creating one fresh bootstrap pane with exact child observation and no default shell.

- Expose verified native process/session ownership and allow identical signed inbox proof re-verification after settlement without duplicate transitions.

## [0.3.2] - 2026-10-04

### Changed

- Depend on the leaf `ace-hitl-contract` provider vocabulary instead of full HITL orchestration, removing the assignment adapter dependency cycle.

## [0.3.1] - 2026-10-04

### Fixed
- Replacing a dead prepared pane updates only the recorded pane pointer: a foreign tab's pointer-only identity record stays pointer-only instead of gaining invented `root`/`preset` ownership keys, so the live replacement pane is reused across adapter and process restarts and `ensure_window` at the verified native root still adopts the tab. Records with genuine provenance keep their exact root and preset, and wrong ids, conflicting provenance, corrupt records, and stale pointers still cannot bypass the ownership guards.
- `ace-herdr tab` reports a failed preset materialization (native tab created, later step failed) through the standard CLI error boundary — non-zero exit, actionable message, no success payload, and no stack trace in ordinary mode. The runtime adapter keeps its documented runtime classification and exact-id rollback; this entrypoint never closes tabs.

## [0.3.0] - 2026-10-02

### Added
- Durable `inbox enqueue`, `status`, and `deliver` commands for attempt-linked messages. Enqueue binds the live pane, terminal, agent, and native session; per-event locked claims and saved submission intent prevent duplicate dispatch after a crash. Codex and Pi use exact-session native queues, and idle agents receive a bounded, payload-free Herdr wake after accepted submission.
- Inbox status reports claim generation, target binding, accepted submission receipt, and uncertainty. `reconcile` accepts an operator or supervisor native-outcome receipt file only when its trusted detached signature and event, attempt, generation, digest, and full bound identity match; missing or mismatched proof returns a machine-readable refusal and keeps the event uncertain.
- Installed acceptance covers Codex delivery, signed uncertainty reconciliation, and idle Pi delivery; bounded wake tests cover subprocess stalls and structured errors.

### Fixed
- Post-launch subprocess I/O failures terminate the child process group before surfacing, so a failed run can never leave an orphaned native client behind past the deadline.
- Post-launch subprocess I/O failures are classified separately from spawn failures, so a native client that already ran keeps its event uncertain instead of being re-queued for a duplicate submission; and a pane that changed agent is classified as target drift before agent-specific validation can mask it.
- Unreadable or malformed reconciliation receipt files surface as the documented machine-readable refusal while persistence failures still exit as command errors.
- Orphaned claims recover by proof: a claim saved before any submission intent requeues as retryable, while only intent-carrying claims stay uncertain; every spawn-time failure is classified at the process boundary as proven pre-launch (retryable) across both executors; and the inbox CLI reports persistence failures as command failures instead of receipt refusals.
- Target identity drift is classified before agent-specific event id rules, so a bound event whose pane changed agent lands in reconcilable uncertainty instead of looping on a pre-send validation error.
- Native queue bindings require an immutable session id for both Codex and Pi, so an agent restarting under the same name in a reused pane can never inherit an old event; signed replacement targets are validated against the replacement agent's own event-id and payload rules before a supersession re-binds the event.
- Pane probe responses are shape-checked and exit-checked before use, so malformed or failed `herdr pane get` output becomes a classified retryable error instead of stranding a claimed event or delivering against a failed observation; the Pi identity probe rejects non-object JSON the same way.
- The pane identity probe runs under a bounded child deadline (process-group kill), so a stalled herdr pane get can no longer hold the per-event inbox lock; a probe timeout classifies as a retryable pre-submission failure. The idle-wake decision rides the first delivered transition (a busy target can never be prompted by a crash-recovery retry), and enqueue rejects payloads that are not valid UTF-8 text with an actionable validation error.
- Pane observation launch failures are normalized to executor unavailability so a delivery probe can never strand an event in `claimed`; idle-wake retry outcomes persist across restarts; reverse-address files that are not JSON objects fail enqueue with an actionable validation error instead of crashing.
- Enqueue applies the target agent's native payload limit (Codex argv bound, Pi body bound) before persisting an event, validates recognized agent statuses before submission (undetermined statuses stay retryable pre-send), and shares one Pi event id validator between enqueue and delivery, so events that could never be delivered are rejected up front instead of queuing forever.
- Idle-agent wakes are persisted as pending before they are attempted and retried by later deliver calls (re-verifying the live target; identity drift demotes the event to uncertain) without ever resubmitting the native payload, so a crash or transient wake failure can no longer leave an accepted message undelivered to an idle agent. Pi targets now enforce the `inb-`/`wnk-` event id constraint at enqueue instead of queuing an event that can never be delivered.
- Native queue submission and the Pi identity probe enforce their deadline at the child boundary through a shared bounded-process molecule (process-group kill, bounded pipe draining, nonblocking partial stdin writes). A stalled or non-reading native client can no longer hold the per-event inbox lock past the configured timeout the way a cleanup-blocking `Timeout.timeout` around `Open3.capture3` allowed. Codex payloads are size-bounded before launch and a spawn-time `E2BIG` is classified as a proven pre-submission rejection, keeping the event retryable instead of stranding it uncertain.

## [0.2.0] - 2026-10-02

### Added
- `Ace::Herdr::Organisms::RuntimeAdapter` and the lazy `ace/runtime/adapters/herdr` entrypoint implement the shared ace-runtime intent contract. It preserves native agent prompt and wait semantics, polls all four lifecycle observations, and maps Herdr failures to contract errors. Native tab and pane probes support context, focus, and retained pane preparation. The packaged shared adapter contract suite runs against a Herdr-shaped fake executor.

## [0.1.0] - 2026-09-27

### Added
- `ace-herdr tidy` (spec 8wq.t.1w0): dry-run-by-default cleanup of finished agent panes and delivery records. Pane closure requires positive completion evidence only (observed `done` agent state, or a pane whose native `pane process-info` shows no live foreground process — herdr omits `foreground_processes` when empty) re-confirmed by a fresh probe immediately before the rename-to-`done`-then-close mutation; revived or uncertain candidates are excluded and never mutated. Delivered records strictly older than the new `tidy.delivered_retention_days` config key (default 7) are atomically archived to `deliveries_dir/archive/` after a lock-guarded reload re-proves eligibility; `pending`/`retryable`/`failed` and unreadable records are never touched, an unreadable record encountered during apply is preserved and reported instead of aborting. Archival never breaks delivery idempotency (`deliver`/`--resume` consult the archive copy, so identical re-delivery still short-circuits and conflicts still fail closed). Deterministic one-line JSON report with explicit empty states; an unreachable herdr runtime fails with an explicit error and no partial report.
- Terminal-control surface matching the ace-tmux intent vocabulary (spec 8wq.t.k84), keeping one-line JSON output: `ace-herdr list` (panes/tabs/workspaces, `--workspace` scoping, explicit empty arrays), `ace-herdr send` (declaration-ordered `--cmd`/`--msg`/`--key`; agent-aware routing sends one self-submitting `agent prompt` on agent panes with `agent_blocked`/`agent_prompt_stalled` gating and drop-and-report of a single trailing `--key Enter`; invalid shapes fail closed before any transport call), `ace-herdr capture` (raw `pane read` text, `--source visible|recent`), `ace-herdr wait --for output --pattern` (literal match, immediate check then poll, seconds→ms conversion, timeout CLI error) alongside the unchanged agent wait, and `--list-presets`.
- Preset-driven creation: `ace-herdr workspace <preset>` / `ace-herdr tab <preset>` compose YAML layouts through the ADR-022 cascade (`.ace/herdr/` > `~/.ace/herdr/` > gem `.ace-defaults/herdr/`, ships `workspaces/development.yml` + `tabs/agent.yml`), with recursive `preset:` inheritance (deep merge, array concat, cycle detection, fail-closed missing references), deterministic creation order (workspace → tabs → root pane + splits → renames → pane commands → readiness-gated agent starts; herdr's seeded initial tab is closed once the declared tabs exist), CLI `--cwd` overrides (CLI > tab > root > pane), and pre-creation layout validation (unplaced panes, duplicate placements, unknown split targets/directions fail closed and create nothing). Includes a tmux-intent ↔ herdr-command parity table in `docs/usage.md`.
- `Ace::Herdr::Organisms::ControlSurface`: owner of the terminal-control behavior — native JSON normalization into public payloads, send validation/routing, and preset instantiation.
- `Ace::Herdr::Molecules::PresetLoader` (ADR-022 cascade discovery) and `Ace::Herdr::Molecules::PresetResolver` (`preset:` reference resolution).
- `Ace::Herdr::Molecules::HerdrExecutor`: native operations for workspace/tab/pane listing, pane read/send-text/send-keys, pane wait-output, pane split, workspace create, agent send-keys, and focus flags on tab/workspace creation; typed `TabNotFoundError`/`WorkspaceNotFoundError` classification; herdr machine codes are now carried in executor error messages (for example `pane_not_found: ...`); output-wait timeouts raise `WaitTimeoutError`.
- Gem bootstrap (spec 8wm.t.vs0): push delivery + agent bootstrap for the Herdr runtime, implementing the ace-hitl provider delivery contract (`deliver(ref, answer)` -> `DeliverResult` with `:delivered`/`:retryable`/`:failed`).
- `Ace::Herdr::Organisms::Deliverer`: idempotent per event id with write-ahead delivery records under `.ace-local/herdr/deliveries/` (0600, atomic writes; the full answer is persisted so a crash never loses it, recoverable via `ace-herdr deliver --resume`), per-event lock serializing concurrent deliveries, duplicate-identical short-circuit, fail-closed content/destination conflicts, bootstrap of missing agents (`herdr agent start` with shell-escaped `HERDR_SESSION`/`HERDR_PANE` exported into the pane shell), a readiness gate before prompting, retry limits with fixed deterministic backoff (covering prompt and probe failures), and terminal-failure reporting — including the ambiguous crash window after a submitted prompt, reported instead of silently resent.
- `Ace::Herdr::Organisms::Dispatcher`: one-command subagent dispatch — tab + `herdr agent start` + prompt with deterministic defaults (caller's workspace, label = agent/pane name, prompt from file/stdin/`--no-prompt`); workspace and pane identifiers are token-validated and shell-escaped before they reach a pane shell.
- `ace-herdr` CLI: `deliver`, `dispatch`, `wait`, `close` (JSON output, exception-based exit codes per ADR-023).
- `Ace::Herdr::Molecules::HerdrExecutor`: the single seam to the herdr CLI (argv arrays per ADR-031) with typed error classification from herdr's machine-readable codes (`agent_blocked`, `agent_prompt_stalled`, `pane_not_found`, `timeout`).
- Config cascade (ADR-022) defaults: `default_agent_kind`, delivery retry limits/backoff, timeouts, deliveries dir (ADR-029).
