# ace-handbook-integration-pi Usage

PI provider integration: canonical ACE skills project to `.pi/skills`, prompt templates to `.pi/prompts`, and the bundled **ace-wake** extension to `.pi/extensions` -- all via `ace-handbook sync --provider pi`.

This package owns no task, assignment, or queue state. The ace-wake timers/watch
are a local in-process utility: no cron, daemon, or delivery-queue engine.
Continuation of already delegated work is available since L7.3 through the
`/continue-work` resume prompt plus the report wake wiring below; the bounded
wake contract is transport behavior, not a work queue.

## Waking agents with ace-wake (`/loop`, `/watch`)

The `ace-wake` extension runs inside the live Pi process. It lets an agent sleep while idle and receive a bounded wake message when a timer fires or a watched file changes. Wake means `queue/sendUserMessage` only: the agent decides what to do after waking. No cron, systemd, external heartbeat, or automatic task execution.

### Commands

```
/loop add NAME --interval SECONDS --message TEXT
/loop list
/loop remove NAME

/watch add NAME --path PATH --message TEXT
/watch list
/watch remove NAME
```

- Loop intervals must be finite numbers greater than zero; names must be unique per subscription kind; messages must not be empty. Invalid input fails with a visible error.
- Flag values may be quoted either after the flag (`--message "check the build"`) or inline (`--message="check the build"`); quotes keep values with spaces whole, and an unterminated quote fails the command instead of storing a truncated value.
- Watch paths are resolved to canonical absolute paths relative to the session working directory and validated for readability before the watch is stored. An unreadable path fails the command.
- Active subscriptions appear in the status surface (`ace-wake` status key). `/loop remove NAME` / `/watch remove NAME` stop future wakes.

### Wake delivery semantics

- **Idle agent:** the wake is sent as a user message and triggers a turn.
- **Busy agent** (streaming or executing a tool): the wake is queued as a follow-up. It never interrupts an in-flight tool operation; user conversation stays responsive. Concurrent sources deliver into an active run immediately -- unrelated sources never wait for that run's settlement.
- **Coalescing:** while one wake for a source is queued, repeated triggers of the same source coalesce into the pending wake. Different sources stay independent (`loop:NAME` and `watch:NAME` are distinct).
- **Messages are bounded** and prefixed with their source, e.g. `[ace-wake loop:heartbeat] check the build`.

### Recovery when delivery is unconfirmed

Pi's `sendUserMessage` returns before delivery resolves, and some refusals (no model selected, failed authentication) never emit a lifecycle event. ace-wake resolves that ambiguity toward **redelivery over loss**: a duplicate is a repeated, bounded, source-prefixed message the agent can ignore, while a silently lost duty wake is a miss. The contract:

- An attempt that Pi shows as neither queued nor running after a bounded recovery window is released and re-attempted from the latest state; retry cadence is one attempt per window, never a spin.
- A watch change refused because no model is selected retries on the same bounded window and delivers as soon as a model exists -- no further filesystem event is needed. (Loops need no such timer: their next tick is a fresh attempt.)
- Unconfirmed watch attempts revert to their last delivered fingerprint before replay, so a genuinely consumed wake is never duplicated, only refused ones are re-sent.

### Reloads, restarts, and errors

- Definitions persist as session entries and survive reload, compaction, restart, and branch switches. Each live-session subscription is re-registered exactly once -- a reload never duplicates timers, and a restart never replays missed ticks.
- A watch whose path becomes unreadable deactivates with a visible error and does not retry-spin; remove and re-add it explicitly once the path is readable.
- The extension never claims to wake a dead process. Overseer liveness detection and restart decisions belong to the L7 status/continuation wave (`ace-overseer status`, `/continue-work`), not to ace-wake.

## Continuing commissioned work with `/continue-work` (L7.3)

The `/continue-work` prompt template (`.pi/prompts/continue-work.md`) is the resume prompt for a pi overseer session. It runs on two triggers: a report notification woke the session, or the session restarted. In both cases it:

1. reads real state — `_overseer` tasks (`ace-task --in _overseer list`), `ace-assign` assignments under `.ace-local/assign/`, and project truth (`ace-task list`, `ace-overseer status`, `ace-git-worktree list`, `git status --short`);
2. processes reports through `ace-overseer process-reports` (dedup by event state — delivery repetition is never work repetition);
3. continues the SAME commissioned process via `ace-overseer work-on` / `ace-overseer handoff`.

### Report wake wiring

A report notification reaches the waiting overseer session through the existing transports — no second queue is introduced:

- **File wake (ace-wake):** the overseer session subscribes to the ace-hitl inbox directory once:
  ```
  /watch add reports --path .ace-local/hitl --message "new ace-hitl report; run /continue-work"
  ```
  A new report file wakes an idle session; during an active turn the wake is queued as a follow-up for that same run (never a second overseer execution); repeats coalesce per source; the definition survives restart and re-registers exactly once.
- **Herdr push (`ace-herdr deliver`):** the herdr adapter prompts the overseer pane with the report; delivery is idempotent per event id, and a pane without an agent is bootstrapped first.

After a restart the session is started/resumed with `/continue-work`; the prompt re-reads `_overseer`, assignment, and project truth, so the same commissioned process and its assignments continue. When no new commissioned work exists, the session records that state and waits — it never seeks other tasks on its own.

## Sync

```bash
ace-handbook sync --provider pi
```

Projects skills, prompts, and the extension in one pass. The extension projection records a receipt (`.pi/extensions/.ace-handbook-projection.json`) so stale projected files are pruned without touching extensions you authored yourself.
