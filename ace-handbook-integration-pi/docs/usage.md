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

- **File wake (ace-wake):** the overseer session subscribes to the ace-hitl inbox once:
  ```
  /watch add reports --path .ace-local/hitl --message "new ace-hitl report; run /continue-work"
  ```
  `ace-hitl create` writes a coworker's report inside THAT coworker's worktree (its own `.ace-local/hitl`), so the watch expands `.ace-local/hitl` to the inbox of every linked worktree — the same `git worktree list` discovery the HITL list uses; no second inbox or cache is introduced. Expansion runs at registration and at every re-registration (session start/reload/branch switch); worktrees created later are covered at the next re-registration, and a worktree inbox that does not exist yet is watched through its nearest existing ancestor, so the first report into it still wakes. A new report wakes an idle session; during an active turn the wake is queued as a follow-up for that same run (never a second overseer execution); repeats coalesce per source; the definition survives restart and re-registers exactly once.
- **Herdr push (`ace-herdr deliver`):** the herdr adapter prompts the overseer pane with the report; delivery is idempotent per event id, and a pane without an agent is bootstrapped first.

After a restart the session is started/resumed with `/continue-work`; the prompt re-reads `_overseer`, assignment, and project truth, so the same commissioned process and its assignments continue. When no new commissioned work exists, the session records that state and waits — it never seeks other tasks on its own.

## Sync

```bash
ace-handbook sync --provider pi
```

Projects skills, prompts, and the extension in one pass. The extension projection records a receipt (`.pi/extensions/.ace-handbook-projection.json`) so stale projected files are pruned without touching extensions you authored yourself.

## Semantic eyes (opt-in replacement for periodic model wakes)

After projecting this package's extension with `ace-handbook sync --provider pi`,
open the project's existing Pi session and run `/eyes start /absolute/path/eyes.json`.
The selected runtime must provide this release's `ace-overseer observe` and
`ace-hitl observe`; when native
Telegram import is configured it also needs `ace-hitl-hermes sync`. These execute
from the project cwd through the selected runtime's PATH. Missing commands,
malformed projections, timeouts and unsuccessful syncs fail closed. This does not
install gems, choose a model, grant permission or create a second bot poller.

A project-owned configuration can be as small as:

```json
{"recipient":"self","scope":"all","syncRoutes":[],"intervalSeconds":30,"maxObservationsPerHour":120,"maxWakesPerHour":20}
```

`recipient` names a real entry in `.ace/hitl/config.yml`'s `recipients` mapping
for this observer (default alias `self`; it must actually be configured). It is
an address selector, never a grant. The HITL owner selects directed incoming
reports/questions, answers belonging to this origin, and instructions imported
into this coordinator's own event root. Outbound Captain questions/reports and
other recipients are excluded. `ace-overseer observe` then consults the existing
private task tree, including archived managers, to suppress adopted reports only
when their entire managing tree is terminal. A recorded report on an active tree
remains eligible to reconcile an incomplete continuation. Canonical terminal
settlements can retire matching pending notifications without another wake;
notification acknowledgement alone never changes those task records.

`current` observes the current project/worktree; `all` includes only its linked
Git worktrees. Set `syncRoutes` to the absolute paths of existing native route JSON
files to import real Hermes delivery/reply/instruction records before observing.
An empty list observes canonical local HITL only and makes no Telegram-readiness
claim. Event roots, channel ownership and authorization remain in those existing
route configurations. The observer does not discover unrelated repositories.

The interval invokes deterministic native sync and read-only `ace-overseer observe`,
not the model. The HITL owner emits identities and semantic revision hashes,
without message/answer text. Content, answers, report results and status change
revisions; delivery timestamps, own acknowledgement, file mtime and polling
bookkeeping do not. Nested records are scanned by the canonical HITL scanner.
Existing unhandled incoming records are initially pending, so adopting a new
observer can produce one reconciliation wake; closed canonical history is excluded; subsequent unchanged polls produce none.

Pi's existing session custom entries retain bounded pending revisions,
acknowledgements, deadlines and breaker/budget state. There is no second report
journal or execution queue. One notification batch (at most 20 revisions) stays
in flight until explicit handling. Further changes coalesce by canonical event
identity, preserving the newest revision. Restart reconciles the same pending
revisions; accepted notification or agent settlement never means business work
completed. The agent reads originals and invokes the existing `ace-overseer
process-reports`/assignment/task owners, which retain report adoption and effect
receipts. It then calls `ace_eyes` with `action: "ack"`, `key`, and exact `revision`.
A newer revision arriving during handling remains pending. Never rerun a merge,
publish or worker start merely because a notification reappeared; reconcile its
existing operation receipt. Operator equivalents are `/eyes status` and
`/eyes ack KEY REVISION`.

Only an actual operation deadline is wake-worthy. The agent tool accepts
`action: "deadline"`, operation `key`, `revision`, and epoch-millisecond `at`;
the operator equivalent is `/eyes deadline NAME REVISION EPOCH_MS`. Deadlines
are one-shot per identity/revision/time. Cancel with `action: "cancel"` or
`/eyes cancel NAME` when the condition no longer applies. Registering a deadline
is an owner decision, not an authorization or an automatic business action.

Observation failures are capped (`maxErrors`, default 3), subprocesses have a
10-second timeout and 1 MiB output bound, event count defaults to 500, and retained
pending/acknowledged identities to 2000. Observation and notification-attempt
budgets persist across restart; notification counts are not token billing.
Quota/credit/billing-limit errors, exceeded budgets, or repeated source failures
open a visible breaker, stop the observer, and retain pending. No model fallback
or automatic quota retry occurs. After checking the underlying quota/source and
operation state, the operator explicitly runs `/eyes resume quota-verified`.
This checks deterministic source readiness, not provider billing. The agent tool
cannot resume the breaker. Retention exhaustion needs owner reconciliation and
handoff to a new session; do not clear history to suppress pending work.

Starting eyes removes this actor's legacy `/loop` and `/watch` subscriptions and
refuses new ones while eyes owns observation. `/eyes retire` also stops eyes,
preserves pending for handoff, and permanently prevents that session actor from
restarting itself (including after reload). Other sessions are untouched. No
watchdog revives dead processes. Published installation, real Telegram delivery,
and a live 24-hour no-change window remain separate acceptance checks; the source
suite uses an accelerated clock and real temporary native transport files.
