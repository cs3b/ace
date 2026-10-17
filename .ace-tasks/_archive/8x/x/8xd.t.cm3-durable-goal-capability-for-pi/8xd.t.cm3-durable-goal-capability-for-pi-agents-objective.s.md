---
id: 8xd.t.cm3
status: cancelled
priority: high
created_at: "2026-10-14 08:24:33"
estimate: TBD
dependencies: []
tags: [ace-wake, goal, pi-extension, h8x]
needs_review: true
---

## Zastąpienie programu — 2026-10-17

Użytkownik polecił anulować i zarchiwizować to zadanie: architekturę wcześniejszego
laba zastępuje uzgodniony model ACE — pliki, własne taski overseera, assignmenty
coworkerów i wspólna komunikacja HITL z adapterami.

Nowi właściciele zakresu: [8xg.t.sbz.6](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/6-l7-status-overseera-i-kontynuacja/8xg.t.sbz.6-l7-status-overseera-i-kontynuacja-zleconej-pracy.s.md).
Program: [8xg.t.sbz](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md); [mapa zastąpień](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/backlog-map.md).
Poniższa specyfikacja pozostaje historią, nie aktywnym poleceniem wdrożenia starej
architektury. Kod, raporty, branche i worktree pozostają zachowane.

# durable /goal capability for pi agents — objective with Assign-linked completion evidence, wake continuation, pause/resume/cancel, restart adoption, coalesced wakes

## Status

SPEC-ONLY draft, needs_review. This task authors the normative capability
specification for a durable `/goal` primitive. It claims NO implementation:
the implementation target is the existing `ace-wake` extension family
(source: `ace-handbook-integration-pi/handbook/extensions/ace-wake/`,
projected to `.pi/extensions/ace-wake/index.js`); nothing in this document
asserts that a `/goal` command exists today or that any behavior is
installed. Acceptance below defines the executable scenarios a later
implementation slice must satisfy.

## Capability summary (Captain, normative)

A `/goal` command (pi extension, ace-wake family) holds a DURABLE objective:

- completion evidence is LINKED TO ASSIGN — the goal's done-state is
  evidenced by Assign task/attempt state plus receipts, never by self-claim;
- continuation on wake — a wake resumes the registered goal's NEXT action;
- pause / resume / cancel verbs;
- RESTART ADOPTION — after session reload or restart, the persisted goal is
  adopted without duplicate execution;
- bounded coalesced wakes — goal wakes coalesce per goal; no wake storms;
- blocker recording with owner + next action;
- cleanup when complete.

## Objective definition schema

A registered goal definition contains exactly:

| Field | Required | Meaning |
| --- | --- | --- |
| `name` | yes | Unique goal name within the agent session (same charset/length rules as loop/watch names). |
| `task` | yes | Assign task reference (e.g. `8xd.t.cm3`). The sole completion-evidence link. |
| `attempt` | no | Optional Assign attempt reference for in-flight work continuation. |
| `objective` | yes | Continuation instruction text delivered on each wake ("resume the next action"). |
| `interval` | yes | Positive integer seconds between goal checks/wakes (same validation as `/loop`). |
| `state` | derived | `ACTIVE` / `PAUSED` / `BLOCKED` / `COMPLETE` / `CANCELLED`. Never agent-claimed; derived per the rules below. |
| `blocker` | conditional | Present iff `state: BLOCKED`: `{description, owner, next_action, recorded_at}`. |
| `created_at` / `updated_at` | derived | Registry bookkeeping. |

The goal definition REFERENCES Assign state; it never stores or duplicates
task/attempt/effect records. Assign remains the sole task and effect record.

## Persistence location and conventions

Goal definitions persist through the SAME injected session `state` port the
ace-wake registry already uses for loop/watch definitions (per-agent,
project-scoped session state; `load()`/`save(snapshot)`). No tracked
repository files, no `.ace-tasks` writes, no heartbeat journal, no cron/
systemd/external timer service — mirroring the existing wake persistence
conventions exactly. A goal adds a `goals` map to the persisted snapshot;
loading an older snapshot without one adopts zero goals (backward-compatible,
no migration).

## Command surface and verb semantics

Command forms (mirroring the existing wake command parser style; invalid
input fails loudly with usage text, never silently):

- `/goal add NAME --task TASK --interval SECONDS --objective TEXT
  [--attempt ATTEMPT]` — registers a durable goal. The task reference is
  validated to exist (readable through the Assign public interface) before
  anything is persisted; an unknown task fails the command loudly.
- `/goal list` — all goals with state, task ref, interval, blocker if any.
- `/goal show NAME` — full definition including objective and evidence link.
- `/goal pause NAME` — suspends dispatch (no wakes while paused); definition
  and Assign link retained.
- `/goal resume NAME` — re-enables dispatch with exactly-one re-registration.
- `/goal cancel NAME` — disposes the goal and removes it from persisted
  state; no Assign effect (the task itself is owned by Assign owners).
- `/goal blocker NAME --owner OWNER --next NEXT-ACTION [--note TEXT]` —
  records a blocker and sets `state: BLOCKED`; dispatch suspends until the
  blocker is resolved (resume/clear through the agent's normal wake
  handling, never an automatic guess).
- `/goal complete NAME` — transition to `COMPLETE` ONLY when fresh Assign
  state confirms completion (task done with accepted attempt receipts).
  Otherwise the command REFUSES with a visible error naming the current
  Assign state. Self-claim never completes a goal.

## Wake and coalescing rules

- A goal is a distinct wake source (its own source prefix, distinct from
  loop and watch sources; distinct sources never coalesce).
- While one goal wake is queued/pending, repeated interval fires for the
  SAME goal coalesce into the pending wake. A busy agent receives at most
  one queued follow-up per goal per run cycle. No wake storms: one
  reconciliation per reload/restart, never a replay of missed ticks.
- Wake delivery is queue-only (`sendUserMessage` through the existing
  dispatcher port). The wake message carries the objective continuation text
  and, when present, the blocker's next action. The agent decides what to do
  after waking — the extension never executes tasks itself.
- Each wake-time check reads fresh Assign state for the linked task:
  Assign-complete transitions the goal to `COMPLETE` (dispatch stops,
  cleanup runs); a detected blocker stays `BLOCKED` (no repeated wakes for
  an unchanged blocker beyond the normal coalesced cadence).

## Assign linkage — completion evidence

The goal's done-state is evidenced ONLY by Assign: task status plus accepted
attempt receipts, read fresh through the installed public interface at check
time. The extension never writes Assign state, never treats its own registry
flag, a report, an exit code, or an elapsed interval as completion evidence,
and never bypasses permissions to read or change task state (it uses the
same public interfaces any wake-driven agent action would use). Unavailable
or unreadable Assign state is a visible error on the goal (`/goal list`
shows the read failure); it is never interpreted as done, never as permission.

## Restart adoption

Session reload, compaction, or restart adopts each persisted goal exactly
once: prior runtime handles are disposed, then exactly one registration per
definition is restored — the same idempotent reconciliation the registry
already performs for loops/watches, extended to goals. No duplicate
execution: no missed-tick replay, no double wake, no second adoption on
repeated reloads. A goal that was `PAUSED`/`BLOCKED` before restart stays in
that state after adoption.

## Blockers

A blocker records `description`, `owner` (who must act), `next_action` (the
attributable next step) and `recorded_at`. While `BLOCKED`, dispatch
suspends; the blocker is visible in `/goal list`/`show`; the wake message of
any coalesced follow-up includes the next action so the woken agent (or the
overseer it escalates to) can act on it. Clearing requires an explicit
resume/clear after the blocker is genuinely resolved — never an automatic
timeout-based unblock.

## Cleanup

`COMPLETE` goals are cleaned up: dispatch stops immediately, the definition
is removed from persisted state, and a final informational wake confirms
closure. Evidence survives independently in Assign (the sole record), so
registry cleanup loses nothing. `CANCELLED` goals are removed the same way.
Cleanup is idempotent and safe across restarts (an already-removed goal is a
no-op, never an error).

## Relations and prohibitions

- NO second task queue: Assign remains the sole task/effect record; the goal
  REFERENCES Assign state and never replaces, mirrors, or caches it as
  authority.
- NO bypass permissions: the extension delivers wakes only; every action
  after a wake runs under the agent's normal authority boundaries.
- SEPARATE from `/loop` and `/watch`: those commands and their behavior
  continue unchanged. `/goal` adds a new definition kind to the same
  registry/dispatcher/state mechanisms — reuse, not fork. Removing a goal
  never touches loops/watches and vice versa.
- No external timer service, no cron/systemd, no tracked heartbeat files,
  no wake claims on dead processes (liveness/restart remains owned by the
  existing parent/liveness layer).

## Reuse and alignment

- **8wr.t.qjy (DONE, archived)** — in-process loop/watch mechanics are the
  reused foundation: named per-agent subscriptions, queue-only wake delivery
  with per-source coalescing and busy follow-up queueing, exactly-once
  re-registration after reload/compaction, one reconciliation per restart
  (no missed-tick flood), stop/unsubscribe semantics, loud failures for
  invalid names/paths/intervals, no dead-process wake claims, no external
  timer/heartbeat dependency. `/goal` extends these mechanisms with a new
  definition kind; it does not fork them.
- **qk0.1.1 Goal/watch adoption clause (PR53 coordination-contract
  branch)** — that acceptance row binds subscriptions to the active project
  goal/plan and original attempt, adopts after reload exactly once, wakes
  the same project owner, coalesces idle and busy callbacks into one
  eligible recorded action without another Captain nudge, and forbids an
  external timer/service or second goal store. The `/goal` primitive defined
  here is the durable goal that clause will consume; its state model
  (`ACTIVE`/`PAUSED`/`BLOCKED`/`COMPLETE`/`CANCELLED`), single-adoption
  rule, and no-second-goal-store prohibition are aligned with it.
- Implementation family: `ace-handbook-integration-pi` (ace-wake extension,
  projected to `.pi/extensions/ace-wake/`); supervision projection note in
  `.ace/handbook/config.yml` already documents the extension family.

## Success criteria and acceptance scenarios

Executable scenarios for the later implementation slice (fake-clock/event
harness plus installed-Pi acceptance, mirroring qjy's SC1–SC3 style):

1. **Registration → actual wake verified at bootstrap/recovery:** `/goal add`
   with a valid task ref registers exactly one goal; the timer fires and a
   wake carrying the objective continuation is queued exactly once; a
   reload/restart re-adopts it exactly once and the next tick wakes again —
   observed at bootstrap and recovery, not assumed from registration.
2. **Assign-linked completion:** with the linked Assign task done
   (accepted attempt receipts, fixture-controlled), the next check
   transitions the goal to `COMPLETE`, stops dispatch, and cleanup removes
   the definition; `/goal complete` on a NOT-done task refuses with the
   current Assign state named; a registry flag or agent report alone never
   completes a goal.
3. **Pause/resume/cancel:** paused goals dispatch nothing; resume restores
   exactly-one registration; cancel disposes and removes without touching
   the linked Assign task.
4. **Restart adoption without duplicate effect:** restart/compaction adopts
   each persisted goal exactly once — no duplicate wake, no missed-tick
   flood; PAUSED/BLOCKED states survive adoption unchanged.
5. **Coalescing:** repeated interval fires while a goal wake is pending
   coalesce into one; a busy agent receives at most one queued follow-up per
   goal per run cycle; distinct goals never coalesce with each other or with
   loop/watch sources; no wake storms.
6. **Blocker escalation with owner/next-action:** `/goal blocker` suspends
   dispatch; list/show expose description, owner and next action; the wake
   follow-up includes the next action; resolution requires explicit
   resume/clear — no automatic unblock.
7. **Completion via Assign-linked evidence:** covered by scenario 2 —
   restated as the binding rule that completion evidence is Assign task/
   attempt state + receipts, fresh-read, never self-claim.
8. **Cleanup:** COMPLETE/CANCELLED goals are removed from persisted state,
   idempotently and restart-safe; a final informational wake confirms
   closure; evidence remains in Assign.

Verification plan: extend the existing ace-wake fake-clock/event harness and
the installed-Pi feature scenario; run `ace-test ace-handbook-integration-pi
all`; prove no external timer/service dependency and no Assign writes from
the extension. Independent current-head review gates delivery; CI advisory.

## Boundaries and defaults

Single capability slice in the ace-wake extension family; size: medium.
No implementation is authorized or claimed by this spec; acceptance is
defined for the later implementation slice. Draft until independent review
accepts. No publication, no new authority, no second queue/journal, no
backward-compatibility aliases for the new command surface. Unknown identity
or unavailable Assign state is a visible error, never permission or success.
