# Changelog

All notable changes to ace-handbook-integration-pi will be documented in this file.

## [Unreleased]

### Fixed
- `ace-wake` runtime discovery refresh (`wake/watch-subscription.js`): worktree discovery re-ran only inside `handleChange` — the one-shot ~500 ms post-registration reconcile plus events on already-watched paths. A worktree linked long after start whose FIRST report landed in its own (then-unwatched) inbox triggered no refresh pass at all, so the wake was missed until another watched path changed or a re-registration. Settlement boundaries now refresh discovery for EVERY active subscription: `flushDirty()` runs the full refresh pass (target discovery + ancestor→direct re-attachment) for all entries, not only dirty ones, and delivers any fingerprint change as a wake. Covered by a fake-layer scenario (late-linked worktree, report in its own inbox, no watched-path event, wake at the settlement boundary); the real-git late-worktree scenario in `test/js/report-wake-worktree.test.mjs` now expresses production ordering — it waits out the one-shot reconcile before linking the worktree and proves the settlement boundary is the channel that wakes.
- `ace-wake` discovery micro-race: a report created between the discovery stat proving a target absent and the baseline fingerprint recomputation was absorbed into the baseline (the `absent` state was never recorded), so the first report into that inbox never woke. The baseline now records the PROVEN "absent" state (derived from the ancestor climb, never a re-stat) at registration and at every discovery refresh, and attaching a newly discovered target schedules a follow-up reconcile pass mirroring `start()` — a race-window report stays a pending change and is delivered by that pass. A fake-layer test injects the report exactly inside the stat-throw/recompute window and asserts the wake.
- `ace-wake` watcher runtime errors on a discovered extra target no longer kill the whole subscription: with runtime discovery, `ace-overseer prune` removing a watched worktree used to deactivate the watch for ALL worktrees (never retried). A runtime error on the primary target keeps the documented deactivate posture; an error on a discovered extra target drops only that target's watcher (the disappearance is absorbed into the baseline — a pruned worktree is not a report) while the subscription stays active, and discovery re-attaches the target if it reappears. A fake-layer test asserts watcher teardown without deactivation and that the primary keeps waking.
- `ace-wake` report watches now discover worktrees linked AFTER the watch started: inbox expansion (`expandInboxWatchTargets` over `git worktree list`) re-runs on every change/reconcile refresh pass instead of only at registration, so a report filed in a task worktree created while the overseer session is already watching still wakes it — no re-registration, reload, or new queue/cache. A newly discovered target that is still absent joins the baseline fingerprint as its stable "absent" state, so only the first report into it wakes.

### Added
- L7.3 commissioned-work continuation (task 8xg.t.sbz.6.2): new `/continue-work` resume prompt (`handbook/prompts/continue-work.md`) for a pi overseer session. After a report wake or session restart it reads `_overseer` tasks, `ace-assign` assignments, and current project truth, then continues the SAME commissioned process through the existing `ace-overseer` gates (`process-reports`, `work-on`, `handoff`) with single-execution, delivery-repetition-≠-work-repetition, and no-self-seeking rules. Report wake wiring is documented: a `/watch` on `.ace-local/hitl` wakes a waiting session, active turns receive queued follow-ups, and restarts re-register the watch exactly once.
- JavaScript acceptance suite for the report wake path (`test/js/report-wake.test.mjs`): wake-on-report for an idle session, queued follow-up (never a second execution) during an active turn with coalesced repeats, exactly-once re-registration after restart without replay, and idempotence of an identical repeated notification. Shared session harness extracted to `test/js/session-harness.mjs`; a real-filesystem test proves a file created inside a watched directory (the `.ace-local/hitl` inbox wiring) wakes exactly once.

### Changed
- `ace-wake` `/watch` now handles directory targets explicitly: the directory itself is watched and any child event is accepted (the mtime/size fingerprint filters noise), so a report file created in `.ace-local/hitl` wakes the session on every platform — Linux inotify delivers child-create events only to a watch on the directory itself, which the previous parent-watch design could never observe. File targets keep the parent-watch + basename-filter behavior that survives atomic replacement.
- Removed the superseded `/work-backlog` prompt template: its self-seeking backlog cycling (pick any pending project task) contradicts the approved file-based lab contract; `/continue-work` replaces it with no alias.

### Fixed
- `ace-wake` watcher re-attachment (`refreshAttachments` in `wake/watch-subscription.js`) could crash the extension host: `watchFactory` may throw synchronously (EMFILE, EPERM, stat race) and re-attachment is reached from native watcher callbacks and the reconcile timer with no guard. The replacement watcher is now attached BEFORE the old ancestor watcher is closed — on an empty result the old watch survives — and a synchronous throw is caught and deactivates the definition (`re-attachment failed: …`, all watchers closed) per the documented runtime-error posture (visible error via `onDeactivate`, never retried) instead of escaping into the host. Covered by a new fake scenario in `test/js/report-wake.test.mjs` (synchronous `watchFactory` throw during re-attachment deactivates the watch, delivers no wake, and leaves no watchers).
- Cross-worktree report wake (PR393 P2): `ace-hitl create` writes a coworker's report inside THAT coworker's worktree (its own `.ace-local/hitl`), so the documented watch on the main checkout's inbox never fired — reproduced with a real linked worktree, a real `ace-hitl create` and the real watcher (zero wakes). A `/watch` on `.ace-local/hitl` now expands to the inbox of every linked worktree using the same `git worktree list --porcelain` discovery the HITL list uses (new `wake/inbox-discovery.js`, the default `resolveTargets` port of `createWatchPort`, overridable for tests); no second inbox, queue, or cache. The watch fingerprint aggregates all targets — a worktree inbox that does not exist yet is a stable "absent" state watched through its nearest existing ancestor, so the first report into a freshly created inbox still wakes; expansion re-runs at every re-registration (session start/reload/branch switch). `test/js/report-wake.test.mjs` gains cross-worktree scenarios (including a not-yet-existing inbox and exactly-once re-registration across targets) and a new real-git + real-`bin/ace-hitl` scenario in `test/js/report-wake-worktree.test.mjs` fails with the old single-target watch.
- `ace-wake` watcher re-attachment for formerly-absent inbox targets: when a worktree's `.ace-local/hitl` did not exist at registration, the watcher attached to the nearest existing ancestor — but Linux inotify is non-recursive, so a SECOND report created inside the now-existing inbox fired no event until the next re-registration. Every change/reconcile pass now re-checks targets watched through an ancestor and, once the target exists, closes the ancestor watch and watches the real target directly (`refreshAttachments` in `wake/watch-subscription.js`). Proven by a new fake scenario in `test/js/report-wake.test.mjs` (second report wakes; the ancestor watch is closed and the inbox watched directly) and a second real-`ace-hitl create` step in `test/js/report-wake-worktree.test.mjs`.
- `expandInboxWatchTargets` now realpath-normalizes its results (worktree roots before joining the inbox suffix, since the inbox itself may not exist yet): symlinked roots (`/tmp` → `/private/tmp`) previously survived as distinct strings, defeating the target dedup in `createWatchPort`'s `resolveTargetsFor` and double-watching one physical inbox.
- `test/js/report-wake-worktree.test.mjs` no longer sleeps fixed 700/900 ms gaps: an awaited-event helper (`waitFor`, 25 ms poll with a 5 s deadline) awaits each expected wake directly, removing slow-machine flake and shortening the fast path.

## [0.5.0] - 2026-09-28

### Added
- Shipped the **ace-wake** Pi extension (`handbook/extensions/ace-wake/index.js`, projected to `.pi/extensions/`): session-scoped `/loop` timers and `/watch` file subscriptions that wake the live agent through queued `sendUserMessage` messages only. Wakes are bounded, source-prefixed, coalesce per source while one is queued, and reach busy agents as queued follow-ups that never interrupt an in-flight tool operation. Concurrent sources deliver into an active run immediately (serialization guards only the idle-to-running transition). Delivery ambiguities from Pi's void `sendUserMessage` resolve toward redelivery over loss: unconfirmed attempts re-fire on a bounded recovery window, and watch changes refused while no model is selected retry on that window without needing another filesystem event. Definitions persist as session entries and reconcile exactly once per session start, reload, or branch switch with no missed-tick replay. No cron, systemd, or external heartbeat dependency.
- Provider manifest now declares `extensions_dir: .pi/extensions`; `ace-handbook sync` projects extension assets and prunes stale projected files via a projection receipt without touching user-authored extensions.
- Command flags accept quoted values both after the flag (`--message "check the build"`) and inline (`--message="check the build"`); an unterminated quote fails the command instead of storing a truncated value, while prose apostrophes mid-token stay literal.

### Changed
- Renamed the backlog-running prompt from `/loop` to `/work-backlog` (template `handbook/prompts/work-backlog.md`) so the timer command owns the `/loop` name. Behavior unchanged; no alias is provided.
- Package verification now includes the JavaScript wake suite (run on the installed Node runtime) and an installed-extension acceptance scenario inside the real Pi SDK runtime (`test/feat/`).

## [0.4.0] - 2026-09-27

### Added
- Provider manifest now declares `prompts_dir: .pi/prompts`; canonical pi prompt templates from `handbook/prompts/` project there via `ace-handbook sync`.
- Shipped the canonical `loop` prompt template: the ACE overseer loop running in-process inside a pi session (`/loop`), cycling the task backlog through the `as-task-work` discipline with executed-evidence stop conditions. Projected to `.pi/prompts/loop.md`.


## [0.3.11] - 2026-09-02

### Technical
- Included in the coordinated all-package patch release preparation for ACE monorepo review.
## [0.3.10] - 2026-08-12

### Technical
- Raised the `ace-handbook` dependency floor to `~> 0.31` after the generic release workflow baselines release.

## [0.3.9] - 2026-08-12

### Technical
- Aligned gemspec dependency floors with current ACE package minor release lines and safe external minor dependency bumps (no major version jumps).

## [0.3.8] - 2026-04-22

### Technical
- **ace-handbook-integration-pi v0.3.8**: Bumped patch release to keep dependency constraints aligned with `ace-handbook v0.28.0`.

## [0.3.7] - 2026-04-13

### Changed
- **ace-handbook-integration-pi v0.3.7**: Published handbook and HITL migration release changes for PI handbook integration.


## [0.3.6] - 2026-04-11

### Technical
- Migrated deterministic coverage to `test/fast/` and documented `ace-handbook-integration-pi` as a fast-only package (no `test/feat/` or `test/e2e/` layer).

## [0.3.5] - 2026-03-29

### Technical
- Updated the `ace-handbook` runtime dependency range from `~> 0.21` to `~> 0.22` to follow the new handbook minor release.

## [0.3.4] - 2026-03-29

### Technical
- Normalized published gem metadata so RubyGems and Ruby Toolbox use current release information instead of the 1980 fallback date.


## [0.3.3] - 2026-03-29

### Fixed
- **ace-handbook-integration-pi v0.3.3**: Bumped dependency constraints to currently available `~>` ranges on RubyGems and updated release metadata after dependency synchronization.

## [0.3.2] - 2026-03-22

### Technical
- Standardized PI provider casing in README terminology (`PI-specific`, `PI-native`) to match package naming and changelog language.

## [0.3.1] - 2026-03-22

### Technical
- Refreshed the package README with standardized handbook integration sections, PI-specific provider wording, and ACE/`ace-handbook` linkage.

## [0.3.0] - 2026-03-12

### Changed
- Replaced the legacy `ace-handbook-integration-agent` dependency with a direct `ace-handbook` runtime dependency.
- Updated the package entrypoint and docs to treat PI integration as a thin provider plugin on top of `ace-handbook`.

## [0.2.0] - 2026-03-10

### Added
- Added a shipped PI provider manifest and packaging support so `ace-handbook sync` can project canonical skills into `.pi/skills`.

### Changed
- Simplified the PI integration entrypoint to a thin provider package that relies on `ace-handbook` for sync and status execution.

## [0.1.1] - 2026-03-10

### Added
- Added the PI-specific handbook integration package scaffold on top of the shared agent integration base.

## [0.1.0] - 2026-03-10

### Added
- Initial package scaffold for PI handbook integration support.
