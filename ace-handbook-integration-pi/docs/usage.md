# ace-handbook-integration-pi Usage

PI provider integration: canonical ACE skills project to `.pi/skills`, prompt templates to `.pi/prompts`, and the bundled **ace-wake** extension to `.pi/extensions` -- all via `ace-handbook sync --provider pi`.

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
- The extension never claims to wake a dead process. Overseer liveness detection and restart decisions belong to the session-liveness layer (task `8wq.t.1w5`).

## Running the backlog with `/work-backlog`

The `/work-backlog` prompt template (`.pi/prompts/work-backlog.md`) runs the ACE overseer loop in-process: pick a backlog task, execute it via `as-task-work`, verify, report, and continue until the backlog drains or a stop condition fires. This is the prompt formerly published as `/loop`; the `/loop` name now belongs to the ace-wake timer command.

## Sync

```bash
ace-handbook sync --provider pi
```

Projects skills, prompts, and the extension in one pass. The extension projection records a receipt (`.pi/extensions/.ace-handbook-projection.json`) so stale projected files are pruned without touching extensions you authored yourself.
