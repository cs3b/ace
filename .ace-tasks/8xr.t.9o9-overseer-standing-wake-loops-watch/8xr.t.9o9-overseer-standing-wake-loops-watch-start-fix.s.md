---
id: 8xr.t.9o9
status: pending
priority: medium
created_at: "2026-10-28 06:26:57"
estimate: 
dependencies: []
tags: [ace-wake, overseer, wake, hitl]
---

# Overseer standing wake loops: watch-start fix, remote PR-watch, standing arming

## Observed defects (probe-proven, 2026-10-27)

1. /watch TUI registration does not START the watcher: definition registers and
   lists, but no filesystem event ever fires it - proven by a probe file in a
   LOCAL directory (not virtiofs). The internal armPendingAskWatches path DOES
   work (cycle-2 reviewer PoC: ask wake fired with the answer content).
2. No remote wake source exists: PR/review/comment changes on Forgejo cannot
   wake any agent. Consequence observed live twice (cycles 1 and 2): the
   pipeline stalls between stages and a human operator relays manually.
3. The overseer role has no standing wake set; every morning-start depends on
   someone prompting it.

## Requirements (WHAT)

1. /watch add starts the watcher through the same implementation the ask
   bridge uses; acceptance: a probe file in a local watched directory wakes
   the agent (regression test).
2. New remote watch type: in-process HTTP poll of configured Forgejo repos
   (PR/review/comment state), interval default 15-30 s, state diff, wake ONLY
   on change; zero model turns while unchanged. No external services.
3. Standing arming for the overseer role: default wake set = reviews folder
   (local watch), HITL transport folder (poll-fallback covers virtiofs),
   PR-watch (remote). Armed automatically on start/restart, persisted, no
   duplicates on restart.
4. Completion-ping doctrine as a reviewed handbook change: an agent finishing
   work for another agent pings the requester pane directly (herdr agent
   prompt) - the sentence wrongly smuggled into PR80 lands here instead.
5. Live acceptance: a reviewer verdict on an open PR wakes the overseer
   unprompted within seconds; the overseer requests integration with zero
   operator relays; idle token burn approximately zero over a multi-hour soak
   (no model turns without change).

## Out of scope

Blocking waits, in-turn sleep-polls, external heartbeat services (standing
rules); the second-Captain recipient model (separate task).

## Revision per independent Codex review (2026-10-28, REQUEST_CHANGES → folded in)

1. Event semantics: every wake message carries full context - source kind
   (file/remote), repository, PR number + title, event identity (review
   verdict / comment / state change), actor, and a direct link. The overseer
   must act without reconstructing or re-querying anything.
2. Host-stopped honesty: in-process polling cannot run while its host process
   is stopped. Standing arming applies to a RUNNING session (re-armed from
   persistence on restart). Waking a dead process is explicitly out of scope
   (watchdog layer is a separate concern).
3. Measurable acceptance: detection deadline <= 2x poll interval after the
   event; soak = 4 hours unchanged with EXACTLY zero model turns (counted
   from the session log); HTTP request rate reported separately; end-to-end
   evidence = timestamped triple (verdict posted -> wake delivered ->
   integration requested) with zero operator messages in between.
4. Configuration: wake-set declared per project route config (single source,
   PR80 rule); one unavailable source logs a warning and never blocks the
   others; first failure retries with backoff, permanent failure marks the
   source degraded in /watch list.
5. Completion-ping doctrine: bounded handbook documentation change only -
   requester = the pane recorded in the dispatch brief; if unavailable, log
   and report via HITL instead. No orchestration-scope expansion.

## DELIVERY DESIGN (Captain decision 2026-10-29 — replaces all relay/consumption variants)

The reply frame already carries the FULL address (machine, project, folder,
case id). Delivery = hermes EXECUTES on the target machine:

    ace-hitl reply <case-id> "<answer content>"

- hermes receives the Telegram reply, resolves message -> request frame ->
  address, and runs the command ON that machine (channel: tbd in spec -
  service ssh key / incus exec / existing lifecycle socket - pick one).
- ace-hitl reply runs locally where the case lives: writes the answer into the
  case file, flips receipt state. Full local access, no path gymnastics.
- The asker watches its CASE FILE (poll-fallback covers any mount); wake
  delivers the answer content; agent acts.
- NO relay, NO reply-file consumers, NO moving case stores into shared mounts,
  NO resident daemons. The only cross-machine motion is one command.
- Acceptance: Captain replies on Telegram; within seconds ace-hitl reply
  executes on the lab; the case file shows the answer; the wake fires with it;
  zero intermediary processes anywhere.
